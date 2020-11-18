#!/bin/bash

    active_window_id=$(xdotool getactivewindow)
    window_name=$(xdotool getwindowname $active_window_id)
    display_width=$(xdotool getdisplaygeometry | awk -F "[[:space:]]+" '/ /{print $1}')
    display_height=$(xdotool getdisplaygeometry | awk -F "[[:space:]]+" '/ /{print $2}')
    window_width=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $3}')
    window_height=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $4}')
    window_y_pos=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:],]+" '/Position:/{print $4}')
    window_x_pos=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:],]+" '/Position:/{print $3}')
    winQT=$(echo $window_name | grep -c  "— \|Octopi\|Session\|System\|HeidiSQL\|qBittorrent\|Clementine")

    if [ "$winQT" -eq 0 ]; then
        gtk_fix=20
        header_height=0
        footer_height=23
    else
        gtk_fix=0
        header_height=23
        footer_height=0
    fi
   
function windowheight () {

    window_fit_height=$(($display_height - $window_y_pos - $2))
    window_min_height=$(($window_fit_height * 9 / 32))
    window_delta=$(($window_fit_height / $3))
    window_zone=$(($window_fit_height - $window_delta))
    
    if [ "$window_name" != "Desktop — Plasma" ]; then
            if [ $5 == 1 ]; then
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
            xdotool windowsize --sync $active_window_id $window_width $window_new_height
            xdotool windowmove --sync $active_window_id 'x' $window_y_pos
    fi

}

function windowtop () {

    window_fit_pos=$(( $display_height - $2 - $2 ))
    top_margin=$(($1 + $3 + $4)) 
    top_offset=$(($top_margin - $4))

    if [ "$window_name" != "Desktop — Plasma" ]; then
        if  [ $6 -eq 1 ]; then
            if [ $window_y_pos -lt $(($5 + $top_margin)) ]; then
                window_y_new_pos=$(( $top_offset + $5))
            elif [ $window_y_pos -lt $(($5 * 2 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 2 + $top_offset))     
            elif [ $window_y_pos -lt $(($5 * 3 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 3 + $top_offset))    
            elif [ $window_y_pos -lt $(($5 * 4 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 4 + $top_offset))
            else
                window_y_new_pos=$(($5 * 4 + $top_offset))
            fi
            window_base_pos=$(( $window_height + $window_y_pos))
            window_fit_height=$(($display_height - $window_y_new_pos - $2 - $footer_height))
            if [ $window_height -gt $window_fit_height ] || [ $window_base_pos -gt $window_fit_pos ] ; then
                window_height=$window_fit_height
            fi
            xdotool windowsize --sync $active_window_id $window_width $window_height
            xdotool windowmove $active_window_id 'x' $window_y_new_pos
            
        else
            if [ $window_y_pos -ge $(($5 * 4 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 3 + $top_offset))   
            elif [ $window_y_pos -ge $(($5 * 3 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 2 + $top_offset)) 
            elif [ $window_y_pos -ge $(($5 * 2 + $top_margin)) ]; then
                window_y_new_pos=$(($5 + $top_offset))
            elif [ $window_y_pos -ge $(($5 + $top_margin)) ]; then
                window_y_new_pos=$(($top_offset))
            else
                window_y_new_pos=$(($top_offset))
            fi
            window_base_pos=$(( $window_height + $window_y_pos))
            window_fit_height=$(($display_height - $window_y_new_pos - $2 - $footer_height))
            if [ $window_height -gt $window_fit_height ] || [ $window_base_pos -gt $window_fit_pos ] ; then
                window_height=$(($window_fit_height))
            fi
             xdotool windowsize --sync $active_window_id $window_width $window_height
             xdotool windowmove $active_window_id 'x' $window_y_new_pos

        fi
    fi
}

function windowwidth () {

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
                        window_x_pos=$(($display_width - $window_new_width - $2))
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

}

function windowcenter () {

    window_x_pos=$((($display_width - $window_width) /2 ))
    window_fit_height=$(($display_height - $1 - $2))

    if [ "$window_name" != "Desktop — Plasma" ];
        then
        if [ $window_height -gt $window_fit_height ]; then
            window_new_height=$window_fit_height
            xdotool windowsize --sync $active_window_id $window_width $window_new_height
        fi
        xdotool windowmove --sync $active_window_id $window_x_pos $window_y_pos
    fi

 }

function windowzoom () {

    window_x_pos=$2
    window_y_pos=$(($1 + $header_height))
    window_fit_height=$(($display_height - $1 - $2 - $3 - $header_height))
    window_fit_width=$(($display_width - $2 - $2))
    zoom_y_delta="41"
    zoom_x_delta=$(($display_width / $4))

    if [ "$window_name" != "Desktop — Plasma" ]; then
        if  [ $5 -eq 1 ]; then
            if [ $window_width -le  $(($window_fit_width - $(($zoom_x_delta * 5)))) ]; then            
                window_fit_width=$(($window_fit_width - $(($zoom_x_delta * 4))))
                window_fit_height=$(($window_fit_height - $(($zoom_y_delta * 4))))
        elif [ $window_width -le  $(($window_fit_width - $(($zoom_x_delta * 4)))) ]; then            
                window_fit_width=$(($window_fit_width - $(($zoom_x_delta * 3))))
                window_fit_height=$(($window_fit_height - $(($zoom_y_delta * 3))))
            elif [ $window_width -le  $(($window_fit_width - $(($zoom_x_delta * 3)))) ]; then            
                window_fit_width=$(($window_fit_width - $(($zoom_x_delta * 2))))
                window_fit_height=$(($window_fit_height - $(($zoom_y_delta * 2))))
        elif [ $window_width -le  $(($window_fit_width - $(($zoom_x_delta * 2)))) ]; then            
                window_fit_width=$(($window_fit_width - $(($zoom_x_delta))))
                window_fit_height=$(($window_fit_height - $(($zoom_y_delta))))
            elif [ $window_width -le  $(($window_fit_width - $zoom_x_delta)) ]; then            
                window_fit_width=$(($window_fit_width))
                window_fit_height=$(($window_fit_height))
            else
                window_fit_width=$(($window_fit_width))
                window_fit_height=$(($window_fit_height))
            fi
            
            window_x_pos=$((($display_width / 2) - ($window_fit_width / 2)))
            window_y_pos=$(($(($(($display_height - $window_fit_height + $header_height + $3)) / 2))))

            xdotool windowmove --sync $active_window_id $window_x_pos $window_y_pos 
            xdotool windowsize --sync $active_window_id $window_fit_width $window_fit_height   
            
        else
            if [ $window_width -ge  $(($window_fit_width))  ]; then
                 window_fit_width=$(($window_fit_width - $zoom_x_delta))
                window_fit_height=$(($window_fit_height - $zoom_y_delta))
            elif [ $window_width -ge  $(($window_fit_width - $zoom_x_delta)) ]; then
                 window_fit_width=$(($window_fit_width - $(($zoom_x_delta * 2))))
                window_fit_height=$(($window_fit_height - $(($zoom_y_delta * 2))))
            elif [ $window_width -ge  $(($window_fit_width - $(($zoom_x_delta * 2)))) ]; then 
                window_fit_width=$(($window_fit_width - $(($zoom_x_delta * 3))))
                window_fit_height=$(($window_fit_height - $(($zoom_y_delta * 3))))
            elif [ $window_width -ge  $(($window_fit_width - $(($zoom_x_delta * 3)))) ]; then
                window_fit_width=$(($window_fit_width - $(($zoom_x_delta * 4))))
                window_fit_height=$(($window_fit_height - $(($zoom_y_delta * 4))))
            elif [ $window_width -ge  $(($window_fit_width - $(($zoom_x_delta * 4)))) ]; then
                window_fit_width=$(($window_fit_width - $(($zoom_x_delta * 5))))
                window_fit_height=$(($window_fit_height - $(($zoom_y_delta * 5))))
            else
                window_fit_width=$(($window_fit_width - $(($zoom_x_delta * 5))))
                window_fit_height=$(($window_fit_height - $(($zoom_y_delta * 5))))
            fi
            window_x_pos=$(($(($display_width - $window_fit_width)) / 2))
            window_y_pos=$(($(($(($display_height - $window_fit_height + $header_height + $3)) / 2))))
            xdotool windowsize --sync $active_window_id $window_fit_width $window_fit_height
            xdotool windowmove --sync $active_window_id $window_x_pos $window_y_pos

        fi
    fi
 }
 
 function windowmove_l () {

    window_x_pos=$2
    window_fit_height=$(($display_height - $1 - $3))

    if [ "$window_name" != "Desktop — Plasma" ]; then
        if [ $window_height -gt $window_fit_height ]; then
            window_new_height=$window_fit_height
            xdotool windowsize --sync $active_window_id $window_width $window_new_height
        fi
        xdotool windowmove --sync $active_window_id $window_x_pos $window_y_pos
    fi
 
 }
 
 function windowmove_r () {
 
    window_x_pos=$(($display_width - $window_width - $2))
    window_fit_height=$(($display_height - $1 - $3))

    if [ "$window_name" != "Desktop — Plasma" ];
        then
        if [ $window_height -gt $window_fit_height ]; then
            window_new_height=$window_fit_height
            xdotool windowsize --sync $active_window_id $window_width $window_new_height
        fi
        xdotool windowmove --sync $active_window_id $window_x_pos $window_y_pos
    fi

 }
 
 function minimize () {
 
    active_window_id=$(xdotool getactivewindow)
    for window_id in $(xdotool search --onlyvisible ".*")
    do
        if [ $window_id != $active_window_id ]
        then
            xdotool windowminimize $window_id
        fi
    done
 
 }
 
 case $1 in
    moveL )
        windowmove_l 5 5 5
    ;;
    moveR )
        windowmove_r 5 5 5
    ;;
    moveC )
        windowcenter 5 5
    ;;
    zoomP )
        windowzoom 5 5 $gtk_fix 16 1
    ;;
    zoomM )
        windowzoom 5 5 $gtk_fix 16 0
    ;;
    widthM )
        windowwidth $window_y_pos 5 32 0
    ;;  
    widthP )
        windowwidth $window_y_pos 5 32 1
    ;;  
    heightM )
        windowheight 5 5 24 $gtk_fix 1
    ;;  
    heightP )
        windowheight 5 5 24 $gtk_fix 0
    ;; 
    topP )
        windowtop 5 5 $header_height $gtk_fix 40 1
    ;; 
    topM )
        windowtop 5 5 $header_height $gtk_fix 40 0
    ;; 
    minimize )
        minimize
    ;;    
    *)
    echo "Command not recognized! - Usage window-move.sh <command> <int. offset> . Commands moveL, moveR, moveC, zoomM, zoomP, widthM, widthP, heightM, heightP or winTop with integer offfset!"
    ;;
esac
