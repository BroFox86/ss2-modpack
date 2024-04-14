// the original size is 16x16, but hey, let's add an extra height.
// Part of the following texture sets:
//	Hydro_1	MTL4
terrain_scale 32 16
render_material_only 1
render_pass
	{
	uv_mod ROTATE -90
	uv_mod OFFSET 0 .5	
	texture FAM\_ACC\MtlBeam2
	shaded 1
	}