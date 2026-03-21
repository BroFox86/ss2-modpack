# mission posting screens
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
}

# fullbright sign
render_pass {
	texture $TEXTURE
	blend ONE ONE
	uv_clamp 1
}

# overlay frame
render_pass {
	texture material/shtup/obj/misspost_frame
	shaded 1
	uv_clamp 1
}

# glow pass
render_pass {
	texture material/shtup/obj/misspost_glow
	shaded 0
}
