// Part of the following texture sets:
//	Shared	GRAV001
terrain_scale 128
render_material_only 1
render_pass
	{
	texture FAM\_GROSNUS\GRAV001
	shaded 1
	}
render_pass
	{
	texture FAM\_GROSNUS\GRAV001_LUMA
	alpha func wave SINE .70 .30 1 2000
	blend SRC_ALPHA ONE
	}