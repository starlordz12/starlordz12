# KiCad — from this schematic to Gerbers

`pager.py` is the **schematic as code** (SKiDL): it describes every component and
net for the pager. Run it where KiCad 8 lives and it emits a KiCad netlist you
import into the PCB editor, route, and plot to Gerbers.

## Why code instead of a hand-drawn `.kicad_sch`?

This was generated in an environment with **no KiCad and no network**, so a binary
`.kicad_sch` couldn't be produced *and verified* — and a schematic's correctness
hinges on the library's exact pin→pad numbering for parts like the ESP32-C6
module and the SOT-23-5 LDO. Writing those pad numbers blind risks a wrong board.
SKiDL sidesteps that: you connect by **function/pin-name**, and KiCad's own
libraries (on your machine) supply the correct pads. It also runs **ERC**.

If you'd rather have the graphical boxes-and-wires `.kicad_sch` to click around in,
say so — easiest is to run this, then let SKiDL's experimental
`generate_schematic()` draft one, or I can hand-build one for you to ERC.

## 1. Generate the netlist

```bash
pip install skidl
# KiCad 8 must be installed (it provides the symbol + footprint libraries).
cd hardware/kicad
python pager.py        # runs ERC, writes pager.net
```

Fix anything ERC flags. Every line tagged `# VERIFY` in `pager.py` is a symbol
name, footprint, or pin name to confirm against your installed library version /
the part datasheet — SKiDL errors are explicit and each fix is one line.

Most likely tweaks on first run:
- `RF_Module:ESP32-C6-WROOM-1` — present in KiCad 8.0.4+. If missing, install the
  latest libraries or add the symbol; GPIO pins may be named `IO4` vs `GPIO4`.
- LDO symbol `TLV75533PDBV` — if absent, add it or pick the exact TLV755 variant.
  **Don't** substitute an AP2112 symbol: SOT-23-5 LDO pinouts differ by part.
- `MAX17048` / `MAX98357A` symbols + their QFN/TDFN footprints.
- E-ink FPC pin map (`eink_map` in the script) — confirm against your panel's
  datasheet; 24-pin orderings vary between vendors.

## 2. Import into the PCB editor

1. New KiCad project named `pager` (so refs/netlist line up).
2. Open **Pcbnew** → `File > Import > Netlist` → select `pager.net` →
   *Update PCB*. All footprints drop in with a ratsnest.
3. Draw the board outline on **Edge.Cuts**: ~**78 × 40 mm** (fits behind the 2.9"
   panel — see `../ENCLOSURE.md`). Add 4× M2 mounting holes.

## 3. Layout priorities (from `../DESIGN.md`)

- **4-layer** stackup: Sig / GND / PWR / Sig.
- ESP32-C6 **antenna keep-out**: no copper any layer; module antenna at a board
  edge, nothing metal/battery behind it.
- **USB D+/D−** routed as a ~90 Ω diff pair, short, ESD (U6) at the connector.
- Fat short traces on VBUS/VBAT; thermal copper under the LDO.
- E-ink charge-pump caps (C14–C19) tight to J2.
- Star-ground the audio amp; keep speaker return off the RF pour.
- Run **DRC** clean before plotting.

## 4. Plot Gerbers for JLCPCB

`File > Plot`:

| Setting | Value |
|---|---|
| Layers | F.Cu, B.Cu, In1.Cu, In2.Cu, F/B.SilkS, F/B.Mask, F/B.Paste (for stencil), Edge.Cuts |
| Format | Gerber |
| Coordinate | 4.6, mm |
| Use Protel filename extensions | optional (JLCPCB accepts both) |
| Plot border/title | off |

Then `Generate Drill Files` (Excellon, mm, single file or PTH/NPTH per JLCPCB).
Zip the whole plot output → upload to JLCPCB "Add gerber file".

## 5. Assembly files (PCBA)

- **BOM:** use `../BOM.csv` (already JLCPCB format; re-verify LCSC stock).
- **CPL/placement:** `File > Fabrication Outputs > Component Placement (.pos)` →
  export the front (and back if used) `.pos`, rename columns to JLCPCB's
  Designator/Mid X/Mid Y/Layer/Rotation if prompted.
- In JLCPCB's order: enable SMT Assembly, upload BOM + CPL, review part
  rotations (watch the ESP32-C6 module and USB-C polarity).

## 6. Stack-to-Gerber checklist

- [ ] `python pager.py` runs, ERC clean
- [ ] Netlist imported, every ref placed
- [ ] Edge.Cuts outline + M2 holes
- [ ] Antenna keep-out honored
- [ ] USB diff pair + ESD placed
- [ ] DRC clean
- [ ] Gerbers + drill zipped
- [ ] BOM + CPL exported for PCBA
