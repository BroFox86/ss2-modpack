// Part of the following texture sets:
//	MedSci_2	MEDSC005
terrain_scale 128
render_material_only 1
render_pass
	{
	texture FAM\_ACC\MEDSC005
	shaded 1
	}
render_pass
	{
	texture FAM\_ACC\MEDSC005_LUMA
	alpha .9
	blend SRC_ALPHA ONE
	}