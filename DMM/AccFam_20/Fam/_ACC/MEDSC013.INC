// Part of the following texture sets:
//	MedSci_2	MedSc013
//	MedSci_2	MedSc031 (no stripes)
//	Res_1			MEDSC013
//	Res_1			MEDSC031 (no stripes)
//	Ops_2			OPS020	(darker)
//	Ops_2			OPS021	(darker, no stripes)
terrain_scale 128
render_material_only 1
render_pass
	{
	texture FAM\_ACC\MEDSC013_ENV
	uv_source ENVIRONMENT
	uv_mod SCALE 1.2 1.2
	shaded 1
	}
render_pass
	{
	texture FAM\_ACC\MEDSC013
	shaded 1
	}