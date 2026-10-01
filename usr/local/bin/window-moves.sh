#!/bin/bash
# Get the current window and desktop data
    active_window_id=$(kdotool getactivewindow)
    window_name=$(kdotool getwindowname $active_window_id)
    # $(cat /sys/class/drm/card1-eDP-1/modes | awk -F "[x]+" '{print $2}')
    window_width=$(kdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print int($3)}')
    window_height=$(kdotool getwindowgeometry $active_window_id | awk -F "[[:space:]x]+" '/Geometry:/{print int($4)}')
    window_y_pos=$(kdotool getwindowgeometry $active_window_id | awk -F "[[:space:],]+" '/Position:/{print int($4)}')
    window_x_pos=$(kdotool getwindowgeometry $active_window_id | awk -F "[[:space:],]+" '/Position:/{print int($3)}')
    pointer_x=$(kdotool getmouselocation | awk -F "[[:space:]]" '//{print $1}' | awk -F "[:]" '//{print int($2)}')
    pointer_y=$(kdotool getmouselocation | awk -F "[[:space:]]" '//{print $2}' | awk -F "[:]" '//{print int($2)}')

# Current set of margin and border sizes with gtk3-nocsd installed:
    top_margin=3        # provodes a comfortable close fit to top of screen
    side_margin=3       # provides a comfortable close fit to sides.
    bottom_margin=3     # provides a comfortable close fit to bottom of screen. Increase by frame size 0 -10 (px) if frame borders are enabled
    footer_height=0
    header_height=0
    gtk_fix=0           # The virtual offset size of window top frame for non QT windows
    top_delta=15        # Step delta for top margin
    margin_delta=6     # Step delta for left/right
    width_steps=42      # Step divider to width of screen width
    height_steps=42     # Step divider to height of screen height
    height_delta=42     # Y delta zoom step
    sync_delay=0.1      # Pause between paired kdotool resize/move calls; without it KWin drops one of the two operations

# Select the screen the active window sits on. Each Geometry line is
# "origin_x,origin_y widthxheight" in global coordinates (ANSI colour codes stripped).
    side_offset=0       # X origin of the window's screen, for absolute position calculations.
    display_width=0
    display_height=0
    while read -r origin size ; do
        origin_x=${origin%%,*}
        width=${size%%x*}
        if [[ $display_width -eq 0 ]] ; then
            display_width=$width
            display_height=${size##*x}
        fi
        if [[ $window_x_pos -ge $origin_x ]] && [[ $window_x_pos -lt $((origin_x + width)) ]] ; then
            side_offset=$origin_x
            display_width=$width
            display_height=${size##*x}
        fi
    done < <(kscreen-doctor -o | sed 's/\x1b\[[0-9;]*m//g' | grep Geometry | awk -F ": " '{print $2}')
    if [[ $display_width -eq 0 ]] ; then
        echo "No screen geometry detected from kscreen-doctor" >&2
        exit 1
    fi

# Detect QT windows which do not need any position fiddles to compensate for windowmove positioning by frame coords for GTK built apps
# With QT windows we add header_height and for GTK both gtk_fix for header and footer_height to compensate for a dummy footer border!
    
    if [ "$(echo $window_name | grep -c  "Konsole\|Dolphin\|Kate\|Kwrite\|Krusader\|Vivaldi\|Postman\|KDevelop\|Code - OSS\|System Settings\|System Monitor\|LSystemLog\|Octopi\|KDE Partition Manager")" -gt 0  ] ; then
        header_height=30
        app_type="KDE-Apps"
    elif [ "$(echo $window_name | grep -c  "Buddy List")" -gt 0  ] ; then
        header_height=0
        side_margin=0 
        app_type="GTKplus"
    else
        header_height=0
        app_type="Other-apps"
    fi

# Move the pointer by a relative delta (ydotool) so it keeps its relative position on the window
# The ydotoold virtual device needs a Flat acceleration profile for 1:1 deltas:
#   kwriteconfig6 --file kcminputrc --group "Libinput" --group "2333" --group "6666" \
#       --group "ydotoold virtual device" --key PointerAccelerationProfile 2
function move_pointer () {
    sleep 0.05
    ydotool mousemove -x $1 -y $2
}

if [[ $pointer_x -lt $window_x_pos ]] || [[ $pointer_x -ge $(($window_x_pos + $window_width)) ]] || [[ $pointer_y -lt $window_y_pos ]] || [[ $pointer_y -ge $(($window_y_pos + $window_height)) ]] ; then
    target_x=$(($window_x_pos + $window_width / 2))
    target_y=$(($window_y_pos + $window_height / 2))
    move_pointer $(($target_x - $pointer_x)) $(($target_y - $pointer_y))
    pointer_x=$target_x
    pointer_y=$target_y
fi

# Function windowheight provides window height adjustment from the bottom in steps by pixel amaount 
# parameters: $1 <top margin>, $2 <side margin>, $3 <window header>,  $4 <GTK header fix>, $5 <step in pixels>, $6 <direction 1=increase>
function windowheight () {

    window_fit_height=$(($display_height - $window_y_pos - $2))
    window_min_height=$(($window_fit_height * 9 / 32))
    window_delta=$(($window_fit_height / $3))
    
    if [ "$window_name" != "Desktop — Plasma" ]; then
            if [ $5 == 1 ]; then
                    window_new_height=$(($window_height + $window_delta))
                    if [[ $window_new_height -gt $window_fit_height ]]; then
                        window_new_height=$window_fit_height
                    fi
            else
                    window_new_height=$(($window_height - $window_delta))
                    if [[ $window_new_height -lt $window_min_height ]]; then
                        window_new_height=$window_min_height
                    fi
            fi
            kdotool windowsize $active_window_id $window_width $window_new_height
            sleep $sync_delay
            kdotool windowmove $active_window_id $window_x_pos $window_y_pos
            new_bottom=$(($window_new_height + $window_y_pos))
            if [ $(($pointer_y + $window_delta)) -ge $new_bottom ]; then
                move_pointer 0 $(($new_bottom - $pointer_y))
            fi
    fi

 }

# Function windowtop provides a top margin expand/contract function in steps by pixel amaount
# parameters: $1 <top margin>, $2 <side margin>, $3 <window header>,  $4 <GTK header fix>, $5 <step in pixels>, $6 <direction 1=increase> 
function windowtop () {

    y_multiplier=$(($(($window_y_pos - $1 - $3)) / $5 ))
    window_fit_pos=$(( $display_height - $1 - $2 ))
    top_margin=$(($1 + $3 - $4))

    if [ "$window_name" != "Desktop — Plasma" ]; then
        if  [[ $6 -eq 1 ]]; then
            window_y_new_pos=$(( $(($(($y_multiplier + 1)) * $5)) + $top_margin))
            window_base_pos=$(( $window_height + $window_y_pos))
            window_fit_height=$(($display_height - $window_y_new_pos - $2 - $footer_height))
            if [[ $window_height -gt $window_fit_height ]] || [[ $window_base_pos -gt $window_fit_pos ]] ; then
                window_height=$window_fit_height
            fi
        else
             if [[ $y_multiplier -eq 0 ]]; then
                    window_y_new_pos=$top_margin
            else
                    window_y_new_pos=$(( $(($(($y_multiplier - 1)) * $5)) + $top_margin))
            fi
            window_base_pos=$(( $window_height + $window_y_pos))
            window_fit_height=$(($display_height - $window_y_new_pos - $2 - $footer_height))
            if [[ $window_height -gt $window_fit_height ]] || [[ $window_base_pos -gt $window_fit_pos ]] ; then
                window_height=$(($window_fit_height))
            fi
        fi
        if [[ $6 -eq 1 ]]; then
            kdotool windowmove $active_window_id $window_x_pos $window_y_new_pos
            sleep $sync_delay
            kdotool windowsize $active_window_id $window_width $window_height
        else
            kdotool windowsize $active_window_id $window_width $window_height
            sleep $sync_delay
            kdotool windowmove $active_window_id $window_x_pos $window_y_new_pos
        fi
        move_pointer 0 $(($window_y_new_pos - $window_y_pos + $gtk_fix))
    fi

 }

# Function windowwidth provides a width expand/contract function in steps proportional to screen width
# parameters: $1 <side margin>, $2 <window_x_pos>, $3 <window_y_pos>, $4 <header height>, $5 <gtk_fix>, $6 <width step delta>, $7 <footer height>, $8 <direction 1=increase> 
function windowwidth () {

    window_fit_width=$(($display_width - $((2 * $1))))
    window_delta=$(($window_fit_width/$6))
    window_y_new_pos=$(($3 - $5))
    window_x_pos=$2
    window_x_new_pos=$2

    if [ "$window_name" != "Desktop — Plasma" ]; then
            if [ $8 == 1 ]; then
                    window_new_width=$(($window_width + $window_delta))
                    window_x_new_pos=$2
                    if [[ $window_new_width -ge $window_fit_width ]]; then
                        window_new_width=$window_fit_width
                        window_x_new_pos=$1
                    elif [[ $window_x_pos -lt $(($window_delta / 2)) ]]; then
                        window_x_new_pos=$1
                    elif [[ $(($window_new_width + $window_x_new_pos)) -gt $window_fit_width ]]; then
                        window_x_new_pos=$(($display_width - $window_new_width))
                    fi
                    window_x_new_pos=$(($window_x_new_pos + $side_offset))
                    kdotool windowmove $active_window_id $window_x_new_pos $window_y_new_pos
                    sleep $sync_delay
                    kdotool windowsize $active_window_id $window_new_width $window_height
            else
                    window_new_width=$(($window_width - $window_delta))
                    if [[ $window_width -le $window_fit_width ]]; then
                        window_x_new_pos=$2
                    elif [[ $(($window_x_pos + $window_width - $1)) -ge $window_fit_width ]]; then
                         window_x_new_pos=$(($window_fit_width - $window_new_width + $1))
                    elif [[ $(($window_x_pos)) -lt $(($window_delta / 2)) ]]; then
                        window_x_new_pos=$1
                    else
                        window_x_new_pos=$window_x_pos
                    fi
                     window_x_new_pos=$(($window_x_new_pos + $side_offset))
                     kdotool windowsize $active_window_id $window_new_width $window_height
                     sleep $sync_delay
                     kdotool windowmove $active_window_id $window_x_new_pos $window_y_new_pos
                     right_edge=$(($window_x_new_pos + $window_new_width - $window_delta))
                     left_edge=$(($window_x_new_pos + $window_delta))
                     if [ $pointer_x -ge $right_edge ]; then
                         move_pointer $(($right_edge - $pointer_x)) 0
                     elif [ $pointer_x -le $left_edge ]; then
                         move_pointer $(($left_edge - $pointer_x)) 0
                     fi
            fi
    fi

 }

# Function windowzoom provides a zoom function centered and proportional to the screen size
# parameters: $1 <top margin>, $2 <side margin>, $3 <window header>, $4 <GTK header fix> ,  $5 <vertical step delta>, $6 <margin delta>, $7 <direction 1=increase> 
function windowzoom () {

    window_fit_height=$(($display_height - $1 - $1 - $3))
    window_fit_width=$(($display_width - $2 - $2))
    window_min_width=800
    window_min_height=450
    zoom_y_delta=$5
    if [[ $window_width -ge $window_fit_width ]] && [[ $7 -eq 0 ]]; then
        kdotool windowstate --remove MAXIMIZED_VERT $active_window_id  # Fixes maxed window V
        kdotool windowstate --remove MAXIMIZED_HORZ $active_window_id  # Fixes maxed window H
        zoom_x_delta=$(($6 * 2))
    else
        zoom_x_delta=$(($(($window_width * $5)) / $window_height))
    fi
    top_margin=$(($1 + $3 - $4))

    if [ "$window_name" != "Desktop — Plasma" ]; then
        if  [[ $7 -eq 1 ]]; then
            if [[ $window_width -lt  $(($window_fit_width - $zoom_x_delta)) ]]; then            
                window_new_width=$(($window_width + $zoom_x_delta))
            else
                window_new_width=$(($window_fit_width))
            fi
            if [[ $window_height -lt  $(($window_fit_height - $zoom_y_delta)) ]]; then            
                window_new_height=$(($window_height + $zoom_y_delta))
            else
                window_new_height=$(($window_fit_height))
            fi
            if [[ $(($window_new_width + $window_x_pos - $2)) -lt $window_fit_width ]]; then
                window_x_new_pos=$window_x_pos
            else
                window_x_new_pos=$(($window_fit_width - $window_new_width + $2))
            fi
            if [[ $(($window_new_height + $window_y_pos - $1)) -ge $window_fit_height ]]; then
                window_y_new_pos=$top_margin
            else
                window_y_new_pos=$(($window_y_pos))
            fi
            window_x_new_pos=$(($window_x_new_pos + $side_offset))
            kdotool windowmove $active_window_id $window_x_new_pos $window_y_new_pos
            sleep $sync_delay
            kdotool windowsize $active_window_id $window_new_width $window_new_height
        else
            if [[ $window_width -ge $(($window_min_width + $zoom_x_delta)) ]]; then
                window_new_width=$(($window_width - $zoom_x_delta))
            else
                window_new_width=$(($window_min_width))
            fi
            if [[ $window_height -ge $(($window_min_height + $zoom_y_delta)) ]]; then
                window_new_height=$(($window_height - $zoom_y_delta))
            else
                window_new_height=$(($window_min_height))
            fi
            if [[ $window_width -ge $window_fit_width ]]; then
                window_x_new_pos=$(($6 + $2))
            else
                window_x_new_pos=$(($window_x_pos))
            fi
            if [[ $(($window_height + $top_margin)) -ge $window_fit_height ]]; then
                window_y_new_pos=$(($6 + $top_margin))
            else
                window_y_new_pos=$(($window_y_pos))
            fi
            window_x_new_pos=$(($window_x_new_pos + $side_offset))
            kdotool windowsize $active_window_id $window_new_width $window_new_height
            sleep $sync_delay
            kdotool windowmove $active_window_id $window_x_new_pos $window_y_new_pos
        fi
        margin_x=$(($zoom_x_delta / 4))
        target_x=$pointer_x
        target_y=$pointer_y
        if [ $pointer_x -ge $(($window_x_new_pos + $window_new_width - $margin_x)) ]; then
            target_x=$(($window_x_new_pos + $window_new_width - $margin_x))
        elif [ $pointer_x -le $(($window_x_new_pos + $margin_x)) ]; then
            target_x=$(($window_x_new_pos + $margin_x))
        elif [ $pointer_y -ge $(($window_y_new_pos + $window_new_height - $zoom_y_delta)) ]; then
            target_y=$(($window_y_new_pos + $window_new_height - $(($zoom_y_delta / 2))))
        elif [ $pointer_y -le $(($window_y_new_pos + $zoom_y_delta)) ]; then
            target_y=$(($window_y_new_pos + $(($zoom_y_delta / 2))))
        fi
        move_pointer $(($target_x - $pointer_x)) $(($target_y - $pointer_y))
    fi

 }

# Function windowmove moves the window left/right/centre with step adjustments for left/right by step pixel steps
# parameters: $1 <top margin>, $2 <side margin>, $3 <bottom margin>, $4 <header height>, $5 <GTK fix>, $6 <horizontal step 1>, $7 <step 2>, $8 <step 3>, 
# $9 <direction 0:left 1:right 2:center> 
function windowmove () {
 
    window_y_new_pos=$(($window_y_pos - $5))
    window_fit_height=$(($display_height - $1 - $3))
    window_fit_width=$(($display_width - $2 - $2 + $5 + $5))
    window_x_rel_pos=$(($window_x_pos - $side_offset))

    if [ "$window_name" != "Desktop — Plasma" ]; then
        if [ $9 -eq 0 ]; then
            if [[ $window_x_rel_pos -eq $2 ]]; then
                window_x_new_pos=$(($6 + $2))
            elif [[ $window_x_rel_pos -eq $(($6 + $2)) ]]; then
                window_x_new_pos=$(($7 + $2))
            elif [[ $window_x_rel_pos -eq $(($7 + $2)) ]]; then
                window_x_new_pos=$(($8 + $2))
            elif [[ $window_x_rel_pos -eq $(($8 + $2)) ]]; then
                window_x_new_pos=$((($display_width - $window_width) / 2))
            else
                window_x_new_pos=$2
            fi
        elif [[ $9 -eq 1 ]]; then
            if [[ $window_x_rel_pos -eq $(($display_width - $window_width - $2)) ]]; then
                window_x_new_pos=$(($display_width - $window_width - $6 - $2))
            elif [[ $window_x_rel_pos -eq $(($display_width - $window_width - $6 - $2)) ]]; then
                window_x_new_pos=$(($display_width - $window_width - $7 - $2))
            elif [[ $window_x_rel_pos -eq $(($display_width - $window_width - $7 - $2)) ]]; then
                window_x_new_pos=$(($display_width - $window_width - $8 - $2))
            elif [[ $window_x_rel_pos -eq $(($display_width - $window_width - $8 - $2)) ]]; then
                window_x_new_pos=$((($display_width - $window_width) / 2 ))
            else
                window_x_new_pos=$(($display_width - $window_width - $2))
            fi
        elif [[ $9 -eq 2 ]]; then
            window_x_new_pos=$((($display_width - $window_width) /2 ))
        fi
        
        # Ensure window_x_new_pos is set to avoid arithmetic errors
        if [[ -z "$window_x_new_pos" ]]; then
            window_x_new_pos=$window_x_pos
        fi
        
        if [[ $(($window_x_new_pos + $window_width)) -ge $window_fit_width ]]; then
            window_x_new_pos=$(($window_fit_width - $window_width + $2))  
        fi
        if [[ $window_x_new_pos -lt $2 ]]; then
            window_x_new_pos=$2
        fi
        window_x_new_pos=$(($window_x_new_pos + $side_offset))

# echo "$active_window_id $window_x_new_pos $window_y_new_pos"
        kdotool windowmove $active_window_id $window_x_new_pos $window_y_new_pos
        move_pointer $(($window_x_new_pos - $window_x_pos)) 0
    fi

 }

# Function windowzoom provides a zoom function centered and proportional to the screen size
# parameters: $1 <top margin>, $2 <side margin>, $3 <window header>, $4 <GTK header fix> ,  $5 <vertical step delta>, $6 <margin delta>, $7 <direction 1=increase>
function windowexpand () {

    window_fit_width=$(($display_width - $2 - $2))
    window_y_new_pos=$(($window_y_pos - $5))
    window_min_width=800
    zoom_x_delta=$5
    if [[ $window_width -ge $window_fit_width ]] && [ $7 -eq 0 ]; then
        kdotool windowstate --remove MAXIMIZED_HORZ $active_window_id  # Fixes maxed window H
    fi

    if [ "$window_name" != "Desktop — Plasma" ]; then
        if  [[ $9 -eq 1 ]]; then
            if [[ $window_width -lt  $(($window_fit_width - $(($window_x_pos * 2)))) ]]; then
                echo $window_width > ~/$active_window_id
                window_new_width=$(($display_width - $(($window_x_pos * 2))))
            else
                saved_width=$(<$active_window_id)
                if [[ $saved_width -gt 0 ]]; then
                    window_new_width=$saved_width
                else
                    window_new_width=$window_min_width
                fi
            fi
            window_x_new_pos=$(($window_x_new_pos + $side_offset))
            kdotool windowsize $active_window_id $window_new_width $window_height
        fi
    fi

 }

# Function minimize minimizes all other windows other than the active window to clear screen clutter 
 function minimize () {
 
    active_window_id=$(kdotool getactivewindow)
    for window_id in $(kdotool search)
    do
        if [ $window_id != $active_window_id ]
        then
            kdotool windowminimize $window_id
        fi
    done
 }
 
# echo "app_type - "$app_type
 # Selector for functions with parameter sets. These can be adjusted to suit personal perferences.
 case $1 in
    moveL )
        windowmove $top_margin $side_margin $bottom_margin $header_height $gtk_fix $margin_delta $(($margin_delta * 4)) $(($margin_delta * 12)) 0 $side_offset
    ;;
    moveR )
        windowmove $top_margin $side_margin $bottom_margin $header_height $gtk_fix $margin_delta $(($margin_delta * 4)) $(($margin_delta * 12)) 1 $side_offset
    ;;
    expandP )
        windowexpand $top_margin $side_margin $bottom_margin $header_height $gtk_fix $margin_delta $(($margin_delta * 4)) $(($margin_delta * 12)) 1 $side_offset
    ;;
    moveC )
        windowmove $top_margin $side_margin $bottom_margin $footer_height $gtk_fix 0 0 0 2 $side_offset
    ;;
    zoomP )
        windowzoom $top_margin $side_margin $header_height $gtk_fix $height_delta $margin_delta 1 $side_offset
    ;;
    zoomM )
        windowzoom $top_margin $side_margin $header_height $gtk_fix $height_delta $margin_delta 0 $side_offset
    ;;
    widthM )
        windowwidth $side_margin $window_x_pos $window_y_pos $header_height $gtk_fix $width_steps $footer_height 0 $side_offset
    ;;  
    widthP )
        windowwidth $side_margin $window_x_pos $window_y_pos $header_height $gtk_fix $width_steps $footer_height 1 $side_offset
    ;;
    heightM )
        windowheight $top_margin $bottom_margin $height_steps $gtk_fix 1
    ;;  
    heightP )
        windowheight $top_margin $bottom_margin $height_steps $gtk_fix 0
    ;; 
    topP )
        windowtop $top_margin $bottom_margin $header_height $gtk_fix $top_delta 1
        ;; 
    topM )
        windowtop $top_margin $bottom_margin $header_height $gtk_fix $top_delta 0
        ;;
    minimize )
        minimize
    ;;    
    *)
    echo "Command not recognized! - Usage window-move.sh <command> <int. offset> . Commands moveL, moveR, moveC, zoomM, zoomP, widthM, widthP, heightM, heightP or winTop with integer offfset!"
    ;;
 esac
