render_material_only 1
ani_frames 1

# water layer
render_pass {
	texture material/shtup/fam/blin
	alpha .2
	uv_mod scroll 0.1 -0.15
}

# water layer again
render_pass {
	texture material/shtup/fam/blin
	alpha 0.1
	uv_mod scroll -0.1 0.14
}
