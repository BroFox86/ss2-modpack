render_material_only 1
ani_frames 1

# wall pipes
render_pass {
	texture material/shtup/fam/s23
	shaded 1
}

# green + purple lights
render_pass {
	ani_rate 350
	blend ONE ONE
	texture { "material/shtup/fam/s23m1" "material/shtup/fam/s23m1_1" "material/shtup/fam/s23m1_2" "material/shtup/fam/s23m1_3" "material/shtup/fam/s23m1_4" }
}
