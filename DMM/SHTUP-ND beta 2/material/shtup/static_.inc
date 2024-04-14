render_material_only 1
ani_frames 1

render_pass {
	shaded 0
	ani_rate 50
	texture *_ 0 material/shtup/obj/stat_
	uv_mod scroll 0 0.05
	uv_mod scale 0.25 0.25
}

render_pass {
	shaded 0
	ani_rate 50
	texture *_ 0 material/shtup/obj/stat_
	uv_mod scroll 0 -0.05
	uv_mod scale 0.25 0.25
	alpha 0.5
}

include ../../material/shtup/_screen.inc