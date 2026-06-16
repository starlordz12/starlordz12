// =====================================================================
//  ESP32-C6 Pager — parametric enclosure
//  Two-part shell (front bezel + back shell) for the 2.9" e-ink pager.
//
//  Open in OpenSCAD. Set `part` to preview/export each piece:
//     "assembled" – both halves + ghosted PCB, for sanity-checking fit
//     "print"     – both halves laid flat on the bed, ready to export STL
//     "front"     – front bezel only
//     "back"      – back shell only
//
//  Everything below the divider is tunable. The packaging (battery under
//  PCB, port heights) is approximate — open in OpenSCAD, drop in your real
//  cell/connector heights, and adjust `standoff_h` and `port_z`.
// =====================================================================

part = "assembled";   // "assembled" | "print" | "front" | "back"
$fn = 72;

// ---- overall body ----------------------------------------------------
body_w   = 50;    // X  width
body_l   = 112;   // Y  length
body_t   = 16;    // Z  total thickness
wall     = 2.0;   // side wall thickness
corner_r = 6;     // rounded vertical corners
front_face = 2.0; // bezel front plate thickness
back_face  = 2.0; // back plate thickness

split = 10;       // Z height of the parting line (back shell is 0..split)
lip_h = 3;        // registration lip height on back shell
fit   = 0.2;      // print clearance on mating lip

// ---- PCB (from DESIGN.md board outline) -------------------------------
pcb_w = 40; pcb_l = 78; pcb_t = 1.6;
pcb_hole_inset = 4;          // mount-hole inset from PCB edge
standoff_d = 5;              // PCB standoff outer diameter
standoff_h = 7;              // height of PCB above back inner floor (clears cell)
insert_d   = 3.2;            // M2 heat-set insert pilot (use ~1.6 for self-tap)
pcb_y = body_l/2 - wall - 4 - pcb_l/2;   // PCB pushed toward the top

// ---- battery pocket (slim 1100 mAh, ~50 x 34 x 6.5) -------------------
batt_w = 35; batt_l = 51; batt_h = 6.6;
batt_y = -body_l/2 + wall + 4 + batt_l/2; // toward the bottom

// ---- display window (2.9" active area 66.9 x 29.1) -------------------
win_w = 30; win_l = 67;
win_y = body_l/2 - 8 - win_l/2;   // 8 mm top margin
halo_w = 3.0;   // NeoPixel diffuser ring width around the window
halo_d = 1.2;   // halo recess depth in the outer face

// ---- front buttons ----------------------------------------------------
btn_d   = 8;
btn_gap = 20;
btn_y   = win_y - win_l/2 - 11;

// ---- speaker grille ---------------------------------------------------
spk_hole_d = 1.6; spk_pitch = 5; spk_cols = 3; spk_rows = 3;
spk_y = btn_y - 15;

// ---- side ports (tune Z to your assembled stack) ----------------------
port_z   = back_face + standoff_h + pcb_t + 1.6;  // ~connector mid-height
usb_w = 9.5; usb_h = 3.4;     // USB-C, bottom edge (-Y)
sw_w  = 8.0; sw_h  = 3.6;     // audio slide switch, right edge (+X)
sw_y  = -8;                   // switch position along length

// ---- case screw bosses (4 corners) -----------------------------------
boss_d = 5.2; boss_x = body_w/2 - 6; boss_y = body_l/2 - 6;
screw_clear = 2.3;            // M2 clearance (back half)
boss_pilot  = 1.6;            // M2 self-tap (front half) — or insert_d for inserts

// ---- belt clip --------------------------------------------------------
clip      = true;
clip_w    = 16; clip_len = 60; clip_gap = 6; clip_t = 2.8;
clip_lip  = 3;

// =====================================================================
//  helpers
// =====================================================================
module rrect2d(w, l, r) {
    hull() for (sx=[-1,1], sy=[-1,1])
        translate([sx*(w/2-r), sy*(l/2-r)]) circle(r=r);
}

// solid outer body
module outer_solid()
    linear_extrude(body_t) rrect2d(body_w, body_l, corner_r);

// inner cavity (between the two faces)
module cavity()
    translate([0,0,back_face])
        linear_extrude(body_t - back_face - front_face)
            rrect2d(body_w - 2*wall, body_l - 2*wall, max(0.5, corner_r-wall));

// closed shell (both faces + walls)
module case_blank() difference() { outer_solid(); cavity(); }

// =====================================================================
//  internal structure (PCB standoffs, bosses, battery rib) — lives 0..split-ish
// =====================================================================
module pcb_standoffs() {
    for (sx=[-1,1], sy=[-1,1])
        translate([sx*(pcb_w/2-pcb_hole_inset), pcb_y + sy*(pcb_l/2-pcb_hole_inset), back_face])
        difference() {
            cylinder(d=standoff_d, h=standoff_h);
            translate([0,0,standoff_h-3]) cylinder(d=insert_d, h=3.1);
        }
}

module screw_bosses() {
    for (sx=[-1,1], sy=[-1,1])
        translate([sx*boss_x, sy*boss_y, back_face])
            cylinder(d=boss_d, h=body_t - back_face - front_face);
}

module screw_holes() {
    for (sx=[-1,1], sy=[-1,1]) translate([sx*boss_x, sy*boss_y, 0]) {
        // clearance through the back half
        translate([0,0,-0.1]) cylinder(d=screw_clear, h=split+0.1);
        // pilot in the front half
        translate([0,0,split]) cylinder(d=boss_pilot, h=body_t);
        // counterbore on the back outer face for the screw head
        translate([0,0,-0.1]) cylinder(d=4.0, h=1.6);
    }
}

module battery_rib() {
    // low rib ring to corral the cell on the floor
    translate([0, batt_y, back_face])
    difference() {
        linear_extrude(2.5) offset(1.2) square([batt_w, batt_l], center=true);
        translate([0,0,-0.1]) linear_extrude(3) square([batt_w, batt_l], center=true);
    }
}

// =====================================================================
//  cutouts (subtracted from the whole assembled model, so a port that
//  straddles the parting line notches both halves correctly)
// =====================================================================
module cutouts() {
    // display window through the front face
    translate([0, win_y, body_t - front_face - 0.1])
        linear_extrude(front_face + 0.2) rrect2d(win_w, win_l, 2);

    // NeoPixel halo recess on the outer front face
    translate([0, win_y, body_t - halo_d])
        linear_extrude(halo_d + 0.1)
            difference() {
                rrect2d(win_w + 2*halo_w, win_l + 2*halo_w, 3);
                rrect2d(win_w, win_l, 2);
            }

    // buttons
    for (sx=[-1,1])
        translate([sx*btn_gap/2, btn_y, body_t - front_face - 0.1])
            cylinder(d=btn_d, h=front_face + 0.2);

    // speaker grille
    for (cx=[0:spk_cols-1], cy=[0:spk_rows-1])
        translate([ (cx-(spk_cols-1)/2)*spk_pitch,
                    spk_y + (cy-(spk_rows-1)/2)*spk_pitch,
                    body_t - front_face - 0.1])
            cylinder(d=spk_hole_d, h=front_face + 0.2);

    // USB-C — bottom edge (-Y)
    translate([0, -body_l/2 - 0.1, port_z])
        rotate([-90,0,0])
            linear_extrude(wall + 0.4) offset(0.6) square([usb_w, usb_h], center=true);

    // audio slide switch — right edge (+X)
    translate([body_w/2 - wall - 0.1, sw_y, port_z])
        rotate([0,90,0])
            linear_extrude(wall + 0.4) offset(0.4) square([sw_h, sw_w], center=true);

    screw_holes();
}

// =====================================================================
//  registration lip on the back shell (sits inside the front wall)
// =====================================================================
module reg_lip()
    translate([0,0,split])
        linear_extrude(lip_h)
            difference() {
                rrect2d(body_w - 2*wall - 2*fit, body_l - 2*wall - 2*fit, corner_r-wall);
                rrect2d(body_w - 2*wall - 2*fit - 2, body_l - 2*wall - 2*fit - 2, max(0.5,corner_r-wall-1));
            }

// =====================================================================
//  belt clip on the back (outside, -Z)
// =====================================================================
module belt_clip() {
    cw = clip_w; t = clip_t;
    translate([0, body_l/2 - 12, 0]) {
        // root bridging to the back face
        translate([-cw/2, 0, -t]) cube([cw, 8, t]);
        // top return
        translate([-cw/2, -2, -clip_gap - t]) cube([cw, 8, t]);
        // sprung arm running down the back
        translate([-cw/2, -clip_len, -clip_gap - t]) cube([cw, clip_len, t]);
        // grip lip at the free end
        translate([-cw/2, -clip_len, -clip_gap - t]) cube([cw, t, clip_lip + t]);
        // connect root to arm (short vertical web)
        translate([-cw/2, -2, -clip_gap - t]) cube([cw, t, clip_gap]);
    }
}

// =====================================================================
//  full assembled model (before splitting)
// =====================================================================
module full_model() {
    difference() {
        union() {
            case_blank();
            pcb_standoffs();
            screw_bosses();
            battery_rib();
            reg_lip();
            if (clip) belt_clip();
        }
        cutouts();
    }
}

// split helpers
module below(z) intersection() { children(); translate([-body_w, -body_l, -clip_gap-clip_t-5]) cube([2*body_w, 2*body_l, z + clip_gap+clip_t+5]); }
module above(z) intersection() { children(); translate([-body_w, -body_l, z]) cube([2*body_w, 2*body_l, body_t - z + 5]); }

module back_shell()  below(split) full_model();
module front_bezel() above(split) full_model();

// ghost PCB for the assembled view
module ghost_pcb()
    translate([0, pcb_y, back_face + standoff_h])
        color([0.1,0.5,0.2,0.4]) linear_extrude(pcb_t) rrect2d(pcb_w, pcb_l, 2);

// =====================================================================
//  render selector
// =====================================================================
if (part == "assembled") {
    back_shell();
    color([0.7,0.7,0.75,0.55]) front_bezel();
    ghost_pcb();
} else if (part == "front") {
    front_bezel();
} else if (part == "back") {
    back_shell();
} else if (part == "print") {
    // back shell flat (belt clip up), front bezel flipped face-down beside it
    translate([-body_w/2 - 6, 0, 0]) back_shell();
    translate([ body_w/2 + 6, 0, body_t])
        rotate([180,0,0]) front_bezel();
}
