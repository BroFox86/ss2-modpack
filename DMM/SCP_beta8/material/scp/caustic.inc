terrain_scale 32

render_pass {
	texture material/scp/fam/caustic
	blend SRC_ALPHA ONE
	uv_mod scale 0.12 0.12
	uv_mod scroll 0.1 -0.15
	alpha 0.06
}

render_pass {
	texture material/scp/fam/caustic
	blend SRC_ALPHA ONE
	uv_mod scale 0.11 0.11
	uv_mod scroll 0.1 0.14
	uv_mod rotate 90
	alpha 0.06
}
