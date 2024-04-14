// 400SCP patch
// fixed glow not rendering on ops1 object walls

// Part of the following texture sets:
//	OpsNew	Base3
//	Note: is also used as obj/txt16/OPS010

render_material_only
terrain_scale 128

render_pass {
	texture FAM/_ACC/BASE3
	shaded
}

render_pass {
	texture FAM/_ACC/GFX_LumaOPS
	alpha 0.9
	blend SRC_ALPHA ONE
}