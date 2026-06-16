# Enclosure — parametric OpenSCAD model

`pager.scad` is the printable two-part shell for the pager, driven by the spec in
`../ENCLOSURE.md`. It was authored without a live OpenSCAD to render it, so **open
it in OpenSCAD and preview before printing** — and tune the packaging knobs to your
actual cell and connector heights.

## Use

1. Open `pager.scad` in OpenSCAD (free, all platforms).
2. Set the `part` variable at the top:
   - `"assembled"` — both halves + a ghosted PCB, to check fit
   - `"print"` — both halves laid flat, ready to export
   - `"front"` / `"back"` — a single piece
3. F5 to preview, F6 to render, then **File > Export > STL**.
4. Slice (PETG/ASA recommended; see `../ENCLOSURE.md` for print settings).

## Knobs you'll most likely touch

| Variable | Why |
|---|---|
| `standoff_h` | Height of the PCB above the floor — set so your LiPo cell clears underneath. |
| `port_z` | Vertical center of the USB-C + slide-switch cutouts — match your assembled board height. |
| `body_t` | Total thickness — shrink once you've confirmed the real stack fits. |
| `win_w`, `win_l`, `win_y` | Display window to your exact panel's active area + position. |
| `batt_w/l/h` | Battery pocket to your exact cell. |
| `clip` | `false` to drop the integrated belt clip (e.g. to use a screw-on metal clip). |
| `boss_pilot` | `1.6` for M2 self-tap into plastic, or set to `insert_d` for heat-set inserts. |

## Modeled features

- Rounded two-part shell with a registration lip and 4× corner M2 screw bosses
  (screw from the back, into the front bezel).
- Display window + a recessed **NeoPixel halo ring** around it.
- Two front button holes, a 3×3 speaker grille.
- USB-C cutout (bottom edge) and audio slide-switch cutout (right edge), both cut
  from the assembled model so they notch the correct half automatically.
- PCB standoffs (M2), a battery-pocket corral rib, and an integrated sprung belt clip.

## Caveats

- The internal packaging (battery under the PCB, port heights) is a **starting
  approximation**. Real fit depends on your exact cell, connectors, and the routed
  board — verify in the `"assembled"` view and adjust.
- This is a geometry model, not a stress analysis. Print a fit-test of the USB-C +
  switch cutout band before committing the full shell (noted in `../ENCLOSURE.md`).
