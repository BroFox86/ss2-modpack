render_material_only 1

# glowing veins
render_pass {
	texture material/shtup/obj/ggglow
	blend ONE ZERO
	uv_mod scroll 0 0.08
	uv_mod spin 5
}

# glowing veins again
render_pass {
	texture material/shtup/obj/ggglow
	alpha 0.5
	uv_mod scroll 0 -0.1
	uv_mod spin 4
}

# egg shell
render_pass {
	shaded 1
	texture material/shtup/obj/gg
}
