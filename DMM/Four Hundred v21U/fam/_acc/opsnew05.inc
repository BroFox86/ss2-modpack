// 400SCP patch
// replaced reflection texture with cubemap

// Part of the following texture sets:
//	OPSNEW	Opsnew05

render_material_only
terrain_scale 128

render_pass {
	texture FAM/_ACC/ops_cube
	alpha 0.5
	blend SRC_ALPHA ZERO
	uv_source ENVIRONMENT
}

render_pass {
	texture FAM/_ACC/OPSNEW05
	shaded
}
