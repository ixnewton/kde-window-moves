#!/bin/bash
# Get the current window and desktop data
    active_window_id=$(xdotool getactivewindow)
    window_name=$(xdotool getwindowname $active_window_id)
    display_width=$(xdotool getdisplaygeometry | awk -F "[[:space:]]+" '/ /{print $1}')
    display_height=$(xdotool getdisplaygeometry | awk -F "[[:space:]]+" '/ /{print $2}')
    window_width=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $3}')
    window_height=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $4}')
    window_y_pos=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:],]+" '/Position:/{print $4}')
    window_x_pos=$(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:],]+" '/Position:/{print $3}')
    pointer_x=$(xdotool getmouselocation | awk -F "[[:space:]]" '//{print $1}' | awk -F "[:]" '//{print $2}')
    pointer_y=$(xdotool getmouselocation | awk -F "[[:space:]]" '//{print $2}' | awk -F "[:]" '//{print $2}')

# Set margin and border sizes here:
    top_margin=5            # provodes a comfortable close fit to top of screen
    side_margin=5           # provides a comfortable close fit to sides. 
    bottom_margin=4     # provides a comfortable close fit to bottom of screen. Increase by frame size 0 -10 (px) if frame borders are enabled
    border_y=23               # The size of the window top frame added to window when positioning (QT)  and virtual bottom (GTK)
    border_gtk=20           # The virtual offset size of window top frame for non QT windows ($gtk_fix)

# Detect QT windows which do not need any position fiddles to compensate for windowmove positioning by frame coords for GTK built apps
# With QT windows we add header_height and for GTK both gtk_fix for header and footer_height to compensate for a dummy footer border! 
    
    winQT=$(echo $window_name | grep -c  "— \|Octopi\|Session\|System\|HeidiSQL\|qBittorrent\|Clementine\|digiKam\|Okular\|KeePassXC\|Krusader\|LibreOffice")
    winGTK=$(echo $window_name | grep -c  "Krusader/ -/ ROOT")

    if [ "$winQT" -eq 0 ] || [ "$winGTK" -gt 0 ] ; then
        gtk_fix=$border_gtk
        header_height=0
        footer_height=$border_y
    else
        gtk_fix=0
        header_height=$border_y
        footer_height=0
    fi

# Function windowheight provides window height adjustment from the bottom in steps by pixel amaount 
# parameters: $1 <top margin>, $2 <side margin>, $3 <window header>,  $4 <GTK header fix>, $4 <step in pixels>, $5 <direction 1=increase> 
function windowheight () {

    window_fit_height=$(($display_height - $window_y_pos - $2))
    window_min_height=$(($window_fit_height * 9 / 32))
    window_delta=$(($window_fit_height / $3))
    
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
            if [ $(($pointer_y + $window_delta)) -ge $(($window_new_height + $window_y_pos)) ]; then
                xdotool mousemove $pointer_x $(($window_new_height + $window_y_pos - $window_delta))
            fi
    fi

}

# Function windowtop provides a top margin expand/contract function in steps by pixel amaount
# parameters: $1 <top margin>, $2 <side margin>, $3 <window header>,  $4 <GTK header fix>, $4 <step in pixels>, $5 <direction 1=increase> 
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
            elif [ $window_y_pos -lt $(($5 * 5 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 5 + $top_offset))
            elif [ $window_y_pos -lt $(($5 * 6 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 6 + $top_offset))
            elif [ $window_y_pos -lt $(($5 * 7 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 7 + $top_offset))
            else
                window_y_new_pos=$(($5 * 7 + $top_offset))
            fi
            window_base_pos=$(( $window_height + $window_y_pos))
            window_fit_height=$(($display_height - $window_y_new_pos - $2 - $footer_height))
            if [ $window_height -gt $window_fit_height ] || [ $window_base_pos -gt $window_fit_pos ] ; then
                window_height=$window_fit_height
            fi
            xdotool windowsize --sync $active_window_id $window_width $window_height
            xdotool windowmove --sync $active_window_id 'x' $window_y_new_pos
            xdotool mousemove $pointer_x $(($pointer_y + $window_y_new_pos - $window_y_pos))
            
        else
            if [ $window_y_pos -ge $(($5 * 7 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 6 + $top_offset))
            elif [ $window_y_pos -ge $(($5 * 6 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 5 + $top_offset))
            elif [ $window_y_pos -ge $(($5 * 5 + $top_margin)) ]; then
                window_y_new_pos=$(($5 * 4 + $top_offset))
            elif [ $window_y_pos -ge $(($5 * 4 + $top_margin)) ]; then
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
             xdotool windowmove --sync $active_window_id 'x' $window_y_new_pos
             xdotool mousemove $pointer_x $(($pointer_y + $window_y_new_pos - $window_y_pos))
        fi
    fi
}

# Function windowwidth provides a width expand/contract function in steps proportional to screen width
# parameters: $1 <window_y_pos>, $2 <side margin>, $3 <width step delta>, $4 <direction 1=increase> 
function windowwidth () {

    window_fit_width=$(($display_width - (2 * $2)))
    window_delta=$(($window_fit_width / $3))
    window_y_pos=$(($1 - $footer_height))

    if [ "$window_name" != "Desktop — Plasma" ]; then
            if [ $4 == 1 ]; then
                    window_new_width=$(($window_width + $window_delta))
                    window_x_new_pos=$(($window_x_pos - $(($window_delta / 2))))
                    if [ $window_new_width -ge $window_fit_width ]; then
                        window_new_width=$window_fit_width
                    fi
                    if [ $window_x_pos -lt $(($window_delta / 2)) ]; then
                        window_x_new_pos=$2
                    fi
                    if [ $(($window_new_width + $window_x_pos)) -gt $window_fit_width ]; then
                        window_x_new_pos=$(($display_width - $window_new_width - $2))  
                    fi
                    xdotool windowmove --sync $active_window_id $window_x_new_pos $window_y_new_pos
                    xdotool windowsize --sync $active_window_id $window_new_width $window_height
            else
                    window_new_width=$(($window_width - $window_delta))
                    if [ $(($display_width - $window_width - $window_x_pos)) -le $(($window_delta / 2)) ]; then
                        window_x_new_pos=$(($display_width - $window_new_width - $2))
                    else
                        window_x_new_pos=$(($window_x_pos + ($window_delta / 2)))
                    fi
                    if [ $window_x_pos -lt $(($window_delta))  ]; then
                        window_x_new_pos=$2
                    fi

                    xdotool windowsize --sync $active_window_id $window_new_width $window_height
                    if [ $(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $3}') -ne  $window_width ]; then
                        xdotool windowmove --sync $active_window_id $window_x_pos $window_y_pos
                    fi
                    if [ $pointer_x -ge $(($window_x_new_pos + $window_new_width - $window_delta))  ]; then
                        xdotool mousemove $(($window_x_new_pos + $window_new_width - $window_delta)) $pointer_y
                    fi
                    if [ $pointer_x -le $(($window_x_new_pos + $window_delta))  ]; then
                        xdotool mousemove $(($window_x_new_pos + $window_delta))  $pointer_y
                    fi
            fi        
    fi

}

# Function windowzoom provides a zoom function centered and proportional to the screen size
# parameters: $1 <top margin>, $2 <side margin>, $3 <GTK header fix>,  $4 <horizontal step delta>, $5 <vertical step delta>, $6 <direction 1=increase> 
function windowzoom () {

    window_x_pos=$2
    window_y_pos=$(($1 + $header_height))
    window_fit_height=$(($display_height - $1 - $2 - $3 - $header_height))
    window_fit_width=$(($display_width - $2 - $2))
    zoom_y_delta=$5
    zoom_x_delta=$4

    if [ "$window_name" != "Desktop — Plasma" ]; then
        if  [ $6 -eq 1 ]; then
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
            window_x_new_pos=$(($(($display_width - $window_fit_width)) / 2))
            window_y_new_pos=$(($(($(($display_height - $window_fit_height + $header_height - $footer_height)) / 2))))
            xdotool windowmove --sync $active_window_id $window_x_new_pos $window_y_new_pos
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
            window_x_new_pos=$(($(($display_width - $window_fit_width)) / 2))
            window_y_new_pos=$(($(($(($display_height - $window_fit_height + $header_height - $footer_height)) / 2))))
            xdotool windowsize --sync $active_window_id $window_fit_width $window_fit_height
            xdotool windowmove $active_window_id $window_x_new_pos $window_y_new_pos
            if [ $pointer_x -ge $(($window_x_new_pos + $window_fit_width - $(($zoom_x_delta / 4)))) ]; then
                pointer_x=$(($window_x_new_pos + $window_fit_width - $(($zoom_x_delta / 4))))
            elif [ $pointer_x -le $(($window_x_new_pos + $(($zoom_x_delta / 4)))) ]; then
                pointer_x=$(($window_x_new_pos + $(($zoom_x_delta / 4))))
            elif [ $pointer_y -ge $(($window_y_new_pos + $window_fit_height - $zoom_y_delta))  ]; then
                pointer_y=$(($window_y_new_pos + $window_fit_height - $(($zoom_y_delta / 2))))
            elif [ $pointer_y -le $(($window_y_new_pos + $zoom_y_delta)) ]; then
                pointer_y=$(($window_y_new_pos + $(($zoom_y_delta / 2))))
            fi
            xdotool mousemove $pointer_x $pointer_y
        fi
    fi
 }

# Function windowmove moves the window left/right/centre with step adjustments for left/right by step pixel steps
# parameters: $1 <top margin>, $2 <side margin>, $3 <bottom margin>,  $4 <GTK footer fix>,  $5 <horizontal step 1>,   $6 <step 2>,   $6 <step 3>, 
# $6 <direction 0:left 1:right 2:center> 
 function windowmove () {
 
    window_y_new_pos=$(($window_y_pos - $4))
    window_fit_height=$(($display_height - $1 - $3))

    if [ "$window_name" != "Desktop — Plasma" ];
        then
        if [ $window_height -gt $window_fit_height ]; then
            window_new_height=$window_fit_height
            xdotool windowsize --sync $active_window_id $window_width $window_new_height
        fi
        if [ $8 -eq 0 ]; then
            if [ $window_x_pos -eq $2 ]; then
                window_x_new_pos=$5
            elif [ $window_x_pos -eq $5 ]; then
                window_x_new_pos=$6
            elif [ $window_x_pos -eq $6 ]; then
                window_x_new_pos=$7
            else
                window_x_new_pos=$2
            fi 
        elif [ $8 -eq 1 ]; then
            if [ $window_x_pos -eq $(($display_width - $window_width - $2)) ]; then
                window_x_new_pos=$(($display_width - $window_width - $5))
            elif [ $window_x_pos -eq $(($display_width - $window_width - $5)) ]; then
                window_x_new_pos=$(($display_width - $window_width - $6))
            elif [ $window_x_pos -eq $(($display_width - $window_width - $6)) ]; then
                window_x_new_pos=$(($display_width - $window_width - $7))
            else
                window_x_new_pos=$(($display_width - $window_width - $2))
            fi
        elif [ $8 -eq 2 ]; then
            window_x_new_pos=$((($display_width - $window_width) /2 ))
        fi
        if [ $4 -eq 0 ]; then
            xdotool windowmove --sync $active_window_id $window_x_new_pos 'y'
            xdotool mousemove $(($pointer_x + $window_x_new_pos - $window_x_pos)) $pointer_y
        else
            xdotool windowmove --sync $active_window_id $window_x_new_pos $window_y_new_pos
            xdotool mousemove $(($pointer_x + $window_x_new_pos - $window_x_pos)) $(($pointer_y + $window_y_new_pos - $window_y_pos))
        fi
    fi

 }

# Function minimize minimizes all other windows other than the active window to clear screen clutter 
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
 
 # Selector for functions with parameter sets. These can be adjusted to suit personal perferences.
 case $1 in
    moveL )
        windowmove $top_margin $side_margin $bottom_margin $footer_height 24 48 72 0
    ;;
    moveR )
        windowmove $top_margin $side_margin $bottom_margin $footer_height 24 48 72 1
    ;;
    moveC )
        windowmove $top_margin $side_margin $bottom_margin $footer_height 24 48 72 2
    ;;
    zoomP )
        windowzoom $top_margin $side_margin $gtk_fix 120 42 1
    ;;
    zoomM )
        windowzoom $top_margin $side_margin $gtk_fix 120 42 0
    ;;
    widthM )
        windowwidth $window_y_pos $side_margin 42 0
    ;;  
    widthP )
        windowwidth $window_y_pos $side_margin 42 1
    ;;  
    heightM )
        windowheight $top_margin $bottom_margin 32 $gtk_fix 1
    ;;  
    heightP )
        windowheight $top_margin $bottom_margin 32 $gtk_fix 0
    ;; 
    topP )
        windowtop $top_margin $bottom_margin $header_height $gtk_fix 20 1
    ;; 
    topM )
        windowtop $top_margin $bottom_margin $header_height $gtk_fix 20 0
    ;; 
    minimize )
        minimize
    ;;    
    *)
    echo "Command not recognized! - Usage window-move.sh <command> <int. offset> . Commands moveL, moveR, moveC, zoomM, zoomP, widthM, widthP, heightM, heightP or winTop with integer offfset!"
    ;;
esac
