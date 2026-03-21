# Xerxes screen
ani_frames 1
render_material_only 1

# lookin' around
render_pass {
	texture $texture
	uv_mod uoffset_wave sine -0.012 0.025 0 10000
	uv_mod voffset_wave sine -0.012 0.025 0 12000
	shaded 1
}

# scanlines
render_pass {
	texture material/shtup/obj/xerxline
	uv_mod scale 1 32
	uv_mod scroll 0 -4
	shaded 1
}
