render_material_only 1
ani_frames 1

# purple lights
render_pass {
	ani_rate 180
	blend ONE ZERO
	texture *_ 0 material/shtup/fam/s02m1
	uv_mod scale 4 4
	uv_mod offset 0.5 0.42
}

# orange + short green lights
render_pass {
	ani_rate 900
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s02m2
	uv_mod scale 4 4
	uv_mod offset 0.5 0.42
}

# red lights
render_pass {
	ani_rate 360
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s02m3
	uv_mod scale 4 4
	uv_mod offset 0.5 0.42
}

# wall panel
render_pass {
	texture material/shtup/fam/s02
	shaded 1
}
