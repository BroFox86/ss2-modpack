// Part of the following texture sets:
//	Eng_3	Goo
force_opaque
render_material_only 1
ani_frames 1
render_pass
	{
	uv_mod ROTATE 180
	uv_mod SCROLL .01 .07 0 0
	texture FAM\_ACC\GOO
	shaded 1
	}
render_pass
	{
	uv_mod SCROLL .02 .09 0 0
	texture FAM\_ACC\GOO
	blend SRC_COLOR DST_COLOR
	shaded 1
	}
render_pass
	{
	uv_mod SCROLL .08 .01 0 0
	uv_mod ROTATE 90
	texture FAM\_ACC\GOO
	blend SRC_COLOR DST_COLOR
	shaded 1
	}
env_map 1 4 FAM\_ACC\GOO_ENV