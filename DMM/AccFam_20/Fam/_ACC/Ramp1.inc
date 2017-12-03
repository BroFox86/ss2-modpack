// Part of the following texture sets:
//	Eng_3	WLITE
//	Msg	W_Lights_1
//	MsgTest	WLITE
terrain_scale 32 128
render_material_only 1
ani_frames 1
render_pass
	{
	texture FAM\_ACC\RampA
	shaded 0
	}
render_pass
	{
	uv_mod scroll 0 1.5 0 4
	texture FAM\_ACC\RampB
	blend SRC_ALPHA ONE
	shaded 0
	}