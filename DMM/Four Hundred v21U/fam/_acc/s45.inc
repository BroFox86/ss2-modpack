// Part of the following texture sets:
//	SHODAN	S45
terrain_scale 128
render_material_only 1
include ../_ACC/gfx_slickdark.inc
render_pass
	{
	texture FAM\_ACC\S45
	alpha func wave ABS_SINE 0.85 .15 1 1500
	shaded 1
	}