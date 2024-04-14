// 400SCP patch
// replaced reflection texture with cubemap

// Part of the following texture sets:
//	Res_Mark	ARBOR01
//	Res_Mark	ARBOR01B

terrain_scale 128
render_material_only

render_pass {
	texture FAM/_ACC/gloss_cube
	alpha 0.4
	blend SRC_ALPHA ZERO
	uv_source ENVIRONMENT
}

render_pass	{
	texture FAM/_ACC/ARBOR01
	shaded
}
