// Part of the following texture sets:
//	MedSci_2	MedSc011
//	MedSci_2	DAMSC008 (burned wires)
terrain_scale 128
render_material_only 1
render_pass
	{
	texture FAM\_ACC\MEDSC011_ENV
	uv_source ENVIRONMENT
	uv_mod SCALE 2 2.5
	shaded 1
	}
render_pass
	{
	texture FAM\_ACC\DAMSC008
	shaded 1
	}