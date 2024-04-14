render_material_only
terrain_scale 64
ani_frames 1

# background
render_pass {
	texture material/shtup/fam/p0050_m1
}

# scrolling graph
render_pass {
	texture material/shtup/fam/p0050_m2
	blend SRC_ALPHA ONE
	uv_mod scroll -1 0
}

# bouncing box
render_pass {
	texture material/shtup/fam/p0050_m3
	uv_mod voffset_wave sine 0.82 0.20 0.4 1000
}

include ../../material/shtup/_screen.inc
