// Part of the following texture sets:
//	Res_Mar2	CASDES
terrain_scale 128
render_material_only 1
ani_frames 1
render_pass
	{
	texture FAM\_ACC\CASDES_ENV
	uv_source ENVIRONMENT
	alpha 1.00
	uv_mod SCALE 2.0 2.0
	shaded 1
	}
render_pass
	{
	texture FAM\_ACC\CASDES
	shaded 1
	}
render_pass
	{
	uv_mod UOFFSET_WAVE SINE 0 1.5 16 2000 4
	uv_mod VOFFSET_WAVE TRIANGLE .5 1 32 2000 4
	texture FAM\_ACC\CASDES_LUMA
	blend SRC_ALPHA ONE
	alpha .7
	shaded 1
	}