render_material_only 1
ani_frames 1
terrain_scale 32

# background
render_pass {
	texture material/shtup/fam/p0006_m1
}

# pulsing "OK."
render_pass {
	texture material/shtup/fam/p0006_m2
	blend SRC_ALPHA ONE
	alpha func wave SAWTOOTH 0 1 0 1000
}

include ../../material/shtup/_screen.inc
