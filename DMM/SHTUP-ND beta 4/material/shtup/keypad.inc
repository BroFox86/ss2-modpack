# keyboards
terrain_scale 128
render_material_only 1

# lay down the base environment map
render_pass {
	texture material/shtup/env/gloss_cube
	blend ONE ZERO
	uv_source ENVIRONMENT
}

# erase/fade some of it with a generic smudge pattern
render_pass {
	texture material/shtup/env/smudges
	uv_mod scale 0.75 0.75
}

# add keyboard texture on top
render_pass {
	texture material/shtup/fam/keypad
	blend ONE ONE
}
