// 400SCP patch
// replaced reflection texture with cubemap

// Part of the following texture sets:
//	Shared	GRAV002

render_material_only
terrain_scale 64

render_pass {
	texture FAM/_ACC/gloss_cube
	alpha 0.35
	blend SRC_ALPHA ZERO
	uv_source ENVIRONMENT
}

render_pass	{
	texture FAM/_GROSNUS/GRAV002
	shaded
}
