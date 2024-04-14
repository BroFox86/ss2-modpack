render_material_only 1
ani_frames 1

# wall panel
render_pass {
	texture material/shtup/fam/s05
	shaded 1
}

# purple lights
render_pass {
	ani_rate 250
	blend ONE ONE
	texture { "material/shtup/fam/s05m1" "material/shtup/fam/s05m1_1" "material/shtup/fam/s05m1_2" "material/shtup/fam/black" "material/shtup/fam/black"	}
}

# yellow-red light
render_pass {
	ani_rate 500
	blend ONE ONE
	texture { "material/shtup/fam/s05m2" "material/shtup/fam/s05m2_1" "material/shtup/fam/s05m2_2" "material/shtup/fam/s05m2_3" "material/shtup/fam/s05m2_1" }
}
