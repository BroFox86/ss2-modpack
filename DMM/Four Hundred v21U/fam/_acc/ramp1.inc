// 400SCP patch
// fixed entire texture being fullbright

// Part of the following texture sets:
//   Eng_3     WLITE
//   Msg       W_Lights_1
//   MsgTest   WLITE

render_material_only
terrain_scale 32 128
ani_frames 1

render_pass {
	texture FAM/_ACC/RampA
	rgb 0.3 0.3 0.3
}

render_pass {
	texture FAM/_ACC/RampD
	uv_mod scroll 0 1 0 4
	blend ONE ONE
}
