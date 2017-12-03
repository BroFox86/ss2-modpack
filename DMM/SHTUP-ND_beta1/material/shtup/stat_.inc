render_material_only 1
ani_frames 1

render_pass {
	ani_rate 50
	texture *_ 0 material/shtup/obj/stat_
	uv_mod scroll 0 0.05
}

render_pass {
	ani_rate 50
	texture *_ 0 material/shtup/obj/stat_
	uv_mod scroll 0 -0.05
	alpha 0.5
}

include ../../material/shared/monitor.inc
