// 400SCP patch
// added reflection to blue parts of image

// Part of the following texture sets:
//	Res_Mark	fandes02
terrain_scale 128
render_material_only

render_pass {
	texture FAM/_ACC/gloss_cube
	uv_source ENVIRONMENT
	alpha 0.03
	blend SRC_ALPHA ZERO
}

render_pass {
	texture FAM/_ACC/fandes02_mask
	blend ZERO SRC_COLOR
}

render_pass {
	texture FAM/_ACC/fandes02
	blend ONE ONE
	shaded
}