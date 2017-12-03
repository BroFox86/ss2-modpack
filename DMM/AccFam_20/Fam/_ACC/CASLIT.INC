// Part of the following texture sets:
// Once again, because of the way the engine handles light,
// it's not possible to actually make the bulbs shine without
// making it "wrong".
//	Res_Mar2	caslit
terrain_scale 64
render_material_only 1
ani_frames 1
render_pass
	{
	texture FAM\_ACC\caslit
	shaded 1
	}
render_pass
	{
	uv_mod scroll 0 1.5 0 4
	texture FAM\_ACC\caslit_luma
	blend SRC_ALPHA ONE
	shaded 1
	}