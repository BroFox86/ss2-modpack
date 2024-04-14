render_material_only
terrain_scale 32 256

# fake caustic pass 1
render_pass {
	texture material/scp/fam/caustic
	blend SRC_ALPHA ZERO
	uv_mod scale 0.12 1
	uv_mod scroll 0.1 -0.15
	alpha 0.06
}

# fake caustic pass 2
render_pass {
	texture material/scp/fam/caustic
	blend SRC_ALPHA ONE
	uv_mod scale 0.11 1
	uv_mod scroll 0.1 0.14
	uv_mod rotate 90
	alpha 0.06
}

# fade out toward bottom
render_pass {
	texture material/scp/fam/pool12m
	blend ZERO SRC_COLOR
}

# wall
render_pass {
	texture $TEXTURE
	blend ONE ONE
	shaded
}