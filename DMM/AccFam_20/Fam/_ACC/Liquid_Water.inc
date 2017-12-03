// Part of the following texture sets:
//	WaterHw	BLIN
//	WaterHw	BLOUT
//	WaterHw	GRIN
//	WaterHw	GROUT
//	WaterHwBkp	BLIN
//	WaterHwBkp	BLOUT
force_opaque
ani_frames 1
render_pass
{
	alpha .3
	uv_mod SCROLL .1 .1 0 0
	texture $TEXTURE
	blend SRC_COLOR DST_ALPHA
	shaded 1
}
render_pass
{
	alpha .2
	uv_mod ROTATE 90
	uv_mod SCROLL -.1 -.1 0 0
	texture $TEXTURE
	blend SRC_ALPHA ONE
	shaded 1
}