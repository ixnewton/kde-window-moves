# kde-window-moves
A KDE window movement/resize/zoom/minimise script using xdotool for reference postioning of windows in KDE/Plasma 5 desktop on X11. xdotool has problems getting or setting QT windows under Wayland.

At the outset the aim was to provide a reliable way to position windows with keyboard shorcuts using KDE's khotkeys. The discovery of xdotool gives the opportunity to automate some useful moves without too much sweat.

I like to have windows aligned left, right or centred but not neccesarily full screen in a repeatable way. Removing the fiddle of mouse or trackpad actions to grab the window and move or resize. Equally I like to clear the clutter on the desktop and minimise all open windows except the window currently in focus or minimise any window under the cursor focus. I have tried to assign consistent intuitive key combinations for any of these actions.

There are some issues not yet resolved as the KDE environment supports native QT based GUI apps as well as GTK apps which are native to Gnome desktop flavours. xdotool gets the window coordinates of any window as being the content without the window for position coordinates but when setting position (xdotool windowmove) moves the inner window to the position requested for QT windows and the outer window with decoration for GTK. As a result different input parameters are used for each window type. In practice this is native Kate, Konsole, Dolphin, kdevelop etc as QT and Chrome, Firefox, Thunderbird, Gimp as GTK. The work around for now is to detect the window type by the separator character used in the window title which works for the majority of applications. This is not a robust solution some apps are out by the window border width notably Wine apps and Libreoffice though this is not fatal. I hope to persuade the xdotool project to fix this! 

One thing I use to help unify the appearance and to some extent behaviour of GTK styled windows is gtk3-nocsd which replaces any GTK header with the desktop QT style. This should be installed to work with the latest update of window-moves.sh. Available from your package manager (pacman, yum, apt etc) or https://github.com/PCMan/gtk3-nocsd .   

I favour minimal window borders with only an 18px header with borderless sides and bottom, one of the nicer style things nicked from MacOS! There may be position issues if side/bottom borders are used as an additional margin fix would have to be applied for the left window border of GTK windows. 

One behaviour implemented in widthM/widthP/winTop is that left, right and bottom edges are sticky so when a window is close to the margin zone this edge is static and expansion is then relative to the "sticky" edge.

When a window is moved by any function the screen cursor is repostioned to follow the window and to prevent the cursor losing the window's focus.

KDE remembers the size and position of application windows so they re-open at the last used layout position. window-moves.sh can quickly set preferred layouts for most applications.   

The set of example key combinations can be a starting point for any preferred scheme.

The scripts should be placed in /usr/local/bin and set executable 755

The shortcuts depend on khotkeys being installed so make sure it is there in your package manager. Using the KDE System Settings > Shortcuts > Custom Shortcuts dialogue import the WindowMoves.khotkeys file to create a keymapping group. Due to rework of how shortcuts are set for applications "Custom Shortcuts" has become effectively an additional application. To get everything working the new way it may be necessary reset to defaults the main shortcuts and reload custom shortcut groups/folders from saved .khotkeys files. Once backups of your custom shortcuts are saved delete "Custom Shortcuts" in the "System" part of Shortcuts then set all shortcuts to defaults. To restore custom shortcuts re-apply saved shortcut files including WindowMoves.khotkeys and all should be well. In my case this resolved non functional Ctrl+Z, Ctrl+X, Ctrl+Y shortcuts in key editors like Kate.   

The mapping scheme:

All actions: `<Ctrl> + <Shift> + ...`
  
The above combinations with navigation keys `<Left> <Right> <Up> <Down> c (center) { (width -) } (width +)` are reasonably intuitive to learn.   
In addition the script to minimze all windows except the one in focus has been set as `<Ctrl> + <Shift> + m `. Window zoom is implemented in 5 steps either increasing as `<Ctrl> + <Shift> + w ` and decreasing `<Ctrl> + <Shift> + q ` and top Window margin implemented in 5 steps either increasing as `<Ctrl> + <Shift> + r ` and decreasing `<Ctrl> + <Shift> + e ` these are less obvious keys but unused by other apps or KDE. 

Standard KDE global shortcuts group "kwin" can be given alternative key mappings for instance minimize window `<Ctrl> + <Shift> + n ` and close window `<Ctrl> + <Shift> + b ` to be in line with this scheme.

The command parameters:

`window-moves.sh moveR - Move right` - Moves window to right margin (5px) horizontally with 3 margin steps *

`window-moves.sh moveL - Move left` - Moves window to left margin (5px) horizontally with 3 margin steps *

`window-moves.sh moveC - Move center` - Moves window to center horizontally *

`window-moves.sh zoomM - Zoom on center minus` - Zoom decreasing in 4 sequential steps *

`window-moves.sh zoomP - Zoom on center plus` - Zoom incresing in 4 sequetial steps *

`window-moves.sh widthM - Width minus` - Adjusts width centered or from edge 32 steps *

`window-moves.sh widthP - Width plus` - Adjusts width centered or from edge 32 steps *

`window-moves.sh heightM - Height minus` - Adjusts height of window bottom up in 16 steps *

`window-moves.sh heightP - Height plus` - Adjusts height of window bottom in 16 steps *

`window-moves.sh topM - Top margin minus` - Adjusts top margin in steps of 40px *

`window-moves.sh topP - Top margin plus` - Adjusts top margin in steps of 40px *

`window-moves.sh minimize - Minimize all` - Minimizes all but the focussed window

If the xdotool windowmove can be fixed to behave the same for QT or GTK windows then there would be no need for window detection and border work around fixes! In addition all but QT windows under Wayland currently work with the functions marked with * . QT windows will require some fix to qt5-wayland or kwayland to provide proper Wayland support.

