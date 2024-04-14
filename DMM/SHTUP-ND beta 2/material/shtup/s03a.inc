render_material_only 1
ani_frames 1

# wall panel
render_pass {
	texture material/shtup/fam/s03a
	shaded 1
}

# red lights
render_pass {
	ani_rate 360
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s03am1
}
