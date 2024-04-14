render_material_only 1
ani_frames 1

# wall panel
render_pass {
	texture material/shtup/fam/s08
	shaded 1
}

# red light
render_pass {
	blend SRC_ALPHA ONE
	texture material/shtup/fam/s08m1
	alpha func WAVE INV_SAWTOOTH 0 1 0 2650 4
}
