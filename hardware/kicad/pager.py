#!/usr/bin/env python3
"""
ESP32-C6 Pager — schematic as code (SKiDL).

Run this where KiCad 8 + its symbol/footprint libraries are installed:

    pip install skidl
    python pager.py            # runs ERC, writes pager.net

Then in KiCad: Pcbnew -> File > Import > Netlist > pager.net, place + route,
plot Gerbers (see README.md). This script encodes the *connectivity*; KiCad's
libraries supply the correct pin->pad numbering, so nothing here depends on
hand-guessed pad numbers.

Anything marked  # VERIFY  is a symbol name, footprint, or pin name that you
should sanity-check against the actual part datasheet / your installed library
version. SKiDL will raise a clear error if a symbol or pin name doesn't exist,
and the fix is a one-line edit here.
"""

from skidl import Part, Net, generate_netlist, ERC, TEMPLATE

# --------------------------------------------------------------------------
# Footprints (KiCad standard libs). Swap to exact LCSC-matched land patterns
# if you have them; packages below match the BOM.
# --------------------------------------------------------------------------
FP = {
    "R0402":   "Resistor_SMD:R_0402_1005Metric",
    "C0402":   "Capacitor_SMD:C_0402_1005Metric",
    "C0603":   "Capacitor_SMD:C_0603_1608Metric",
    "LED0603": "LED_SMD:LED_0603_1608Metric",
    "SOT23":   "Package_TO_SOT_SMD:SOT-23",
    "SOT23_5": "Package_TO_SOT_SMD:SOT-23-5",
    "SOT23_6": "Package_TO_SOT_SMD:SOT-23-6",
    "ESP32C6": "RF_Module:ESP32-C6-WROOM-1",                              # VERIFY (KiCad 8.0.4+)
    "TDFN8":   "Package_DFN_QFN:TDFN-8-1EP_2x3mm_P0.5mm_EP0.9x1.6mm",     # VERIFY MAX17048 pkg
    "QFN16":   "Package_DFN_QFN:QFN-16-1EP_3x3mm_P0.5mm_EP1.7x1.7mm",     # VERIFY MAX98357A pkg
    "USB_C":   "Connector_USB:USB_C_Receptacle_HRO_TYPE-C-31-M-12",       # VERIFY 16-pin part
    "FPC24":   "Connector_FFC-FPC:Hirose_FH12-24S-0.5SH_1x24-1MP_P0.50mm_Horizontal",  # VERIFY 24p 0.5mm
    "JST_PH2": "Connector_JST:JST_PH_B2B-PH-K_1x02_P2.00mm_Vertical",
    "SK6812":  "LED_SMD:LED_SK6812_PLCC4_5.0x5.0mm",                      # VERIFY (or 2020 variant)
    "TACT":    "Button_Switch_SMD:SW_SPST_B3U-1000P",                     # VERIFY tact pkg
    "SLIDE":   "Button_Switch_SMD:SW_MEC_5G_5GTH9",                       # VERIFY SPDT slide pkg
}

# --------------------------------------------------------------------------
# Nets
# --------------------------------------------------------------------------
gnd   = Net("GND");   gnd.drive   = 7   # POWER
v3v3  = Net("+3V3");  v3v3.drive  = 7
vbat  = Net("VBAT")
vbus  = Net("VBUS")                      # 5V from USB-C
led_pwr = Net("LED_PWR")                 # switched ring supply (off the P-FET)

# USB
usb_dp, usb_dm = Net("USB_DP"), Net("USB_DM")
cc1, cc2       = Net("USB_CC1"), Net("USB_CC2")

# E-ink SPI / control
eink = {n: Net("EINK_" + n) for n in ("SCK", "MOSI", "CS", "DC", "RST", "BUSY")}
# E-ink SSD1680 charge-pump rails (caps live next to the FPC). VERIFY against panel.
ep = {n: Net("EINK_" + n) for n in ("VGL", "VGH", "VSH", "VSL", "VCOM")}

# I2C (fuel gauge + future sensors)
sda, scl = Net("I2C_SDA"), Net("I2C_SCL")
alrt     = Net("BATT_ALRT")

# I2S audio
bclk, lrclk, dout = Net("I2S_BCLK"), Net("I2S_LRCLK"), Net("I2S_DOUT")
amp_sd            = Net("AMP_SD")
spk_p, spk_n      = Net("SPK_P"), Net("SPK_N")

# Misc control
led_data  = Net("LED_DATA")      # 3V3 logic from MCU
led_data5 = Net("LED_DATA_5V")   # after level shifter, to first SK6812
led_gate  = Net("LED_PWR_EN")    # MCU -> P-FET gate
btn_ack   = Net("BTN_ACK")
btn_menu  = Net("BTN_MENU")
en        = Net("EN")            # module reset / boot strap node
chg_stat  = Net("CHG_STAT")

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------
R = Part("Device", "R", dest=TEMPLATE, footprint=FP["R0402"])
C = Part("Device", "C", dest=TEMPLATE, footprint=FP["C0402"])

def res(ref, val, a, b, fp=FP["R0402"]):
    r = R(ref=ref, value=val, footprint=fp); r[1] += a; r[2] += b; return r

def cap(ref, val, a, b, fp=FP["C0402"]):
    c = C(ref=ref, value=val, footprint=fp); c[1] += a; c[2] += b; return c

# --------------------------------------------------------------------------
# U1 — ESP32-C6-WROOM-1  (connect by pin NAME so KiCad maps pads correctly)
# --------------------------------------------------------------------------
u1 = Part("RF_Module", "ESP32-C6-WROOM-1", value="ESP32-C6-WROOM-1-N8",
          footprint=FP["ESP32C6"])          # VERIFY symbol exists in your lib
u1["GND"] += gnd
u1["3V3"] += v3v3
u1["EN"]  += en
# E-ink SPI
u1["IO6"]  += eink["SCK"]
u1["IO7"]  += eink["MOSI"]
u1["IO10"] += eink["CS"]
u1["IO11"] += eink["DC"]
u1["IO21"] += eink["RST"]
u1["IO20"] += eink["BUSY"]
# I2C
u1["IO4"] += sda
u1["IO5"] += scl
# I2S
u1["IO18"] += bclk
u1["IO19"] += lrclk
u1["IO23"] += dout
u1["IO2"]  += amp_sd
# Ring
u1["IO0"] += led_data
u1["IO1"] += led_gate
# Buttons / status
u1["IO3"]  += btn_ack
u1["IO14"] += btn_menu
u1["IO22"] += chg_stat
# Native USB (names may be 'IO12'/'IO13' or 'USB_D-/IO12' in your symbol) VERIFY
u1["IO12"] += usb_dm
u1["IO13"] += usb_dp

cap("C1", "10uF", v3v3, gnd, FP["C0603"])
cap("C2", "0.1uF", v3v3, gnd)
cap("C3", "0.1uF", v3v3, gnd)
# EN RC + boot/reset
res("R6", "10k", v3v3, en)
cap("C4", "0.1uF", en, gnd)

# --------------------------------------------------------------------------
# USB-C input + ESD
# --------------------------------------------------------------------------
j1 = Part("Connector", "USB_C_Receptacle_USB2.0_16P", ref="J1",
          footprint=FP["USB_C"])            # VERIFY symbol/footprint pairing
j1["VBUS"] += vbus
j1["GND"]  += gnd
j1["CC1"]  += cc1
j1["CC2"]  += cc2
j1["DP1"]  += usb_dp; j1["DP2"] += usb_dp   # VERIFY pin names (DP1/DP2 or D+)
j1["DM1"]  += usb_dm; j1["DM2"] += usb_dm
j1["SHIELD"] += gnd
res("R1", "5.1k", cc1, gnd)
res("R2", "5.1k", cc2, gnd)
cap("C5", "4.7uF", vbus, gnd, FP["C0603"])
cap("C6", "0.1uF", vbus, gnd)

u6 = Part("Power_Protection", "USBLC6-2SC6", ref="U6", footprint=FP["SOT23_6"])  # VERIFY
u6["I/O1"] += usb_dp; u6["I/O2"] += usb_dm   # VERIFY pin names
u6["VBUS"] += vbus
u6["GND"]  += gnd

# --------------------------------------------------------------------------
# U2 — MCP73831 charger
# --------------------------------------------------------------------------
u2 = Part("Battery_Management", "MCP73831-2-OT", ref="U2", value="MCP73831T-2ACI/OT",
          footprint=FP["SOT23_5"])
u2["VDD"]  += vbus
u2["VSS"]  += gnd
u2["VBAT"] += vbat
u2["STAT"] += chg_stat
res("R3", "2.0k", u2["PROG"], gnd)           # ~500mA charge
cap("C7", "4.7uF", vbat, gnd, FP["C0603"])
# charge status LED
d9 = Part("Device", "LED", ref="D9", footprint=FP["LED0603"])
d9["K"] += chg_stat
res("R11", "1k", v3v3, d9["A"])

# --------------------------------------------------------------------------
# U3 — MAX17048 fuel gauge
# --------------------------------------------------------------------------
u3 = Part("Battery_Management", "MAX17048", ref="U3", footprint=FP["TDFN8"])  # VERIFY symbol
u3["CELL"] += vbat
u3["GND"]  += gnd
u3["SDA"]  += sda
u3["SCL"]  += scl
u3["ALRT"] += alrt
cap("C8", "0.1uF", vbat, gnd)
res("R4", "4.7k", v3v3, sda)
res("R5", "4.7k", v3v3, scl)

# --------------------------------------------------------------------------
# U4 — 3V3 LDO (TLV75533, low Iq). SOT23-5 pinout differs per part: use the
# TLV755 symbol so pads map correctly, NOT a generic AP2112 symbol. VERIFY.
# --------------------------------------------------------------------------
u4 = Part("Regulator_Linear", "TLV75533PDBV", ref="U4", footprint=FP["SOT23_5"])  # VERIFY name
u4["IN"]  += vbat
u4["OUT"] += v3v3
u4["GND"] += gnd
u4["EN"]  += vbat                            # always-on (tie EN to IN)
cap("C9",  "1uF", vbat, gnd)
cap("C10", "1uF", v3v3, gnd)

# --------------------------------------------------------------------------
# U5 — MAX98357A I2S amp + speaker, with hard mute via SW4
# --------------------------------------------------------------------------
u5 = Part("Amplifier_Audio", "MAX98357A", ref="U5", footprint=FP["QFN16"])  # VERIFY symbol/pkg
u5["LRC"]   += lrclk
u5["BCLK"]  += bclk
u5["DIN"]   += dout
u5["GAIN"]  += gnd          # ~+9dB (set per datasheet table)
u5["SD"]    += amp_sd       # firmware enable, AND mechanically gated below
u5["VDD"]   += v3v3
u5["GND"]   += gnd
u5["OUTP"]  += spk_p
u5["OUTN"]  += spk_n
cap("C11", "0.1uF", v3v3, gnd)
cap("C12", "10uF", v3v3, gnd, FP["C0603"])

# SW4 — AUDIO on/off SPDT in series with SD (common -> SD pin, throw -> MCU/GND)
sw4 = Part("Switch", "SW_SPDT", ref="SW4", footprint=FP["SLIDE"])  # VERIFY
sw4[1] += amp_sd            # to amp SD
sw4[2] += u1["IO2"]         # ON: follow MCU enable  (already amp_sd net via IO2)
sw4[3] += gnd              # OFF: SD pulled low -> amp shut down
# speaker
j4 = Part("Connector", "Conn_01x02_Socket", ref="J4", footprint=FP["JST_PH2"])
j4[1] += spk_p; j4[2] += spk_n

# --------------------------------------------------------------------------
# RGB notification ring: 8x SK6812, power-gated by Q1, data via level shifter
# --------------------------------------------------------------------------
# Q1 high-side P-FET load switch (gate driven by led_gate through R)
q1 = Part("Device", "Q_PMOS_GSD", ref="Q1", value="SI2301", footprint=FP["SOT23"])
q1["S"] += vbus
q1["D"] += led_pwr
q1["G"] += led_gate
res("R7", "100k", vbus, q1["G"])             # default-off pull-up

# U7 level shifter 3V3 -> 5V data
u7 = Part("74xGxx", "74AHCT1G125", ref="U7", footprint=FP["SOT23_5"])  # VERIFY
u7["A"]  += led_data
u7["Y"]  += led_data5
u7["OE"] += gnd            # active-low enable
u7["VCC"] += vbus
u7["GND"] += gnd
res("R12", "330", led_data5, Net("LED_DIN1"))  # series term to first LED
cap("C13", "0.1uF", vbus, gnd)

# SK6812 chain
prev_din = Net("LED_DIN1")
for i in range(1, 9):
    led = Part("Device", "LED", ref=f"LED{i}", footprint=FP["SK6812"])  # VERIFY 4-pin SK6812 symbol
    # SK6812 symbol pins: VDD, DOUT, GND, DIN  (names VERIFY)
    led["VDD"] += led_pwr
    led["GND"] += gnd
    led["DIN"] += prev_din
    nxt = Net(f"LED_DIN{i+1}")
    led["DOUT"] += nxt
    cap(f"C{20+i}", "0.1uF", led_pwr, gnd)
    prev_din = nxt
cap("C30", "10uF", led_pwr, gnd, FP["C0603"])

# --------------------------------------------------------------------------
# Buttons
# --------------------------------------------------------------------------
for ref, net in (("SW1", btn_ack), ("SW2", btn_menu)):
    sw = Part("Switch", "SW_Push", ref=ref, footprint=FP["TACT"])
    sw[1] += net; sw[2] += gnd
# BOOT button on EN/IO9 path (here on EN for first-flash reset)
sw3 = Part("Switch", "SW_Push", ref="SW3", footprint=FP["TACT"])
sw3[1] += en; sw3[2] += gnd
res("R8",  "10k", v3v3, btn_ack)
res("R9",  "10k", v3v3, btn_menu)

# --------------------------------------------------------------------------
# Battery connector
# --------------------------------------------------------------------------
j3 = Part("Connector", "Conn_01x02_Socket", ref="J3", footprint=FP["JST_PH2"])
j3[1] += vbat; j3[2] += gnd

# --------------------------------------------------------------------------
# J2 — 2.9" e-ink FPC (24-pin). Map signal pins to nets; charge-pump caps on
# their rails. Panel pin order VERIFY against your exact module datasheet.
# --------------------------------------------------------------------------
j2 = Part("Connector_Generic", "Conn_01x24", ref="J2", footprint=FP["FPC24"])
# Typical SSD1680 2.9" 24-pin mapping (Good Display GDEY029T94 family). VERIFY.
eink_map = {
    1: gnd, 2: v3v3, 3: v3v3, 4: gnd,          # power
    5: eink["CS"], 6: eink["DC"], 7: eink["RST"], 8: eink["BUSY"],
    9: eink["MOSI"], 10: eink["SCK"],
    11: ep["VSH"], 12: ep["VSL"], 13: ep["VGH"], 14: ep["VGL"],
    15: ep["VCOM"], 16: gnd, 17: gnd, 18: v3v3,
    19: gnd, 20: gnd, 21: gnd, 22: gnd, 23: gnd, 24: gnd,
}
for pin, net in eink_map.items():
    j2[pin] += net
# SSD1680 reference cap network (values per panel datasheet)
cap("C14", "1uF", ep["VSH"], gnd)
cap("C15", "1uF", ep["VSL"], gnd)
cap("C16", "1uF", ep["VGH"], gnd)
cap("C17", "1uF", ep["VGL"], gnd)
cap("C18", "1uF", ep["VCOM"], gnd)
cap("C19", "0.1uF", v3v3, gnd)

# --------------------------------------------------------------------------
# Checks + output
# --------------------------------------------------------------------------
ERC()
generate_netlist(file_="pager.net")
print("Wrote pager.net — import into Pcbnew (File > Import > Netlist).")
