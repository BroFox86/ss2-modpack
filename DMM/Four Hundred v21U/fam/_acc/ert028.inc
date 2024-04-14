// 400SCP patch
// replaced reflection texture with cubemap

// Part of the following texture sets:
//   Ert_2   ERT028

terrain_scale 64
render_material_only

render_pass {
	texture FAM/_ACC/earth_cube
	alpha 0.3
	blend SRC_ALPHA ZERO
	uv_source ENVIRONMENT
}

render_pass {
	texture FAM/_ACC/ERT028
	alpha 0.7
	blend SRC_ALPHA ONE
	shaded
}
