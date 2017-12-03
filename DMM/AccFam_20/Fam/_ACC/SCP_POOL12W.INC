// New to SCP beta3
terrain_scale 32 256
render_material_only 1

render_pass {
	texture material/scp/fam/caustic
	blend SRC_ALPHA ZERO
	uv_mod scale 0.12 1
	uv_mod scroll 0.1 -0.15
	alpha 0.06
}

render_pass {
	texture material/scp/fam/caustic
	blend SRC_ALPHA ONE
	uv_mod scale 0.11 1
	uv_mod scroll 0.1 0.14
	uv_mod rotate 90
	alpha 0.06
}

render_pass {
	texture material/scp/fam/pool12m
	blend ZERO SRC_COLOR
}
render_pass {
	texture FAM\_ACC\SCP_POOL12W
	blend ONE ONE
	shaded
}