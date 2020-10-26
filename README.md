# kde-window-moves
A set of KDE window movement/resize/minimise scripts using xdotool

At the outset the aim was to provide a reliable way to position windows with keyboard shorcuts. The discovery of xdotool gives the opportunity to automate some useful moves without too much sweat.

I like to have windows aligned left, right or centred but not neccesarily full screen in a repeatable way. Removing the fiddle of mouse or trackpad actions to grab the window and move or resize. Equally I like to clear the clutter on the desktop and minimise all open windows except the window currently in focus or minimise any window under the cursor focus. Then assign quick intuitive key combinations for any of these actions.

There are some issues not yet resolved as the KDE environment supports native QT based GUI apps as well as GTK apps which ar native to Gnome desktop flavours. xdotool recognises a QT window as being the content without the window as position and size but GTK windows as the complete frame/border as the size/position coordinates. As a result different input parameters are used for each window type. In practice this is native Kate, Konsole, Dolphin, kdevelop etc as QT and Chrome, Firefox, Thunderbird, Gimp as GTK. The work around for now is to use different signature key combinations to manage each.

The set of example key combinations can be a starting point for any preferred scheme.

The scripts should be placed in /usr/local/bin and set executable 755

Using the KDE System Settings > Shortcuts > Custom Shortcuts dialogue import the WindowMoves.khotkeys file to create a keymapping group.

The mapping scheme:

QT KDE apps: <Ctrl> + <Shift> + ...
GTK apps full height: <Ctrl> + <Alt> + ...
GTK apps below top menu/panel: <Meta> + <Alt> ...
  
The above combinations with navigation keys <Left> <Right> <Up> <Down> < < > < > > are reasonably intuitive to learn
  
In addition the script to minimze all windows except the one in focus is <Ctrl> + <Shift> + m
