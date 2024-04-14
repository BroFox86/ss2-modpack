// Part of the following texture sets:
//	WaterHw	BLIN
//	WaterHw	BLOUT

render_material_only 1
ani_frames 1

render_pass {
	texture FAM/_ACC/blin
	alpha 0.25
	uv_mod scroll 0.1 0.11
}

render_pass {
	texture  FAM/_ACC/blin2
	alpha 0.25
	uv_mod scroll -0.12 -0.13
}
