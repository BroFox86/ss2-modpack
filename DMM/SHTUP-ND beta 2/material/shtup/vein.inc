ani_frames 1

# blood coursing through vein
render_pass {
	texture $TEXTURE
	uv_mod ROTATE 180
	uv_mod SCALE 0.3 0.3
	uv_mod SCROLL 0.5 0.05
	alpha 0.4
	shaded
}
