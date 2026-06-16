# Electrical Design — ESP32-C6 Pager

This is the schematic-level design: every functional block, how it connects to
the ESP32-C6, the power tree, and the math behind the ~1-week battery target.
It's written so it maps 1:1 onto a KiCad schematic.

---

## 1. System block diagram

See `block-diagram.svg` for the visual. In words:

```
                 USB-C (5V, native USB data)
                    |            |
              [ESD: USBLC6]  D+/D- ── ESP32-C6 (USB-Serial/JTAG, first flash)
                    |
            [Charger: MCP73831] ── STAT ── ESP32-C6 GPIO (charge LED/flag)
                    |
        LiPo 1100mAh ──┬── [Fuel gauge MAX17048] ── I2C ── ESP32-C6
        (JST-PH)       |
                       ├── [LDO 3.3V, low-Iq] ── 3V3 rail ── ESP32-C6 + e-ink + sensors
                       |
                       └── [P-MOSFET load switch] ── LED_PWR ── NeoPixel ring (gated!)

   ESP32-C6 ── SPI ───────── 2.9" e-ink (SSD1680, 24-pin FPC)
            ── I2S ───────── [MAX98357A class-D amp] ── [AUDIO slide switch] ── speaker
            ── 1-wire ─────── SK6812 RGB ring (power-gated)
            ── GPIO ───────── 2× tactile buttons (ACK / MENU)
            ── 2.4GHz Wi-Fi 6 + BLE (module antenna)
```

## 2. Power tree

```
5V USB ─► MCP73831 ─► LiPo (3.0–4.2V) ─┬─► MAX17048 fuel gauge (battery sense)
                                       ├─► TLV75533 LDO ─► 3V3 (always-on rail)
                                       └─► SI2301 P-FET ─► LED_VDD (ring, GPIO-gated)
```

- **Charger — MCP73831T-2ACI/OT:** 500 mA single-cell LiPo charger. Set charge
  current with a PROG resistor (2.0 kΩ ≈ 500 mA; use 3.0 kΩ ≈ 333 mA to be gentle
  on a slim cell). `STAT` pin → a GPIO and/or a charge LED.
- **3V3 rail — TLV75533PDBVR:** 500 mA LDO, ~25 µA quiescent. The 500 mA headroom
  covers the C6's Wi-Fi TX current peaks (~350–500 mA bursts) without browning out;
  the low Iq is what protects deep-sleep runtime. (A buck converter would be ~10–15%
  more efficient but adds switching noise next to the RF + e-ink — skipped on
  purpose for v1; noted as an efficiency upgrade.)
- **Fuel gauge — MAX17048G+T:** I2C battery state-of-charge, ModelGauge (no sense
  resistor). This is what feeds the "low battery → SMS to family" alert and an
  accurate on-screen %. Cheaper alt: **CW2015** (LCSC, I2C, similar function).
- **LED ring load switch — SI2301 P-MOSFET:** *Critical for battery life.* SK6812
  LEDs draw ~0.5–0.8 mA **each, continuously, even when displaying black** — 8 of
  them would burn ~5 mA 24/7 and wreck the budget. So the whole ring's VDD is
  high-side switched by a GPIO and only powered when actually notifying.

## 3. ESP32-C6 pin map

Module: **ESP32-C6-WROOM-1-N8** (8 MB flash, PCB antenna). Assignments use the
GPIO matrix, so they're flexible — verify against the WROOM-1 datasheet before
routing, and keep strapping pins clear at boot.

| Function | Net | GPIO | Notes |
|----------|-----|------|-------|
| E-ink SPI clock | EINK_SCK | GPIO6 | SPI |
| E-ink SPI data | EINK_MOSI | GPIO7 | SPI (display is write-only) |
| E-ink chip select | EINK_CS | GPIO10 | |
| E-ink data/command | EINK_DC | GPIO11 | |
| E-ink reset | EINK_RST | GPIO21 | |
| E-ink busy | EINK_BUSY | GPIO20 | input |
| I2C SDA | I2C_SDA | GPIO4 | fuel gauge (+ future sensors) |
| I2C SCL | I2C_SCL | GPIO5 | |
| I2S bit clock | I2S_BCLK | GPIO18 | to MAX98357A |
| I2S word select | I2S_LRCLK | GPIO19 | |
| I2S data out | I2S_DOUT | GPIO23 | |
| Amp enable | AMP_SD | GPIO2 | also hard-muted by the slide switch |
| NeoPixel data | LED_DATA | GPIO0 | level-shift to 5V if ring runs at 5V |
| LED ring power | LED_PWR_EN | GPIO1 | drives P-FET gate (active low) |
| Button: acknowledge | BTN_ACK | GPIO3 | wake-from-sleep capable |
| Button: menu | BTN_MENU | GPIO14 | |
| Charger status | CHG_STAT | GPIO22 | from MCP73831 STAT |
| USB D− | USB_DM | GPIO12 | native USB (fixed) |
| USB D+ | USB_DP | GPIO13 | native USB (fixed) |
| Boot strap | — | GPIO9 | leave for BOOT button / pull-up |
| Strapping | — | GPIO8, GPIO15 | do not drive at boot |

**Boot/flash:** GPIO9 = BOOT (tactile button to GND + 10k pull-up), EN = reset
(10k pull-up + 100nF + optional reset button). USB D+/D− go straight to the
module for the first flash and for serial logs; after that, OTA over Wi-Fi.

## 4. Block details (net level)

### 4.1 USB-C input + ESD
- **USB-C receptacle (16-pin):** VBUS → charger VIN; GND; CC1/CC2 each via **5.1 kΩ**
  to GND (advertise as a sink so any charger supplies 5 V); D+/D− → ESD → module.
- **USBLC6-2SC6:** ESD clamp on D+/D−/VBUS. Place at the connector.
- 4.7 µF + 0.1 µF bulk on VBUS.

### 4.2 Charger
- MCP73831 VDD = VBUS, VBAT = LiPo+, PROG = 2.0–3.0 kΩ to GND, STAT → CHG_STAT
  (+ optional amber LED via 1 kΩ). 4.7 µF on VBAT.

### 4.3 Battery + fuel gauge
- **LiPo 1100 mAh** (e.g. 503450 / 603450 pouch) on a **JST-PH 2-pin**.
- MAX17048 across the cell: CELL → LiPo+, GND, SDA/SCL with **4.7 kΩ** pull-ups to
  3V3, QSTRT/ALRT optional → GPIO for the low-battery interrupt. 0.1 µF on CELL.

### 4.4 3V3 regulation
- TLV75533: IN = LiPo+, EN = IN (or to a GPIO if you ever want a hard kill),
  OUT = 3V3. 1 µF in / 1 µF out (per datasheet, ceramic).
- Decouple the module with 10 µF + 0.1 µF at the 3V3 pin; another 0.1 µF near pins.

### 4.5 E-ink (2.9" mono, 296×128)
- Panel uses the **SSD1680** controller, **24-pin 0.5 mm FPC** (bottom contact).
  Compatible panels: GDEY029T94 / GDEM029T94 / WeAct 2.9" B/W.
- Connector: 24-pin 0.5 mm FPC. Nets: VCI=3V3, SPI (SCK/MOSI/CS/DC/RST/BUSY),
  plus the **charge-pump caps** the SSD1680 needs: typically a **1 µF** on each of
  VGL/VGH/VSH/VSL/VCOM and a **0.1 µF** on VDD — follow the exact panel datasheet's
  reference cap network (this is the #1 e-ink bring-up gotcha).
- A FET or the panel's own EN can cut VCI in deep sleep to drop standby further
  (e-ink holds its image with **zero** power, so this is safe).

### 4.6 Audio + the physical toggle
- **MAX98357A** I2S class-D amp → **8 Ω, ~1 W** speaker. BCLK/LRCLK/DIN from the
  C6's I2S. GAIN pin set for ~9–12 dB.
- **Audio on/off slide switch (SPDT):** wired in series with the amp's **SD/enable**
  (and optionally the speaker +). Throw it off → amp shuts down, **zero ring,
  zero current** to the audio stage, fully mechanical (works even if firmware is
  asleep or hung). Firmware also reads the state via AMP_SD so the UI can show a
  mute icon.
- Speaker on a JST 2-pin so it mounts to the enclosure.

### 4.7 RGB notification ring
- **8× SK6812** (or WS2812B-2020) in a ring, daisy-chained. VDD from the P-FET
  load switch (LED_PWR_EN). DIN from LED_DATA (add a **74AHCT1G125** level shifter
  if the ring runs at 5 V from VBUS; if you run the ring at 3V3 off the LiPo via a
  small boost or directly, a C6 3.3 V data line usually drives SK6812 fine).
- 0.1 µF per LED, 10 µF bulk at the ring input.

### 4.8 Buttons
- 2× SMD tactile (ACK, MENU) to GND, 10 k pull-ups (or internal). ACK on an
  RTC/wake-capable GPIO so a press wakes the device from deep sleep.

## 5. Power budget — proving ~1 week

Cell: **1100 mAh** nominal; usable to the 3.3 V LDO dropout ≈ **~950 mAh**.
Target: **7 days = 168 h** → average budget **≈ 5.6 mA**.

| State | Current | Notes |
|-------|--------:|-------|
| Deep sleep (C6 RTC + LDO Iq + gauge + leakage) | ~55–70 µA | LED ring fully power-gated, e-ink VCI off, amp off |
| E-ink full refresh | ~25 mA for ~2 s | only on a new message; ~0.014 mAh per refresh — negligible |
| Wi-Fi wake (connect, fetch, sleep) | ~100 mA avg for ~2 s | ~0.055 mAh per wake |
| NeoPixel notify pulse | ~40–120 mA for a few s | only while alerting; gate keeps idle draw at 0 |

Two connectivity strategies (firmware choice, both fit the budget):

- **Deep-sleep polling** every 2 min: ~720 wakes/day × 0.055 mAh ≈ **40 mAh/day**
  + ~1.5 mAh/day sleep ≈ **~41 mAh/day → ~23 days**. Latency up to 2 min.
- **Wi-Fi 6 TWT (always "connected," low duty)**: keeps a session alive while the
  radio sleeps between negotiated wake times — low-latency notifications at a few
  mA average. Lands around the **~1 week** target with near-instant alerts. This is
  the roadmap's "2× battery life" point and the reason to be on the C6.

Either way the ~1-week goal is comfortable; TWT buys low latency, deep-sleep
polling buys multi-week life if you can tolerate a minute or two of delay.

## 6. PCB stackup + layout notes

- **4-layer, 1.6 mm:** Sig / GND / PWR / Sig. The solid ground plane under the
  module's antenna keep-out and the e-ink SPI is what keeps RF + display clean.
- **Antenna keep-out:** no copper (any layer) under the ESP32-C6 PCB antenna; push
  it to a board edge, no battery/metal behind it.
- **USB-C:** keep D+/D− as a ~90 Ω differential pair, short, ESD at the connector.
- **Charger/LDO:** short, fat traces on VBAT/VBUS; thermal copper under the LDO.
- **E-ink charge-pump caps:** place tight to the FPC connector pins.
- **Star ground** the audio amp; keep the speaker return off the RF ground pour.
- **Mounting:** 4× M2 holes matched to the enclosure (see `ENCLOSURE.md`).
- Board outline ≈ **78 × 40 mm** (fits behind the 2.9" panel; see enclosure).

## 7. Roadmap hooks already accounted for

- **Web config + OTA:** USB only needed for the first flash; C6 native USB present.
- **Low-battery SMS (Telnyx):** MAX17048 ALRT → GPIO triggers the firmware to push
  an alert up over Wi-Fi to your server/Telnyx — no cellular hardware on-board.
- **Qi wireless charging (v2):** add a Qi RX module (e.g. BQ51013B + coil) whose
  5 V output feeds the same charger VIN node; left as a v2 add-on pad area.
- **TWT:** native to the C6 — firmware feature, no extra parts.
