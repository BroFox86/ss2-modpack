// 400SCP patch
// replaced small tiled texture with larger texture with tiling variation
// this displays wrong in DromEd but correctly in game mode, somehow

// Part of the following texture sets:
//   Eng_3     MM0009
//   Eng_3     MM0015
//   Flt_3     YellowStripe2
//   Msg       D_WT5
//   MsgTest   MM0008
//   Ops_3     MM0009
//   Res_3     D_WT5
//   Ricken_3  YS2

render_material_only
tile_factor 2 4

render_pass {
	texture FAM/_ACC/StripeYel4
	shaded
}
