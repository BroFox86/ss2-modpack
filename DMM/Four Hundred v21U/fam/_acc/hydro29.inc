// 400SCP patch
// replaced reflection texture with cubemap

// Part of the following texture sets:
//	Hydro_1	HYDRO29

terrain_scale 128
render_material_only

render_pass {
	texture FAM/_ACC/hydro_cube
	alpha 0.8
	blend SRC_ALPHA ZERO
	uv_source ENVIRONMENT
}

render_pass	{
	texture FAM/_ACC/HYDRO29
	shaded
}
