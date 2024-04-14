render_material_only 1
ani_frames 1

# wall panel
render_pass {
	texture material/shtup/fam/s09
	shaded 1
}

# green lights
render_pass {
	ani_rate 360
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s09m1
}

# short green lights
render_pass {
	ani_rate 900
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s09m2
}
