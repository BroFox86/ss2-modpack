render_material_only 1
ani_frames 1
terrain_scale 64

# grid
render_pass {
	texture material/shtup/fam/p123_m1
}

# scrolling pulse
render_pass {
	texture material/shtup/fam/p1_m2
	blend ONE ONE
	uv_mod scroll 0 -1.25
	uv_mod offset 0.5 0
}
