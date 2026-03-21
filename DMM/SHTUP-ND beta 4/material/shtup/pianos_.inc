# piano screen note display
render_material_only 1
ani_rate 150

# scrolling notes
render_pass {
	texture material/shtup/obj/pianotes
	uv_mod SCROLL 0.18 0
	uv_mod SCALE 0.5 2
	uv_mod OFFSET 0 0.5
}

# bar overlay
render_pass {
	texture $TEXTURE
}
