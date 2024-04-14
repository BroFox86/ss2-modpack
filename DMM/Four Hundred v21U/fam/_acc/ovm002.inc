// Part of the following texture sets:
//	Ovrmnd_1	OVM002
terrain_scale 64
render_material_only 1
ani_frames 1
render_pass
	{
	texture FAM\_ACC\OVM002
	uv_mod SCROLL -.003 .001
	shaded 1
	}
render_pass
	{
	texture FAM\_ACC\OVM002_VEINS
	uv_mod UOFFSET_WAVE SINE 0.00 0.03 1 16000
	uv_mod VOFFSET_WAVE SINE 0.03 0.03 1 8900
	shaded 1
	}