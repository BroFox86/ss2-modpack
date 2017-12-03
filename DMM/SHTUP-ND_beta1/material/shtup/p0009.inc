render_material_only 1
ani_frames 1
terrain_scale 32

# background
render_pass {
	texture material/shtup/fam/p0009_m1
}

# pulsing "0"
render_pass {
	texture material/shtup/fam/p0009_m2
	blend SRC_ALPHA ONE
	alpha func wave TRIANGLE 0.25 0.75 0.0 1100
}

# pulsing "1"
render_pass {
	texture material/shtup/fam/p0009_m3
	blend SRC_ALPHA ONE
	alpha func wave TRIANGLE 0.25 0.75 0.1 1100
}

include ../../material/shared/monitor.inc
