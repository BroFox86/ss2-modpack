render_material_only 1
ani_frames 1

# purple lights
render_pass {
	ani_rate 180
	blend ONE ZERO
	texture *_ 0 material/shtup/fam/s03m1
	uv_mod scale 4 2
	uv_mod offset 0 0.2344
}

# yellow-red lights
render_pass {
	ani_rate 900
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s03m2
	uv_mod scale 4 2
	uv_mod offset 0 0.2344
}

# red lights
render_pass {
	ani_rate 360
	blend ONE ONE
	texture *_ 0 material/shtup/fam/s03m3
	uv_mod scale 4 2
	uv_mod offset 0 0.2344
}

# wall panel
render_pass {
	texture material/shtup/fam/s03
	shaded 1
}
