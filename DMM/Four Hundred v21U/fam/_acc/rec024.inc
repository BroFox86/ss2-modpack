// 400SCP patch
// replaced reflection texture with cubemap

// Part of the following texture sets:
//	Res_3	REC024

render_material_only
terrain_scale 64

render_pass {
	texture FAM/_ACC/senstim_cube
	alpha 0.4
	blend SRC_ALPHA ZERO
	uv_source ENVIRONMENT
	uv_mod SCALE 1 1
}

render_pass {
	texture FAM/_ACC/REC024
	shaded
}
