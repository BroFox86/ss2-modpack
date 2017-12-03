render_material_only 1
ani_frames 1

# black background and center fruit reel
render_pass {
	texture material/shtup/obj/slotfrut1
	blend ONE ZERO
	uv_mod scale 1 0.5
	uv_mod scroll 0 -1.0
}

# left fruit reel
render_pass {
	texture material/shtup/obj/slotfrut2
	blend SRC_ALPHA ONE
	uv_mod offset 0 0
	uv_mod scale 1 0.5
	uv_mod scroll 0 -0.6
}

# right fruit reel
render_pass {
	texture material/shtup/obj/slotfrut2
	blend SRC_ALPHA ONE
	uv_mod offset 0.525 0
	uv_mod scale 1 0.5
	uv_mod scroll 0 -1
}

# animated frame and reel mask
render_pass {
	texture * 8 material/shtup/obj/slot_
	ani_rate 150
}

include ../../material/shared/monitor.inc
