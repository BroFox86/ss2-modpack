render_material_only 1
ani_frames 1

# cyberjack base
render_pass {
	texture material/shtup/fam/citjack1
	shaded 1
}

# purple lights
render_pass {
	blend SRC_ALPHA ONE
	texture material/shtup/fam/citjackg
	alpha func WAVE INV_SAWTOOTH 0 1 0 1750 2
}
