render_material_only 1
ani_frames 1
terrain_scale 64

# scrolling plasma
render_pass {
	texture material/shtup/fam/p3_m2
	uv_mod scroll 0 -0.625
	uv_mod scale 0.5 0.5
}

# scrolling plasma
render_pass {
	texture material/shtup/fam/p3_m2
	blend ONE ONE
	uv_mod scroll 0 -0.5
	uv_mod scale 0.5 0.5
	uv_mod rotate 90
}

# grid
render_pass {
	texture material/shtup/fam/p123_m1
	blend SRC_ALPHA ONE
	alpha 0.5
}

