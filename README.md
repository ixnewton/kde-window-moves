# kde-window-moves
A set of KDE window movement/resize/minimise scripts using xdotool

At the outset the aim was to provide a reliable way to position windows with keyboard shorcuts. The discovery of xdotool gives the opportunity to automate some useful moves without too much sweat.

I like to have windows aligned left, right or centred but not neccesarily full screen in a repeatable way. Removing the fiddle of mouse or trackpad actions to grab the window and move or resize. Equally I like to clear the clutter on the desktop and minimise all open windows except the window currently in focus or minimise any window under the cursor focus. I have tried to assign consistent intuitive key combinations for any of these actions.

There are some issues not yet resolved as the KDE environment supports native QT based GUI apps as well as GTK apps which are native to Gnome desktop flavours. xdotool gets the window coordinates of any window as being the content without the window for position coordinates but when setting position (xdotool windowmove) moves the inner window to the position requested for QT windows and the outer window with decoration for GTK. As a result different input parameters are used for each window type. In practice this is native Kate, Konsole, Dolphin, kdevelop etc as QT and Chrome, Firefox, Thunderbird, Gimp as GTK. The work around for now is to detect the window type by the separator character used in the window title which works for the majority of applications. This is not a robust solution some apps are out by the window border width notably Wine apps and Libreoffice though this is not fatal. I hope to persuade the xdotool project to fix this!

The set of example key combinations can be a starting point for any preferred scheme.

The scripts should be placed in /usr/local/bin and set executable 755

Using the KDE System Settings > Shortcuts > Custom Shortcuts dialogue import the WindowMoves.khotkeys file to create a keymapping group.

The mapping scheme:

All actions: `<Ctrl> + <Shift> + ...`
  
The above combinations with navigation keys `<Left> <Right> <Up> <Down> c (center) < (width -) > (width +) 1 2 3` are reasonably intuitive to learn.   
In addition the script to minimze all windows except the one in focus has been set as `<Ctrl> + <Shift> + m `

Standard KDE global shortcuts group "kwin" can be given alternative key mappings for instance minimize window `<Ctrl> + <Shift> + n ` and close window `<Ctrl> + <Shift> + b ` to be in line with this scheme.

The command parameters:

`window-moves.sh moveR - Move right` - Moves window to right margin (5px) horizontally

`window-moves.sh moveL - Move left` - Moves window to left margin (5px) horizontally

`window-moves.sh moveC - Move center` - Moves window to center horizontally

`window-moves.sh widthM - Width minus` - Adjusts width centered or from edge 32 steps

`window-moves.sh widthP - Width plus` - Adjusts width centered or from edge 32 steps

`window-moves.sh heightM - Height minus` - Adjusts height from bottom in 16 steps

`window-moves.sh heightP - Height plus` - Adjusts height from bottom in 16 steps

`window-moves.sh winTop 1 - Top margin 5px` - Set to be on the top margin which is 5px

`window-moves.sh winTop 2 - Top margin 63px` - Set below desktop top panel which is 60px  

`window-moves.sh winTop 3 - Top margin 90px` - Set to be in the main body of desktop 90px

If the xdotool windowmove can be fixed to behave the same for QT or GTK windows then there would be no need for position work arounds! 

