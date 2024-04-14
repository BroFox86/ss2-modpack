// 400SCP patch
// fixed entire texture being fullbright

// Part of the following texture sets:
// Once again, because of the way the engine handles light,
// it's not possible to actually make the bulbs shine without
// making it "wrong".
//	Res_Mar2	caslit

terrain_scale 64
render_material_only
ani_frames 1

render_pass	{
	texture FAM/_ACC/caslit
	shaded
}

render_pass {
	texture FAM/_ACC/caslit_luma
	uv_mod scroll 0 1 0 4
}
