#!/bin/bash

active_window_id=$(xdotool getactivewindow)
window_name=$(xdotool getwindowname $active_window_id)
display_height=$(xdotool getdisplaygeometry | awk -F "[[:space:]]+" '/ /{print $2}')
window_width=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $3}')
window_height=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $4}')
window_y_pos=$2

window_fit_height=$(($display_height - $window_y_pos - $1))
window_min_height=$(($window_fit_height * 9 / 32))
window_delta=$(($window_fit_height / $3))
 
if [ "$window_name" != "Desktop — Plasma" ]; then
        if [ $4 == 1 ]; then
                window_new_height=$(($window_height + $window_delta))
                if [ $window_new_height -gt $window_fit_height ]; then
                    window_new_height=$window_fit_height
                fi
        else
                window_new_height=$(($window_height - $window_delta))
                if [ $window_new_height -lt $window_min_height ]; then
                    window_new_height=$window_min_height
                fi
        fi
        xdotool windowsize $active_window_id $window_width $window_new_height
        xdotool windowmove $active_window_id 'x' $window_y_pos
fi
