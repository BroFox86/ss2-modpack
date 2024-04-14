render_material_only 1
ani_frames 1
terrain_scale 64

# scrolling text
render_pass {
	texture material/shtup/fam/p0034_m1
	uv_mod scroll 0.0 0.3
}

# animated foreground and mask
render_pass {
	ani_rate 100
	texture *_ 0 material/shtup/fam/p0034
}

include ../../material/shtup/_screen.inc
