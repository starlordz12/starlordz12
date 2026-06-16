# Pager — Custom PCB + Enclosure

A pocket pager built around the **ESP32-C6** with a **2.9" mono e-ink** display,
**~1 week battery life**, a physical **audio on/off toggle**, an RGB notification
ring, USB-C charging, and **web config + OTA** (no serial cable needed after the
first flash).

This folder is the hardware design package for that device. It pairs with the
V2 roadmap: ESP32-C6 (Wi-Fi 6 TWT), custom JLCPCB board, e-ink status display,
NeoPixel ring, web config portal, OTA, and low-battery SMS alerts.

---

## What's in here

| File | What it is |
|------|------------|
| `DESIGN.md` | Full electrical design — block diagram, power tree, net-by-net schematic, ESP32-C6 pin map, and the power budget that proves the ~1-week target. |
| `BOM.csv` | Bill of materials in JLCPCB upload format (MPN + LCSC #, package, designator). |
| `ENCLOSURE.md` | 3D-printed enclosure spec — dimensions, two-part shell, belt clip, all cutouts. |
| `block-diagram.svg` | One-page system block diagram. |
| `pager-concept.svg` | Front-panel mockup for the pager look. |
| `kicad/` | Schematic as code (SKiDL) → KiCad netlist → board → Gerbers. See `kicad/README.md`. |

## Status — read this first

This package is **complete through schematic + BOM + mechanical spec**, and the
schematic now exists as runnable code in **`kicad/pager.py`** (SKiDL). It does
**not** yet include routed Gerbers, because PCB routing must be done in an EDA
tool (KiCad/Altium) — it can't be hand-authored reliably. To finish:

1. **KiCad (recommended, free):** run `kicad/pager.py` to emit a netlist, import
   it into Pcbnew, place + route, then plot Gerbers + the pick-and-place (CPL)
   file. Full steps in `kicad/README.md`. `BOM.csv` is already JLCPCB-formatted.
2. **JLCPCB EDA / layout service:** upload this design intent and let their tool
   (or a service like Flux.ai's AI router) place it; the BOM here drops straight in.

Every **LCSC part number** below should be re-verified for stock at order time —
LCSC inventory moves, and JLCPCB PCBA only places parts they currently have.

## Why JLCPCB over PCBWay here

You asked which manufacturer — for this board, **JLCPCB**:

- **Assembly cost:** their economic PCBA + "Basic Parts" library is the cheapest
  path for a board with a fine-pitch ESP32-C6 module you don't want to hand-solder.
- **One vendor:** PCB fab + SMT assembly + the LCSC parts catalog are the same
  company, so the BOM/CPL workflow is tightly integrated.
- **Bare-board price** lands near your roadmap's ~$1/board in quantity (5-board
  minimum on the cheap tier).

PCBWay is a great shop too (often nicer for fancy finishes / large boards), and
this BOM is portable — but for a small assembled IoT board JLCPCB is the value pick.

---

## Ordering flow (once Gerbers exist)

1. **Gerbers + drill** → JLCPCB "Add gerber file". Pick 4-layer (see `DESIGN.md`
   for the stackup and why), ENIG finish (good for the e-ink FPC + RF), 1.6 mm.
2. **Turn on SMT Assembly** → upload `BOM.csv` and the CPL/placement file.
3. **Confirm placements** in their review step — pay attention to the ESP32-C6
   module rotation and the USB-C connector polarity.
4. **Hand-add parts** (see `BOM.csv` "Hand-solder" column): the e-ink panel,
   the LiPo cell, the speaker, and the side slide switch typically go on by hand
   or are plugged into connectors after assembly.
5. **First flash** over USB-C (the C6 has native USB-Serial/JTAG). After that,
   firmware updates ride OTA via the web portal — no cable.

## Rough cost (5 pcs, ballpark)

| Item | ~Cost |
|------|-------|
| PCB fab (4-layer, 5 pcs) | $15–25 |
| SMT assembly + basic parts | $40–80 setup + parts |
| ESP32-C6-WROOM-1 modules (×5) | ~$10–15 |
| E-ink 2.9" panels (×5) | ~$50–70 |
| LiPo cells, speakers, switches | ~$25–35 |
| **Total (5 units)** | **~$150–220 → ~$30–45/unit** |

Per-unit cost drops fast at 30–50 qty as the assembly setup amortizes.
