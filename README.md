# kde-window-moves
A KDE window movement/resize/zoom/minimise script using xdotool for reference postioning of windows in KDE/Plasma 5 desktop

At the outset the aim was to provide a reliable way to position windows with keyboard shorcuts. The discovery of xdotool gives the opportunity to automate some useful moves without too much sweat.

I like to have windows aligned left, right or centred but not neccesarily full screen in a repeatable way. Removing the fiddle of mouse or trackpad actions to grab the window and move or resize. Equally I like to clear the clutter on the desktop and minimise all open windows except the window currently in focus or minimise any window under the cursor focus. I have tried to assign consistent intuitive key combinations for any of these actions.

There are some issues not yet resolved as the KDE environment supports native QT based GUI apps as well as GTK apps which are native to Gnome desktop flavours. xdotool gets the window coordinates of any window as being the content without the window for position coordinates but when setting position (xdotool windowmove) moves the inner window to the position requested for QT windows and the outer window with decoration for GTK. As a result different input parameters are used for each window type. In practice this is native Kate, Konsole, Dolphin, kdevelop etc as QT and Chrome, Firefox, Thunderbird, Gimp as GTK. The work around for now is to detect the window type by the separator character used in the window title which works for the majority of applications. This is not a robust solution some apps are out by the window border width notably Wine apps and Libreoffice though this is not fatal. I hope to persuade the xdotool project to fix this!

I favour minimal window borders with only an 18px header with borderless sides and bottom, one of the nicer style things nicked from MacOS! There may be position issues if side/bottom borders are used as an additional margin fix would have to be applied for the left window border of GTK windows. 

One behaviour implemented in widthM/widthP/winTop is that left, right and bottom edges are sticky so when a window is close to the margin zone this edge is static and expansion is then relative to the "sticky" edge.

KDE remembers the size and position of application windows so they re-open at the last used layout position. window-moves.sh can quickly set preferred layouts for most applications.   

The set of example key combinations can be a starting point for any preferred scheme.

The scripts should be placed in /usr/local/bin and set executable 755

Using the KDE System Settings > Shortcuts > Custom Shortcuts dialogue import the WindowMoves.khotkeys file to create a keymapping group.

The mapping scheme:

All actions: `<Ctrl> + <Shift> + ...`
  
The above combinations with navigation keys `<Left> <Right> <Up> <Down> c (center) < (width -) > (width +) 1 2 3` are reasonably intuitive to learn.   
In addition the script to minimze all windows except the one in focus has been set as `<Ctrl> + <Shift> + m `. Window zoom is implemented in 4 steps either increasing as `<Ctrl> + <Shift> + w ` and decreasing `<Ctrl> + <Shift> + q ` these are less obvious keys but unused by other apps or KDE. 

Standard KDE global shortcuts group "kwin" can be given alternative key mappings for instance minimize window `<Ctrl> + <Shift> + n ` and close window `<Ctrl> + <Shift> + b ` to be in line with this scheme.

The command parameters:

`window-moves.sh moveR - Move right` - Moves window to right margin (5px) horizontally

`window-moves.sh moveL - Move left` - Moves window to left margin (5px) horizontally

`window-moves.sh moveC - Move center` - Moves window to center horizontally

`window-moves.sh zoomM - Zoom on center minus` - Zoom decreasing in 4 sequential steps

`window-moves.sh zoomP - Zoom on center plus` - Zoom incresing in 4 sequetial steps

`window-moves.sh widthM - Width minus` - Adjusts width centered or from edge 32 steps

`window-moves.sh widthP - Width plus` - Adjusts width centered or from edge 32 steps

`window-moves.sh heightM - Height minus` - Adjusts height of window bottom up in 16 steps

`window-moves.sh heightP - Height plus` - Adjusts height of window bottom in 16 steps

`window-moves.sh winTop 1 - Top margin 5px` - Set to be on the top margin which is 5px

`window-moves.sh winTop 2 - Top margin 63px` - Set below desktop top panel which is 60px  

`window-moves.sh winTop 3 - Top margin 90px` - Set to be in the main body of desktop 90px

If the xdotool windowmove can be fixed to behave the same for QT or GTK windows then there would be no need for window detection and a position work around fix! 

