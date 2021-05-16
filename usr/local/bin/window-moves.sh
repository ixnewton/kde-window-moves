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

# Current set of margin and border sizes with gtk3-nocsd installed:
    top_margin=4            # provodes a comfortable close fit to top of screen
    side_margin=4           # provides a comfortable close fit to sides. 
    bottom_margin=4     # provides a comfortable close fit to bottom of screen. Increase by frame size 0 -10 (px) if frame borders are enabled
    border_y=29               # The size of the window top frame added to window when positioning (QT)  and virtual bottom (GTK)
    border_gtk=29           # The virtual offset size of window top frame for non QT windows ($gtk_fix)
    margin_delta=21       # Step delta for left/right and top margin
    width_steps=42         # Step divider to width of screen width
    height_steps=32        # Step divider to height of screen height
    width_delta=120        # X delta zoom step
    height_delta=42         # Y delta zoom step

# Alternative set of margin and border sizes without gtk3-nocsd installed
#     top_margin=4            # provodes a comfortable close fit to top of screen
#     side_margin=4           # provides a comfortable close fit to sides. 
#     bottom_margin=4     # provides a comfortable close fit to bottom of screen. Increase by frame size 0 -10 (px) if frame borders are enabled
#     border_y=23               # The size of the window top frame added to window when positioning (QT)  and virtual bottom (GTK)
#     border_gtk=20           # The virtual offset size of window top frame for non QT windows ($gtk_fix)
#     margin_delta=21       # Step delta for left/right and top margin
#     width_steps=42         # Step divider to width of screen width
#     height_steps=32        # Step divider to height of screen height
#     width_delta=120        # X delta zoom step
#     height_delta=42         # Y delta zoom step    
    
# Detect QT windows which do not need any position fiddles to compensate for windowmove positioning by frame coords for GTK built apps
# With QT windows we add header_height and for GTK both gtk_fix for header and footer_height to compensate for a dummy footer border! 
    
    winQT=$(echo $window_name | grep -c  "—\|Octopi\|Session\|System\|HeidiSQL\|qBittorrent\|Clementine\|digiKam\|Okular\|KeePassXC\|Krusader\|LibreOffice\|Telegram") # Apps with QT behaviour
    winGTK=$(echo $window_name | grep -c  "Krusader/ -/ ROOT\|Mozilla") # Force GTK behaviour for apps like Krusader as root
    winOther=$(echo $window_name | grep -c  "Scanner\|Twitter\|Maps\|iPlayer\|Calendar\|Photos\|Podcasts\|WhatsApp") # To catch other apps which don't conform or behave including headless Chrome windows saved as shortcuts
    
    if [ "$winOther" -gt 0 ] ; then
        gtk_fix=0
        footer_height=0
        header_height=0
    elif [ "$winQT" -eq 0 ] || [ "$winGTK" -gt 0 ] ; then
        gtk_fix=$border_gtk
        header_height=$border_gtk
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

    y_multiplier=$(( $(($window_y_pos - $1 - $3)) / $5 ))
# echo "Delta Position - " $window_y_pos " - " $y_multiplier " - " $6
    window_fit_pos=$(( $display_height - $1 - $2 ))
    top_margin=$(($1 + $3)) 
    top_offset=$(($top_margin - $4))

    if [ "$window_name" != "Desktop — Plasma" ]; then
        if  [ $6 -eq 1 ]; then
            window_y_new_pos=$(( $(($(($y_multiplier + 1)) * $5)) + $top_offset)) 
            window_base_pos=$(( $window_height + $window_y_pos))
            window_fit_height=$(($display_height - $window_y_new_pos - $2 - $footer_height))
            if [ $window_height -gt $window_fit_height ] || [ $window_base_pos -gt $window_fit_pos ] ; then
                window_height=$window_fit_height
            fi
            xdotool windowsize --sync $active_window_id $window_width $window_height
            xdotool windowmove --sync $active_window_id 'x' $window_y_new_pos
            xdotool mousemove $pointer_x $(($pointer_y + $window_y_new_pos - $window_y_pos + $4))
        else
             if [ $y_multiplier -lt 2 ]; then
                    window_y_new_pos=$top_offset
            else
                    window_y_new_pos=$(( $(($(($y_multiplier - 1)) * $5)) + $top_offset))
            fi
            window_base_pos=$(( $window_height + $window_y_pos))
            window_fit_height=$(($display_height - $window_y_new_pos - $2 - $footer_height))
            if [ $window_height -gt $window_fit_height ] || [ $window_base_pos -gt $window_fit_pos ] ; then
                window_height=$(($window_fit_height))
            fi
             xdotool windowsize --sync $active_window_id $window_width $window_height
             xdotool windowmove --sync $active_window_id 'x' $window_y_new_pos
             xdotool mousemove $pointer_x $(($pointer_y + $window_y_new_pos - $window_y_pos + $4))
        fi
    fi
}



# Function windowwidth provides a width expand/contract function in steps proportional to screen width
# parameters: $1 <window_y_pos>, $2 <side margin>, $3 <width step delta>, $4 <direction 1=increase> 
function windowwidth () {

    window_fit_width=$(($display_width - $((2 * $1))))
    window_delta=$(($window_fit_width / $4))
    window_y_pos=$(($3 - $5))
    window_x_pos=$2

    if [ "$window_name" != "Desktop — Plasma" ]; then
            if [ $6 == 1 ]; then
                    window_new_width=$(($window_width + $window_delta))
                    window_x_new_pos=$(($window_x_pos - $(($window_delta / 2))))
                    if [ $window_new_width -ge $window_fit_width ]; then
                        window_new_width=$window_fit_width
                        window_x_new_pos=$1
                    elif [ $window_x_pos -lt $(($window_delta / 2)) ]; then
                        window_x_new_pos=$1
                    elif [ $(($window_new_width + $window_x_pos)) -gt $window_fit_width ]; then
                        window_x_new_pos=$(($display_width - $window_new_width - $1))
                    fi
                    xdotool windowmove --sync $active_window_id $window_x_new_pos $window_y_pos
                    xdotool windowsize --sync $active_window_id $window_new_width $window_height
            else
                    window_new_width=$(($window_width - $window_delta))
                    window_x_new_pos=$(($window_x_pos + $(($window_delta / 2))))                    
                    
                    if [ $(($display_width - $window_width - $window_x_pos)) -le $(($window_delta / 2)) ]; then
                        window_x_new_pos=$(($display_width - $window_new_width - $1))
                    elif [ $window_x_pos -lt $(($window_delta / 2))  ]; then
                        window_x_new_pos=$1
                    fi

                    xdotool windowsize --sync $active_window_id $window_new_width $window_height
                    if [ $(xdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print $3}') -ne  $window_width ]; then
                        xdotool windowmove --sync $active_window_id $window_x_new_pos $window_y_pos
                    fi
                    if [ $pointer_x -ge $(($window_x_new_pos + $window_new_width - $window_delta))  ]; then
                        xdotool mousemove $(($window_x_new_pos + $window_new_width - $window_delta)) $pointer_y
                    elif [ $pointer_x -le $(($window_x_new_pos + $window_delta))  ]; then
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
 
    window_y_new_pos=$(($window_y_pos - $5))
    window_fit_height=$(($display_height - $1 - $3))

    if [ "$window_name" != "Desktop — Plasma" ];
        then
        if [ $window_height -gt $window_fit_height ]; then
            window_new_height=$window_fit_height
            xdotool windowsize --sync $active_window_id $window_width $window_new_height
        fi
        if [ $9 -eq 0 ]; then
            if [ $window_x_pos -eq $2 ]; then
                window_x_new_pos=$(($6 + $2))
            elif [ $window_x_pos -eq $(($6 + $2)) ]; then
                window_x_new_pos=$(($7 + $2))
            elif [ $window_x_pos -eq $(($7 + $2)) ]; then
                window_x_new_pos=$(($8 + $2))
            else
                window_x_new_pos=$2
            fi 
        elif [ $9 -eq 1 ]; then
            if [ $window_x_pos -eq $(($display_width - $window_width - $2)) ]; then
                window_x_new_pos=$(($display_width - $window_width - $6 - $2))
            elif [ $window_x_pos -eq $(($display_width - $window_width - $6 - $2)) ]; then
                window_x_new_pos=$(($display_width - $window_width - $7 - $2))
            elif [ $window_x_pos -eq $(($display_width - $window_width - $7 - $2)) ]; then
                window_x_new_pos=$(($display_width - $window_width - $8 - $2))
            else
                window_x_new_pos=$(($display_width - $window_width - $2))
            fi
        elif [ $9 -eq 2 ]; then
            window_x_new_pos=$((($display_width - $window_width) /2 ))
        fi
#         if [ $4 -eq 0 ]; then
#             xdotool windowmove --sync $active_window_id $window_x_new_pos 'y'
#             xdotool mousemove $(($pointer_x + $window_x_new_pos - $window_x_pos)) $pointer_y
#         else
            xdotool windowmove --sync $active_window_id $window_x_new_pos $window_y_new_pos
            xdotool mousemove $(($pointer_x + $window_x_new_pos - $window_x_pos)) $pointer_y
#         fi
    fi

 }

# Function minimize minimizes all other windows other than the active window to clear screen clutter 
 function minimize () {
 
    active_window_id=$(xdotool getwindowfocus)
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
        windowmove $top_margin $side_margin $bottom_margin $footer_height $gtk_fix $margin_delta $(($margin_delta * 2)) $(($margin_delta * 3)) 0
    ;;
    moveR )
        windowmove $top_margin $side_margin $bottom_margin $footer_height $gtk_fix $margin_delta $(($margin_delta * 2)) $(($margin_delta * 3)) 1
    ;;
    moveC )
        windowmove $top_margin $side_margin $bottom_margin $footer_height $gtk_fix 0 0 0 2
    ;;
    zoomP )
        windowzoom $top_margin $side_margin $gtk_fix $width_delta $height_delta 1
    ;;
    zoomM )
        windowzoom $top_margin $side_margin $gtk_fix $width_delta $height_delta 0
    ;;
    widthM )
        windowwidth $side_margin $window_x_pos $window_y_pos $width_steps $footer_height 0
    ;;  
    widthP )
        windowwidth $side_margin $window_x_pos $window_y_pos $width_steps $footer_height 1
    ;;  
    heightM )
        windowheight $top_margin $bottom_margin $height_steps $gtk_fix 1
    ;;  
    heightP )
        windowheight $top_margin $bottom_margin $height_steps $gtk_fix 0
    ;; 
    topP )
        windowtop $top_margin $bottom_margin $header_height $gtk_fix $margin_delta 1
        ;; 
    topM )
        windowtop $top_margin $bottom_margin $header_height $gtk_fix $margin_delta 0
        ;;
    minimize )
        minimize
    ;;    
    *)
    echo "Command not recognized! - Usage window-move.sh <command> <int. offset> . Commands moveL, moveR, moveC, zoomM, zoomP, widthM, widthP, heightM, heightP or winTop with integer offfset!"
    ;;
esac
