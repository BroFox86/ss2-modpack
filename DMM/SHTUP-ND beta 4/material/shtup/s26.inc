render_material_only 1
ani_frames 1

# relay access port
render_pass {
	texture material/shtup/fam/s26
	shaded 1
}

# purple lights
render_pass {
	ani_rate 180
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s26m1
}

# green + orange lights
render_pass {
	ani_rate 250
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s26m2
}

# red + yellow-red + short green lights
render_pass {
	ani_rate 400
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s26m3
}

