render_material_only 0
ani_frames 1

# red light
render_pass {
	blend SRC_ALPHA ONE
	texture material/shtup/fam/s01am1
	alpha func WAVE INV_SAWTOOTH 0 1 0 2650 4
}
