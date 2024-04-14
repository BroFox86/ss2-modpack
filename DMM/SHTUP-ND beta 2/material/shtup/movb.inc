# movie screen for original version of rec3
render_material_only 1
terrain_scale 64 64

# sweeping hand
render_pass {
	shaded 1
	ani_rate 50
	texture *_ 0 material/shtup/fam/movsw
	uv_mod OFFSET 0.5 0
	blend ONE ZERO
}

# countdown numbers
render_pass {
	shaded 1
	ani_rate 1000
	ani_mode REVERSE
	uv_mod OFFSET 0.5 0
	texture *_ 0 material/shtup/fam/movie
}

# screen mask
render_pass {
	shaded 1
	uv_mod SCALE 0.5 1
	uv_mod OFFSET 0.75 0
	texture material/shtup/fam/movie_m1
}
