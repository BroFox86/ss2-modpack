render_material_only 1
ani_frames 1

# computer console
render_pass {
	texture material/shtup/fam/s25
	shaded 1
}

# purple tubes
render_pass {
	ani_rate 180
	blend ONE ONE
	texture { "material/shtup/fam/s25m1" "material/shtup/fam/s25m1_1" "material/shtup/fam/s25m1_2" "material/shtup/fam/black" "material/shtup/fam/black" }
}

# orange screen
render_pass {
	ani_rate 500
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s25m2
}
