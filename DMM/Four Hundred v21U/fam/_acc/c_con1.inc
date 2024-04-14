// Part of the following texture sets:
//	MsgTest	MW0010
//	MsgTest	MW0009 (light orange)
//	Msg		C_CON1 (light orange, 90°)
terrain_scale 64 128
render_material_only 1
render_pass
	{
	uv_mod ROTATE -90
	uv_mod OFFSET 0 .5
	texture FAM\_ACC\MW0009
	shaded 1
	}