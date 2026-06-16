# Enclosure — 3D-Printed Pager Shell

A two-part snap/screw shell sized to land the classic pager look: wider than a
keyfob, thin enough to clip on a belt, e-ink readout front and center.

See `pager-concept.svg` for the front-panel mockup.

> A printable parametric model of this spec lives in `enclosure/pager.scad`.

## Overall dimensions

| Dim | Value | Driver |
|-----|-------|--------|
| Footprint | **112 × 50 mm** | 2.9" module (~79 × 37 mm) needs room *below* it for the buttons + speaker |
| Thickness | **16 mm** | 1.6 mm PCB on 7 mm standoffs over a ~6.6 mm LiPo + e-ink + clearances |
| Wall thickness | 2.0 mm | PETG/ASA stiffness |
| Corner radius | 6 mm | rounded pager feel |
| Display window | 67 × 30 mm | matches 2.9" active area (66.9 × 29.1 mm), 8 mm top margin |

(Earlier drafts listed 84 × 46 × 14 mm — that couldn't fit the ~79 mm display
module *and* a button row + speaker on the front, so the body grew to 112 × 50 × 16.
Shrink it back in the `.scad` once you confirm the real packing.)

## Parts (print)

1. **Front bezel** — display window, button caps, speaker grille, NeoPixel
   diffuser ring around the screen, recessed "PAGER" badge area.
2. **Back shell** — battery pocket, PCB standoffs (4× M2), USB-C cutout, side
   slide-switch cutout, integrated **belt clip** (or a clip boss for a metal clip).
3. *(optional)* **Light pipe ring** — clear/natural filament ring over the 8
   SK6812s so the notification glow wraps the bezel like a halo.

## Cutouts & features

- **USB-C port:** bottom edge, 9 × 3.5 mm slot aligned to J1.
- **Audio slide switch:** right side, 8 × 3 mm window with a finger ridge — flip
  it without opening the case (this is the mechanical mute).
- **Buttons:** two front tactile caps (ACK / MENU) over SW1/SW2; flexible TPU
  caps or printed posts with a thin living-hinge membrane.
- **Speaker grille:** 3×3 array of 1.5 mm holes over SPK1, behind the front face.
- **Belt clip:** spring-arm clip molded into the back, or 2 bosses for a
  screw-on metal spring clip (more durable — recommended).
- **NeoPixel halo:** translucent ring inset in the bezel; print front face in a
  light-blocking color so only the ring and window pass light.

## Assembly stack (front → back)

```
Front bezel
  └ e-ink panel (taped to bezel, FPC folded down to J2)
      └ PCB (4× M2 to back-shell standoffs)
          └ LiPo cell (in back pocket, double-sided foam tape, JST to J3)
              └ speaker (grille pocket, JST to J4)
Back shell + belt clip
```

## Print settings

- **Material:** PETG or ASA (heat + UV tolerance for something carried around;
  PLA is fine for a first prototype).
- **Layer height:** 0.16 mm walls / 0.2 mm draft.
- **Walls/top/bottom:** 3 perimeters, 4 top/bottom layers.
- **Infill:** 20–30% gyroid.
- **Supports:** only under the belt-clip arm and switch overhang.
- **Tolerance:** 0.2 mm clearance on snap fits; print a 10 mm fit-test coupon of
  the USB-C + switch cutouts before committing the full shell.

## Closure

- 4× **M2 × 6 mm** screws into heat-set brass inserts in the back-shell standoffs
  (more serviceable than snap-fits for a device you'll reflash/open).
- Optional 1 mm TPU gasket in the bezel groove for splash resistance.

## Printable model

The parametric model is in **`enclosure/pager.scad`** — open it in OpenSCAD, set
`part` to `"print"`, and export STL. Wall thickness, cell size, standoff height,
port positions, and the window are all variables. See `enclosure/README.md` for
the knobs to tune to your exact parts.
