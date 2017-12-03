render_material_only 1
ani_frames 1
terrain_scale 64

# scrolling text
render_pass {
	texture material/shtup/fam/p0025_m1
	uv_mod scroll 0.0 -0.4 0 16
}

# animated foreground and mask
render_pass {
	ani_rate 200
	texture { material/shtup/fam/p0025 material/shtup/fam/p0025_1 material/shtup/fam/p0025_1 material/shtup/fam/p0025_1 }
}

include ../../material/shared/monitor.inc
