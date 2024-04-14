// 400SCP patch
// removed reflection
// toned down intensity of glow
// made glow animate instead of just pulsing

// Part of the following texture sets:
//   FLT_2/ENGC04-1  (grey, no luma)
//   FLT_2/ENGC04-2  (grey, luma    > REC028_ENV, ENGC_LUMA)
//   FLT_3/FLT033    (purple, luma  > GFX_ENVCMD, ENGC_LUMA)
//   ENG_1/ENGC04    (green, luma   > MEDSC011_ENV, ENGC_LUMA)

render_material_only
terrain_scale 128

render_pass	{
	texture FAM/_ACC/ENGC_LUMA
	uv_mod SCALE 0.4 0.4
	uv_mod SCROLL 0.25 0.1
}

render_pass {
	texture FAM/_ACC/ENGC04-2
	shaded
}

