// 400SCP patch
// replaced small tiled texture with larger texture with tiling variation
// this displays wrong in DromEd but correctly in game mode, somehow

// Part of the following texture sets:
//	MedSci_2	MEDSC006

render_material_only
tile_factor 8

render_pass {
	texture FAM/_ACC/SqrTilWht1
	shaded
}
