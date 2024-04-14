// Part of the following texture sets:
//	Ops_3			OPS009 (red stripe, dark metal)
//	Eng_1			ENGC03 (green stripe, light metal)
terrain_scale 128
render_material_only 1
render_pass
	{
	texture FAM\_ACC\ENGC03
	shaded 1
	}
render_pass
	{
	texture FAM\_ACC\ENGC03_LUMA
	alpha func wave TURB .90 .05 1 1500
	blend SRC_ALPHA ONE
	}