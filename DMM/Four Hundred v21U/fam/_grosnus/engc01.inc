// 400SCP patch
// replaced reflection texture with cubemap

// Part of the following texture sets:
//	Eng_1	ENGC01

render_material_only
terrain_scale 128

render_pass {
	texture FAM/_ACC/gloss_cube
	alpha 0.15
	blend SRC_ALPHA ZERO
	uv_source ENVIRONMENT
}

render_pass	{
	texture FAM/_GROSNUS/ENGC01
	shaded
}
