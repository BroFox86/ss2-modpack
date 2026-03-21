render_material_only 1
ani_frames 1

# wall panel
render_pass {
	texture material/shtup/fam/s06
	shaded 1
}

# yellow-red lights
render_pass {
	ani_rate 500
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s06m1
}

# orange lights
render_pass {
	ani_rate 900
	blend ONE ONE
	texture { "material/shtup/fam/s06m2" "material/shtup/fam/s06m2_1" "material/shtup/fam/s06m2_1"}
}

# purple lights
render_pass {
	ani_rate 250
	blend ONE ONE
	texture { "material/shtup/fam/s06m3" "material/shtup/fam/s06m3_1" "material/shtup/fam/black" "material/shtup/fam/black" "material/shtup/fam/black"}
}
