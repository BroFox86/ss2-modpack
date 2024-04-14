// 400SCP patch
// replaced reflection texture with cubemap
// made goo flow instead of just floating around

// Part of the following texture sets:
//	Eng_3	Goo

render_material_only
terrain_scale 128 64
ani_frames 1

render_pass {
	uv_mod SCROLL -1.5 0.15
	texture FAM/_ACC/goo
	blend ONE ZERO
}

render_pass {
	uv_mod ROTATE 180
	uv_mod SCROLL 2.0 0.14
	alpha 0.5
	texture FAM/_ACC/goo
}

render_pass {
	uv_mod OFFSET 0.5 0.5
	uv_mod SCROLL -2.75 0.13
	alpha 0.4
	texture FAM/_ACC/goo
}

env_map 0.3 1 FAM/_ACC/gloss_cube
