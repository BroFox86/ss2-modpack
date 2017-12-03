render_material_only 1
ani_frames 1
terrain_scale 32

# scrolling text
render_pass {
	texture material/shtup/fam/p0039_m1
	uv_mod scale 1.0 0.5
	uv_mod scroll 0.0 0.25
}

# animated foreground
render_pass {
	ani_rate 100
	texture *_ 0 material/shtup/fam/p0039
}

include ../../material/shared/monitor.inc
