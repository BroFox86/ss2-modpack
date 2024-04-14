// 400SCP patch
// reflection for engc_ object texture (inactive fuel flow cover object)

render_material_only
ani_frames 1

render_pass {
	texture FAM/_ACC/engc_
	blend ONE ZERO
}

env_map 0.05 1 FAM/_ACC/gloss_cube
