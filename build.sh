#!/bin/sh

function make_texture(){
	NAME=$1 ; shift
	if [[ $1 =~ ^[0-9]+$ ]]; then FRAMES=$1; shift; else FRAMES=''; fi

	[ ! -z "$FRAMES" ] && I=".${NAME}-0.xpm" || I=".${NAME}.xpm"
	O="textures/cobble_generator_${NAME}.png"
	echo "[build] $O"
	convert $I -define png:exclude-chunks=date -strip $* $O

	if [ ! -z "$FRAMES" ]; then
		I=".${NAME}-?.xpm"
		O="textures/cobble_generator_${NAME}_animated.png"
		echo "[build] $O"
		montage $I -define png:exclude-chunks=date -strip -mode concatenate -tile 1x$FRAMES $* $O
	fi
}

make_texture S1 -blur 1x0.5
make_texture S2 -blur 1x0.5
make_texture S3 -blur 1x0.5
make_texture S4 -blur 1x0.5
make_texture S5 -blur 1x0.5
make_texture S6 -blur 1x0.5
make_texture UD -blur 1x0.5
