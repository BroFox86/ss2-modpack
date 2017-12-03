render_material_only 1
ani_frames 1
terrain_scale 32

# ring 1
render_pass {
	texture material/shtup/fam/p0008_m1
	rgb func wave SINE 0.25 0.75 0.5 1200
}

# ring 2
render_pass {
	texture material/shtup/fam/p0008_m2
	blend ONE ONE
	rgb func wave SINE 0.25 0.75 0.375 1200
}

# ring 3
render_pass {
	texture material/shtup/fam/p0008_m3
	blend ONE ONE
	rgb func wave SINE 0.25 0.75 0.125 1200
}

# ring 4
render_pass {
	texture material/shtup/fam/p0008_m4
	blend ONE ONE
	rgb func wave SINE 0.25 0.75 0.0 1200
}

include ../../material/shared/monitor.inc
