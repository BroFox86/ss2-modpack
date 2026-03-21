render_material_only 1
ani_frames 1
terrain_scale 64

# background
render_pass {
	texture material/shtup/fam/p0011_m1
}

# pulsing "ATTENTION"
render_pass {
	texture material/shtup/fam/p0011_m2
	blend SRC_ALPHA ONE
	alpha func wave TRIANGLE 0.31 0.69 0.0 800
}

include ../../material/shtup/_screen.inc
