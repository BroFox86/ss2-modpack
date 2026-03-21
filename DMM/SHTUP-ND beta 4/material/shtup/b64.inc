render_material_only 1
ani_frames 1
terrain_scale 128

# static layer
render_pass {
	ani_rate 50
	texture *_ 0 material/shtup/fam/b64
	uv_mod scroll 0 0.05
}

# static layer again
render_pass {
	ani_rate 50
	texture *_ 0 material/shtup/fam/b64
	uv_mod scroll 0 -0.05
	alpha 0.5
}

include ../../material/shtup/_frosted.inc
