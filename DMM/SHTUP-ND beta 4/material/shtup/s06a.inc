render_material_only 1
ani_frames 1

# damaged wall panel
render_pass {
	texture material/shtup/fam/s06a
	shaded 1
}

# orange lights
render_pass {
	ani_rate 900
	blend ONE ONE
	texture { "material/shtup/fam/s06am1" "material/shtup/fam/s06am1_1" "material/shtup/fam/s06am1_1"}
}
