# The material texture won't smoothly fade unless its alpha channel
# has multiple transparency levels. NewDark will force any texture with
# one-bit transparency to be an alpha keyed texture. force_full_alpha
# apparently only controls the base texture.

force_full_alpha 1
ani_frames 1
uv_clamp 1

# fade to second frame of anim instead of just switching to it
render_pass {
	texture material/shtup/obj/cluste_1
	alpha func wave sine 0 1 0 1000
	uv_clamp 1
	shaded 1
}
