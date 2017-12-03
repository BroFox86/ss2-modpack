render_material_only 1
ani_frames 1
terrain_scale 32

# scrolling background
render_pass {
	texture material/shtup/fam/p0031_m1
	uv_mod scroll -0.35 0
}

# scrolling distant background
render_pass {
	texture material/shtup/fam/p0031_m1
	uv_mod scroll -0.35 0
	uv_mod scale 3 3
	blend SRC_ALPHA ONE
	alpha 0.25
}

include ../../material/shared/monitor.inc
