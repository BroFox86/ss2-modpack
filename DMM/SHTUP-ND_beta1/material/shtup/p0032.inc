render_material_only 1
ani_frames 1
terrain_scale 64

# background
render_pass {
	texture material/shtup/fam/p0032_m1
}

# scrolling bar
render_pass {
	texture material/shtup/fam/p0032_m2
	blend SRC_ALPHA ONE
	uv_mod scroll -1.25 0
}

include ../../material/shared/monitor.inc
