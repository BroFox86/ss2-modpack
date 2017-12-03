render_material_only 1
ani_frames 1
terrain_scale 64

# scrolling text
render_pass {
	texture material/shtup/fam/p0026_m1
	uv_mod scale 2 1
	uv_mod uoffset_wave SQUARE 0.5 0 0 9999
	uv_mod voffset_wave SAWTOOTH 0 1 0 4000
}

# animated foreground and mask
render_pass {
	ani_rate 100
	texture *_ 0 material/shtup/fam/p0026
}

include ../../material/shared/monitor.inc
