// 400SCP patch
// replaced reflection texture with cubemap

// Part of the following texture sets:
//   MedSci_2   MedSc013
//   MedSci_2   MedSc031 (no stripes)
//   Res_1      MEDSC013
//   Res_1      MEDSC031 (no stripes)
//   Ops_2      OPS020   (darker)
//   Ops_2      OPS021   (darker, no stripes)

render_material_only
terrain_scale 128

render_pass {
	texture FAM/_ACC/ops_cube
	alpha 0.9
	blend SRC_ALPHA ZERO
	uv_source ENVIRONMENT
}

render_pass {
	texture FAM/_ACC/OPS021
	shaded
}