render_material_only 1
ani_frames 1

# wall panel
render_pass {
	texture material/shtup/fam/s07
	shaded 1
}

# green light
render_pass {
	blend SRC_ALPHA ONE
	texture material/shtup/fam/s07m1
	alpha func WAVE TRIANGLE 0.06 0.94 0 1750 3
}

# short green light
render_pass {
	blend SRC_ALPHA ONE
	texture material/shtup/fam/s07m2
	alpha func WAVE SAWTOOTH 0.32 0.68 0 2700 3
}

# orange light
render_pass {
	ani_rate 500
	blend ONE ONE
	texture { "material/shtup/fam/s07m3" "material/shtup/fam/s07m3_1" "material/shtup/fam/s07m3_2" "material/shtup/fam/s07m3_3" "material/shtup/fam/s07m3_1" }
}
