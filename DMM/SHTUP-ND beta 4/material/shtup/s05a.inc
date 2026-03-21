render_material_only 1
ani_frames 1

# damaged wall panel
render_pass {
	texture material/shtup/fam/s05a
	shaded 1
}

# yellow-red + orange lights
render_pass {
	ani_rate 500
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s05am1
}
