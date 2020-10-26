#!/bin/bash

active_window_id=$(xdotool getactivewindow)

window_name=$(xdotool getwindowname $active_window_id)
display_height=$(xdotool getdisplaygeometry | awk -F "[[:space:]]+" '/ /{print $2}')
window_width=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $3}')
window_height=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $4}')
window_fit_height=$(($display_height - $2 - $3))


if [ "$window_name" != "Desktop — Plasma" ]; then
    if [ $window_height -gt $window_fit_height ]; then
        window_new_height=$window_fit_height
        xdotool windowsize $active_window_id $window_width $window_new_height
    fi
    xdotool windowmove $active_window_id $1 $2
fi