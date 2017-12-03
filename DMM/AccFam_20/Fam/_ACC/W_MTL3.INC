// Part of the following texture sets:
//	Eng_2			W_MTL2 (horizontal, 128x32)
//	MedSci_1	W_MTL2 (horizontal, 128x32)
//	Eng_2			W_MTL3 (vertical, 32x128)
//	scs				W_MTL3 (vertical, 32x128)
terrain_scale 32 128
render_material_only 1
render_pass
	{
	uv_mod ROTATE -90
	uv_mod OFFSET 0 .5
	texture FAM\_ACC\W_MTL2
	shaded 1
	}