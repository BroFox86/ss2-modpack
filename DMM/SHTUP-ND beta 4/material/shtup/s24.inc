render_material_only 1
ani_frames 1

# healing incubator
render_pass {
	texture material/shtup/fam/s24
	shaded 1
}

# yellow-red + orange lights
render_pass {
	ani_rate 500
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s24m1
}

# green light
render_pass {
	blend SRC_ALPHA ONE
	texture material/shtup/fam/s24m2
	alpha func WAVE TRIANGLE 0.06 0.94 0 1750 3
}