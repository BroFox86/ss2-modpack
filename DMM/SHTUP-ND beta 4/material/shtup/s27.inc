render_material_only 1
ani_frames 1

# control panel
render_pass {
	texture material/shtup/fam/s27
	shaded 1
}

# red lights
render_pass {
	ani_rate 360
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s27m1
}
