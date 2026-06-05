# Wi-Fi Pager Device — Complete System Design

**Project:** Modern Wi-Fi pager for elderly user  
**Goal:** Device lights up, vibrates, and chimes when a trusted family member calls a secret pager number  
**Constraints:** Works on Wi-Fi, battery life in days/weeks, zero-interaction operation  
**Phone number approach:** Dedicated secret Telnyx DID (family-only) → webhook → pager  
**Dad's AT&T number:** Completely untouched — this device is separate  
**Research date:** June 2026  

---

## Quick Start (Minimal Work Path)

Total setup time: ~2–3 hours (mostly the hardware build). Nothing touches dad's existing phone.

| Step | What | Time | Cost |
|------|------|------|------|
| 1 | Buy a Telnyx phone number (share with family only) | 5 min | $1/month |
| 2 | Deploy Cloudflare Worker (copy-paste code below) | 20 min | Free |
| 3 | Create HiveMQ Cloud MQTT broker | 10 min | Free |
| 4 | Order hardware parts | 5 min | ~$24 one-time |
| 5 | Assemble and flash firmware | 2 hrs | — |
| **Total** | | **~2.5 hours** | **~$24 + $1/mo** |

**How it works for family:** They save the Telnyx number in their contacts as "Dad's Pager." When they need to reach him, they call that number. Pager goes off within a few seconds. They hang up — no need to stay on the line. Dad sees it lit up and calls them back on his regular phone.

**Access control:** Nobody outside the family knows the number exists. No allowlists, no filtering logic needed — security by obscurity.

---

## Table of Contents

1. [Approach Comparison Matrix](#1-approach-comparison-matrix)
2. [Detailed Approach Analyses](#2-detailed-approach-analyses)
3. [Recommendation](#3-recommendation)
4. [Recommended System Architecture](#4-recommended-system-architecture)
5. [Bill of Materials](#5-bill-of-materials)
6. [Wiring Diagram](#6-wiring-diagram)
7. [Firmware Architecture](#7-firmware-architecture)
8. [Software Architecture (Cloud Side)](#8-software-architecture-cloud-side)
9. [Step-by-Step Build Instructions](#9-step-by-step-build-instructions)
10. [Version 2 Roadmap](#10-version-2-roadmap)
11. [Version 3 Roadmap](#11-version-3-roadmap)
12. [Sources](#12-sources)

---

## 1. Approach Comparison Matrix

| Approach | Hardware Cost | Monthly Cost | Battery Life (2000mAh) | Complexity | Wi-Fi Required |
|----------|--------------|--------------|----------------------|------------|----------------|
| A: ESP32-C3 + MQTT + Telnyx webhook | $12–18 | ~$1.10/mo | 2–4 weeks | Low-Medium | Yes |
| B: ESP32-C6 + MQTT + TWT Wi-Fi 6 | $15–22 | ~$1.10/mo | 4–8 weeks | Medium | Yes (Wi-Fi 6) |
| C: ESP32 Direct SIP Client | $8–15 | ~$1.10/mo | 1–2 weeks | High | Yes |
| D: ESP32 + Firebase FCM | $8–15 | Free–$1/mo | 2–4 weeks | Medium | Yes |
| E: Raspberry Pi Zero W 2 + SIP | $18–30 | ~$1.10/mo | ~12 hours | Low | Yes |
| F: Commercial Pager (Spok) | $50–200 | $10–40/mo | Weeks (own battery) | Zero | No (RF) |
| G: LTE-M/NB-IoT (no Wi-Fi needed) | $35–65 | ~$2–3/mo | 1–3 weeks | Medium | No |
| H: LoRa / Meshtastic | $25–45 | $0 | Weeks | Medium | No |

---

## 2. Detailed Approach Analyses

---

### Approach A: ESP32-C3 + MQTT + VoIP Webhook ⭐ RECOMMENDED

**How it works:**  
Someone calls a Telnyx phone number → Telnyx fires an HTTP webhook to a Cloudflare Worker (serverless function) → the Worker publishes an MQTT message to HiveMQ Cloud → the ESP32-C3 subscribed to that topic wakes from modem sleep, activates LED and vibration motor for 5–10 seconds, returns to sleep.

**Software stack:**
- Telnyx (phone number + webhook on inbound call)
- Cloudflare Workers (free tier, receives webhook, publishes to MQTT)
- HiveMQ Cloud (free tier MQTT broker, TLS port 8883)
- ESP-IDF or Arduino framework (PubSubClient or AsyncMQTT)

**Monthly recurring cost:**
- Telnyx local DID: $1.00/month
- Inbound call minutes: $0.002/min × ~20 min/month = ~$0.04
- Cloudflare Workers: Free (100,000 req/day free tier)
- HiveMQ Cloud: Free (up to 100 devices)
- **Total: ~$1.05/month**

**Battery life:**
- ESP32-C3 modem sleep with DTIM-3 (router beacon): ~3–5mA average
- 2000mAh ÷ 4mA = 500 hours = **~21 days**

**Difficulty:** Low-Medium

---

## 3. Recommendation

**Winner: Approach A — ESP32-C3 + MQTT + Telnyx + Cloudflare Workers**

| Criterion | Score |
|-----------|-------|
| Monthly cost | ✅ ~$1.05/month |
| Battery life | ✅ 2–4 weeks (2000mAh) |
| Simplicity for end user | ✅ Zero interaction, always on |
| Reliability | ✅ MQTT QoS 1 guarantees delivery |
| Hardware cost | ✅ ~$42 one-time |
| Development difficulty | ✅ Low-Medium |

---

## 4. Recommended System Architecture

```
Family calls secret Telnyx number → Telnyx webhook fires (< 500ms) →
Cloudflare Worker publishes MQTT (< 100ms) → ESP32 receives (< 200ms) →
LEDs flash + motor vibrates + buzzer chimes
(total latency from dial to alert: < 1 second)

Dad's AT&T number: completely separate, unchanged, not involved.
```

---

## 5. Bill of Materials

### Compatibility Notes (Verified)

| Check | Result |
|-------|--------|
| XIAO ESP32-C3 battery connector | JST-PH 2.0mm — Adafruit LiPo plugs in directly, no adapter |
| Adafruit #2011 LiPo connector | JST-PH 2.0mm ✅ direct match |
| Red LED (Vf=2.0V) at 3.3V with 68Ω | (3.3−2.0)/68 = **19mA** per LED — bright, within spec ✅ |
| PN2222A driving 5× LEDs (95mA) at 3.3V GPIO | Ib=2.6mA, hfe≥50 at Ic=95mA → fully saturated ✅ |
| PN2222A driving vibration motor (85mA) at 3.3V | Same calculation → fully saturated ✅ |
| Vibration motor (rated 3V) on 3.3V rail | Within operating range (2.5–4.5V) ✅ |
| Passive buzzer (3V) on 3.3V GPIO direct | Draws ~20mA — within GPIO 40mA limit ✅ |
| Enclosure interior vs. LiPo size | LiPo is 60×42×8mm — enclosure must be ≥70×50×20mm interior ✅ |

> **Why red LEDs, not white:** White LEDs have Vf=3.0–3.4V — barely visible at 3.3V. Red LEDs have Vf=2.0V; at 3.3V with 68Ω they run at 19mA each — very bright.

### Complete Parts List — V1

| # | Component | Exact Part | Where to Buy | Qty | Price |
|---|-----------|------------|-------------|-----|-------|
| 1 | **MCU** | Seeed Studio XIAO ESP32-C3 | seeedstudio.com or Amazon | 1 | $4.99 |
| 2 | **Battery** | Adafruit Lithium Ion Battery 3.7V 2000mAh — Product #2011 | adafruit.com | 1 | $12.50 |
| 3 | **LEDs** | 5mm Red Diffused LED, super-bright — Adafruit #299 (25-pack) | adafruit.com | 5 | $3.95 (pack) |
| 4 | **LED resistors** | 68Ω 1/4W through-hole resistors | Amazon: "68 ohm resistors 1/4W 100 pack" | 5 | $1.00 (pack) |
| 5 | **Transistors** | PN2222A NPN BJT TO-92 (×2, one per circuit) | Amazon: "PN2222A transistor TO-92 100 pack" | 2 | $1.00 (pack) |
| 6 | **Base resistors** | 1kΩ 1/4W through-hole resistors (×2) | Same pack as #4 | 2 | — |
| 7 | **Vibration motor** | 10mm coin ERM vibration motor 3V | Amazon: "coin vibration motor 3V 10mm ERM" | 1 | $1.50 |
| 8 | **Flyback diode** | 1N4001 rectifier diode | Amazon: "1N4001 diode 100 pack" | 1 | $1.00 (pack) |
| 9 | **Buzzer** | 3V passive piezo buzzer 12mm | Amazon: "3V passive piezo buzzer" | 1 | $0.80 |
| 10 | **Perfboard** | Solderable protoboard 5×7cm | Amazon or Adafruit #1609 | 1 | $1.50 |
| 11 | **Wire** | 22AWG solid hook-up wire assortment | Adafruit #1311 or Amazon | 1 | $3.00 |
| 12 | **Enclosure** | ABS project box ~100×60×25mm | Amazon: "ABS project enclosure 100x60x25" | 1 | $4.50 |
| 13 | **USB-C panel mount** | USB-C female panel mount breakout | Amazon: "USB-C panel mount female breakout" | 1 | $2.00 |
| 14 | **Solder** | 60/40 rosin-core 0.8mm solder | Amazon | 1 | $4.00 |
| | **Hardware Total** | | | | **~$42** |

**Recurring cloud costs (monthly):**
| Service | Cost |
|---------|------|
| Telnyx secret pager number | $1.00 |
| Telnyx inbound call minutes (~10 calls/mo) | ~$0.01 |
| Cloudflare Workers | Free |
| HiveMQ Cloud | Free |
| **Monthly Total** | **~$1.01** |

**Battery life:** ~21 days on 2000mAh. Charging time: ~4 hours via USB-C.

---

## 6. Wiring Diagram

```
                        XIAO ESP32-C3 PINOUT
                        ┌──────────────────┐
                3V3 ─── │ 3V3         GND  │ ─── GND
               BAT+ ─── │ BAT+        D10  │
               BAT- ─── │ BAT-         D9  │
        (LEDs)  D0  ─── │ D0           D8  │
       (MOTOR)  D1  ─── │ D1           D7  │
      (BUZZER)  D2  ─── │ D2           D6  │
                        │ USB-C ───────────│──→ charging port
                        └──────────────────┘

Battery: Adafruit #2011 JST-PH 2.0mm plug → BAT+ / BAT- pads on XIAO

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LED CIRCUIT  (5× red LED, parallel, low-side NPN switch)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  3.3V ──┬──[68Ω]──[LED1 +]──[LED1 -]──┐
         ├──[68Ω]──[LED2 +]──[LED2 -]──┤
         ├──[68Ω]──[LED3 +]──[LED3 -]──┼──→ Collector (Q1 PN2222A)
         ├──[68Ω]──[LED4 +]──[LED4 -]──┤         │
         └──[68Ω]──[LED5 +]──[LED5 -]──┘    Emitter → GND

  D0 ──[1kΩ]──→ Base (Q1)
  Each LED: I=(3.3−2.0)/68=19mA ✓   Total: 95mA ✓ (PN2222A rated 600mA)
  LONGER leg = Anode (+) toward 3.3V   SHORTER leg = Cathode (−) toward transistor

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VIBRATION MOTOR CIRCUIT  (low-side NPN + flyback diode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  3.3V ──────────────────┬──→ Motor (+) red wire
                         │
                    [1N4001]  ← stripe/cathode end toward 3.3V
                         │
  Motor (−) black ───────┴──→ Collector (Q2 PN2222A)
                                    │
                               Emitter → GND
  D1 ──[1kΩ]──→ Base (Q2)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BUZZER CIRCUIT  (direct GPIO — no transistor needed)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  D2 ──→ Buzzer (+)
  GND ──→ Buzzer (−)
```

---

## 7. Firmware Architecture

### platformio.ini
```ini
[env:seeed_xiao_esp32c3]
platform = espressif32
board = seeed_xiao_esp32c3
framework = arduino
monitor_speed = 115200
lib_deps =
    knolleary/PubSubClient @ ^2.8
    bblanchon/ArduinoJson @ ^7.0
```

### src/config.h
```cpp
#pragma once

#define WIFI_SSID        "YourWiFiName"
#define WIFI_PASSWORD    "YourWiFiPassword"

#define MQTT_BROKER      "xxxxxxxx.s1.eu.hivemq.cloud"
#define MQTT_PORT        8883
#define MQTT_USER        "your-hivemq-username"
#define MQTT_PASS        "your-hivemq-password"
#define MQTT_CLIENT_ID   "pager-001"

#define TOPIC_ALERT      "pager/alert"
#define TOPIC_STATUS     "pager/status"

#define PIN_LEDS         D0
#define PIN_MOTOR        D1
#define PIN_BUZZER       D2

#define ALERT_DURATION_MS  30000
#define BUZZ_FREQ_HZ       1000
```

### src/main.cpp
```cpp
#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include "config.h"

WiFiClientSecure wifiClient;
PubSubClient mqtt(wifiClient);

void runAlert() {
  unsigned long start = millis();
  bool ledOn = false;
  while (millis() - start < ALERT_DURATION_MS) {
    ledOn = !ledOn;
    digitalWrite(PIN_LEDS,  ledOn ? HIGH : LOW);
    digitalWrite(PIN_MOTOR, ledOn ? HIGH : LOW);
    if (millis() - start < 3000) tone(PIN_BUZZER, BUZZ_FREQ_HZ, 400);
    delay(500);
  }
  digitalWrite(PIN_LEDS,  LOW);
  digitalWrite(PIN_MOTOR, LOW);
  noTone(PIN_BUZZER);
}

void onMqttMessage(char* topic, byte* payload, unsigned int len) {
  Serial.println("[PAGER] Alert received!");
  runAlert();
  mqtt.publish("pager/ack", "ok");
}

void connectWifi() {
  Serial.printf("[WIFI] Connecting to %s", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.printf("\n[WIFI] Connected. IP: %s\n", WiFi.localIP().toString().c_str());
}

void connectMqtt() {
  wifiClient.setInsecure();
  mqtt.setServer(MQTT_BROKER, MQTT_PORT);
  mqtt.setCallback(onMqttMessage);
  Serial.print("[MQTT] Connecting...");
  while (!mqtt.connected()) {
    if (mqtt.connect(MQTT_CLIENT_ID, MQTT_USER, MQTT_PASS)) {
      Serial.println(" connected.");
      mqtt.subscribe(TOPIC_ALERT, 1);
      mqtt.publish(TOPIC_STATUS, "online");
    } else {
      Serial.printf(" failed (rc=%d), retrying in 5s\n", mqtt.state());
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_LEDS,   OUTPUT);
  pinMode(PIN_MOTOR,  OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  // Startup self-test
  digitalWrite(PIN_LEDS, HIGH); digitalWrite(PIN_MOTOR, HIGH);
  tone(PIN_BUZZER, 880, 200); delay(300);
  digitalWrite(PIN_LEDS, LOW); digitalWrite(PIN_MOTOR, LOW);

  connectWifi();
  esp_wifi_set_ps(WIFI_PS_MIN_MODEM); // modem sleep ~3-5mA
  connectMqtt();
  Serial.println("[READY] Waiting for pages...");
}

void loop() {
  if (!mqtt.connected()) connectMqtt();
  mqtt.loop();
}
```

---

## 8. Software Architecture (Cloud Side)

### Cloudflare Worker (webhook bridge)
```javascript
export default {
  async fetch(request, env) {
    if (request.method !== 'POST') return new Response('OK', { status: 200 });
    const body = await request.json();
    const eventType = body?.data?.event_type;
    if (eventType !== 'call.initiated' && eventType !== 'call.answered') {
      return new Response('ignored', { status: 200 });
    }
    const mqttPayload = JSON.stringify({
      event: 'incoming_call',
      from: body?.data?.payload?.from,
      timestamp: new Date().toISOString()
    });
    await fetch(`https://YOUR-CLUSTER.s1.eu.hivemq.cloud/api/v1/mqtt/publish`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${btoa(env.HIVEMQ_USER + ':' + env.HIVEMQ_PASS)}`
      },
      body: JSON.stringify({ topic: 'pager/alert', payload: mqttPayload, qos: 1, retain: false })
    });
    return new Response(JSON.stringify({
      commands: [{ command: 'speak', payload: 'Your page has been sent.', language: 'en-US' }]
    }), { headers: { 'Content-Type': 'application/json' } });
  }
};
```

**Cloudflare Worker secrets:** `HIVEMQ_USER` and `HIVEMQ_PASS`

---

## 9. Step-by-Step Build Instructions

### Phase 1: Hardware (~2 hours)
1. Order all parts — Amazon ships in 2 days; Adafruit in 3–5 days. Order simultaneously.
2. Plug XIAO into USB-C, install PlatformIO, upload a Blink sketch to confirm it works before soldering.
3. **LED circuit:** 5× red LED anodes → 68Ω → 3.3V rail. Cathodes → Q1 (PN2222A) Collector. D0 → 1kΩ → Q1 Base. Q1 Emitter → GND.
4. **Motor circuit:** Motor+ → 3.3V. Motor− → Q2 Collector. D1 → 1kΩ → Q2 Base. Q2 Emitter → GND. 1N4001 across motor (stripe toward 3.3V).
5. **Buzzer:** D2 → Buzzer+. GND → Buzzer−.
6. **Battery:** Plug Adafruit #2011 JST-PH 2.0mm directly into XIAO's battery socket.
7. **Smoke test** before enclosing — upload hardware test sketch, verify all three activate.
8. Drill lid (5× 5mm for LEDs), side (3× 3mm for buzzer), end (USB-C hole). Mount everything, close box.

### Phase 2: Cloud (~30 minutes)
9. Create Telnyx account, add $10 credit, buy a US local DID. Share with family only.
10. Create HiveMQ Cloud account → Serverless cluster → create credentials → note cluster URL.
11. Create Cloudflare Worker → paste JS code → add HIVEMQ_USER and HIVEMQ_PASS secrets → deploy.
12. Telnyx console → Voice → Call Control Applications → Create → paste Worker URL → assign DID → Save.
13. Replace `YOUR-CLUSTER` in Worker with real HiveMQ hostname → redeploy.
14. Test: call the Telnyx number, watch HiveMQ Web Client for message on `pager/alert`.

### Phase 3: Firmware (~1 hour)
15. New PlatformIO project: board = `seeed_xiao_esp32c3`, framework = `arduino`.
16. Add `platformio.ini` lib_deps (see Section 7).
17. Create `src/config.h` with your Wi-Fi, HiveMQ, and pin values.
18. Create `src/main.cpp` (see Section 7).
19. Upload → open Serial Monitor → confirm `[READY] Waiting for pages...`
20. Call the Telnyx number → LEDs flash + motor vibrates + buzzer chimes within 1 second ✅

### Phase 4: Deploy (5 minutes)
21. Label box: `"Pager — charge with USB-C"`
22. Charge 4 hours, place on dad's nightstand. It remembers Wi-Fi across reboots.
23. Text family: `"Save this as Dad's Pager: [Telnyx number]"`

---

## 10. Version 2 Roadmap

- Upgrade to ESP32-C6 (Wi-Fi 6 TWT — 2× battery life)
- Custom PCB from JLCPCB (~$1/board in quantity)
- RGB NeoPixel notification ring
- E-ink status display ("Last call: Mom, 2:34 PM")
- Qi wireless charging dock
- Web config portal for Wi-Fi setup (no serial cable needed)
- OTA firmware updates
- Low battery SMS alert to family via Telnyx

---

## 11. Version 3 Roadmap

- Dual-mode: Wi-Fi primary + LTE-M cellular fallback (works away from home)
- Solar trickle charging panel on lid
- Companion iOS/Android app — family sends pages from app, not just phone calls
- Two-way ack button — dad presses it, family gets "Dad acknowledged ✅" notification
- Commercial packaging, FCC Part 15 certification, sellable product
- Business model: $79–99 device + optional $4.99/month subscription

---

## 12. Sources

- [ESP32 Sleep Modes & Power — Last Minute Engineers](https://lastminuteengineers.com/esp32-sleep-modes-power-consumption/)
- [ESP32-C3 Datasheet — Espressif](https://www.espressif.com/sites/default/files/documentation/esp32-c3_datasheet_en.pdf)
- [TWT Battery Extension — Hubble Network](https://hubble.com/community/guides/using-target-wake-time-to-extend-esp32-battery/)
- [Telnyx Pricing](https://telnyx.com/pricing)
- [Cloudflare Workers Pricing](https://developers.cloudflare.com/workers/platform/pricing/)
- [HiveMQ Cloud](https://www.hivemq.com/products/mqtt-cloud-broker/)
- [Adafruit Vibrating Mini Motor #1201](https://www.adafruit.com/product/1201)
- [Adafruit 2000mAh LiPo #2011](https://www.adafruit.com/product/2011)
- [Hologram IoT SIM Pricing](https://www.hologram.io/pricing/)
- [Meshtastic Hardware](https://meshtastic.org/docs/hardware/devices/)
- [Spok Paging Services](https://www.spok.com/solutions/paging-services/)

---

*Research conducted June 2026. Prices and free tier limits subject to change.*
