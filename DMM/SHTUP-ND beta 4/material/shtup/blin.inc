render_material_only 1
ani_frames 1

# water layer
render_pass {
	texture material/shtup/fam/blin
	alpha 0.25
	uv_mod scroll 0.1 0.11
}

# water layer again
render_pass {
	texture material/shtup/fam/blin2
	alpha 0.25
	uv_mod scroll -0.12 -0.13
}
