// 400SCP patch
// rec1 water caustic effect added

render_material_only
terrain_scale 32

# fake caustic pass 1
render_pass {
	texture material/scp/fam/caustic
	blend SRC_ALPHA ZERO
	uv_mod scale 0.12 0.12
	uv_mod scroll 0.1 -0.15
	alpha 0.06
}

# fake caustic pass 2
render_pass {
	texture material/scp/fam/caustic
	blend SRC_ALPHA ONE
	uv_mod scale 0.11 0.11
	uv_mod scroll 0.1 0.14
	uv_mod rotate 90
	alpha 0.06
}

# ceiling
render_pass {
	texture FAM/_ACC/StnTil6
	blend ONE ONE
	shaded
}
