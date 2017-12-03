# shared post-processing effect for monitor object and terrain surfaces
# be sure to include both DX6 and DX9 render options

##render_pass {
##	texture * 3 material/shared/monrgb1
##	ani_rate 33.3333
##	blend DST_COLOR SRC_COLOR
##	uv_mod scale 128 128
##}