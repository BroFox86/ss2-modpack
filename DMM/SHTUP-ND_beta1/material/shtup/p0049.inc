render_material_only 1
ani_frames 1
terrain_scale 64

# background
render_pass {
	ani_rate 200
	texture *_ 0 material/shtup/fam/p0049
}

# scrolling fuel flow indicator
render_pass {
	texture material/shtup/fam/p0049_m1
	uv_mod scroll 0 1.25
}

include ../../material/shared/monitor.inc
