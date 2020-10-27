#!/bin/bash

active_window_id=$(xdotool getactivewindow)
window_name=$(xdotool getwindowname $active_window_id)
display_width=$(xdotool getdisplaygeometry | awk -F "[[:space:]]+" '/ /{print $1}')
window_width=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $3}')
window_height=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $4}')
window_x_pos=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:],]+" '/Position:/{print $3}')
window_fit_width=$(($display_width - (2 * $2)))
window_delta=$(($window_fit_width / $3))
window_y_pos=$1
 
if [ "$window_name" != "Desktop — Plasma" ]; then
        if [ $4 == 1 ]; then
                window_new_width=$(($window_width + $window_delta))
                window_x_pos=$(($window_x_pos - ($window_delta / 2)))
                if [ $window_new_width -ge $window_fit_width ]; then
                    window_new_width=$window_fit_width
                fi
                if [ $window_x_pos -lt $(($window_delta / 2)) ]; then
                    window_x_pos=$2
                fi
                if [ $(($window_new_width + $window_x_pos)) -gt $window_fit_width ]; then
                    window_x_pos=$(($display_width - $window_new_width - $2))  
                fi
                xdotool windowmove --sync $active_window_id $window_x_pos $window_y_pos
                xdotool windowsize --sync $active_window_id $window_new_width $window_height
        else
                window_new_width=$(($window_width - $window_delta))
               if [ $(($display_width - $window_width - $window_x_pos)) -le $(($window_delta / 2)) ]; then
                    window_x_pos=$(($display_width - $window_new_width -$2))
                else
                    window_x_pos=$(($window_x_pos + ($window_delta / 2)))
                fi
                if [ $window_x_pos -lt $(($window_delta))  ]; then
                    window_x_pos=$2
                fi
                xdotool windowsize --sync $active_window_id $window_new_width $window_height
                if [ $(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $3}') -ne  $window_width ]; then
                   xdotool windowmove --sync $active_window_id $window_x_pos $window_y_pos
                fi
        fi        
fi
