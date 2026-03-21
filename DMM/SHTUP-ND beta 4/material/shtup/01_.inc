render_material_only 1
ani_frames 1

# scrolling text
render_pass {
	texture material/shtup/obj/01_m1
	uv_mod scale 4 1
	uv_mod scroll 0.0 0.2
}

# animated foreground and mask
render_pass {
	ani_rate 67
	texture *_ 0 material/shtup/obj/01_
}

include ../../material/shtup/_screen.inc
