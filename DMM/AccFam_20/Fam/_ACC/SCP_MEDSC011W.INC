// New to SCP beta3 (I wish it was an animated texture using frames instead of a material)
render_material_only
terrain_scale 128

render_pass {
	texture material/scp/fam/caustic
	blend SRC_ALPHA ZERO
	uv_mod scale 0.7 0.6
	uv_mod scroll 0.1 -0.15
	alpha 0.06
}

render_pass {
	texture material/scp/fam/caustic
	blend SRC_ALPHA ONE
	uv_mod scale 0.7 0.6
	uv_mod scroll 0.1 0.14
	uv_mod rotate 90
	alpha 0.06
}

render_pass {
	texture material/scp/fam/medscim
	blend ZERO SRC_COLOR
	uv_mod scale 1 0.666
	uv_mod offset 0 0.51
}

render_pass {
	texture FAM\_ACC\MEDSC011
	blend ONE ONE
	shaded 1
}