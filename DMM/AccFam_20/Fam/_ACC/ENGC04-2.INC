// Part of the following texture sets:
//	FLT_2/ENGC04-1	(grey, no luma)
//	FLT_2/ENGC04-2	(grey, luma		> REC028_ENV, ENGC04-2_LUMA)
//	FLT_3/FLT033		(purple, luma	> GFX_ENVCMD, ENGC04-2_LUMA)
//	ENG_1/ENGC04		(green, luma	> MEDSC011_ENV, ENGC04-2_LUMA)
terrain_scale 128
render_material_only 1
render_pass
	{
	texture FAM\_ACC\ENGC04-2
	shaded 1
	}
render_pass
	{
	texture FAM\_ACC\REC028_ENV
	uv_source ENVIRONMENT
	uv_mod SCALE 1.2 1.2
	alpha .45
	shaded 1
	}
render_pass
	{
	texture FAM\_ACC\ENGC04-2_LUMA
	alpha func wave SINE .60 .40 1 1500
	blend SRC_ALPHA ONE
	}