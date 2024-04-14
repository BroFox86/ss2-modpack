// 400SCP patch
// replaced reflection texture with cubemap
// improved sparkle effect

// Part of the following texture sets:
//	Res_Mar2	CASDES

terrain_scale 128
render_material_only
ani_frames 1

render_pass {
	texture FAM/_ACC/casino_cube
	alpha 0.5
	blend SRC_ALPHA ZERO
	uv_source ENVIRONMENT
}

render_pass {
	texture FAM/_ACC/CASDES
	shaded
}

render_pass {
	texture FAM/_ACC/CASDES_LUMA
	uv_mod SCROLL 0.001 0
	alpha func WAVE SINE 0 0.75 0 1200
	blend SRC_ALPHA ONE
	shaded
}

render_pass {
	texture FAM/_ACC/CASDES_LUMA
	uv_mod ROTATE 90
	uv_mod SCROLL 0.001 0
	alpha func WAVE SINE 0 0.75 0.33 1200
	blend SRC_ALPHA ONE
	shaded
}

render_pass {
	texture FAM/_ACC/CASDES_LUMA
	uv_mod ROTATE 180
	uv_mod SCROLL 0.001 0
	alpha func WAVE SINE 0 0.75 0.66 1200
	blend SRC_ALPHA ONE
	shaded
}
