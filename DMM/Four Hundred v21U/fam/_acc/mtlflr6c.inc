// 400SCP patch
// replaced small tiled texture with larger texture with tiling variation
// this displays wrong in DromEd but correctly in game mode, somehow

// Part of the following texture sets:
//	Eng_2       MF0019   32x32  a
//	Msg         DIAMOND  32x32  a	
//	Msgtest     MF0019   32x32  a
//	Eng_2       MF0021   16x16  b
//	Flt_2       MF0020   16x16  b
//	Msg         DIAMOND2 16x16  b
//	Msgtest     MF0020   16x16  b
//	Eng_2       MF0020   8x8    c
//	Msg         DIAMOND3 8x8    c
//	Msgtest     MF0002   8x8    c

render_material_only
tile_factor 16

render_pass {
	texture FAM/_ACC/MtlFlr6z
	shaded
}
