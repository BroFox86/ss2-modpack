// 400SCP patch
// replaced reflection texture with cubemap
// added some smudging

// Part of the following texture sets:
//	Res_Mark	plgrstr1

render_material_only
terrain_scale 128

render_pass {
	texture FAM/_ACC/gloss_cube
	uv_source ENVIRONMENT
	blend ONE ZERO
}

render_pass {
	texture FAM/_ACC/smudges
}

render_pass {
	texture FAM/_ACC/plgrstr1
	shaded
}
