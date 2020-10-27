# kde-window-moves
A set of KDE window movement/resize/minimise scripts using xdotool

At the outset the aim was to provide a reliable way to position windows with keyboard shorcuts. The discovery of xdotool gives the opportunity to automate some useful moves without too much sweat.

I like to have windows aligned left, right or centred but not neccesarily full screen in a repeatable way. Removing the fiddle of mouse or trackpad actions to grab the window and move or resize. Equally I like to clear the clutter on the desktop and minimise all open windows except the window currently in focus or minimise any window under the cursor focus. I have tried to assign a consistent intuitive key combinations for any of these actions.

There are some issues not yet resolved as the KDE environment supports native QT based GUI apps as well as GTK apps which ar native to Gnome desktop flavours. xdotool recognises a QT window as being the content without the window as position and size but GTK windows as the complete frame/border as the size/position coordinates. As a result different input parameters are used for each window type. In practice this is native Kate, Konsole, Dolphin, kdevelop etc as QT and Chrome, Firefox, Thunderbird, Gimp as GTK. The work around for now is to use different signature key combinations to manage each.

The set of example key combinations can be a starting point for any preferred scheme.

The scripts should be placed in /usr/local/bin and set executable 755

Using the KDE System Settings > Shortcuts > Custom Shortcuts dialogue import the WindowMoves.khotkeys file to create a keymapping group.

The mapping scheme:

QT KDE apps: `<Ctrl> + <Shift> + ...`

GTK apps full height: `<Ctrl> + <Alt> + ...`

GTK apps below top menu/panel: `<Meta> + <Alt> ...`
  
The above combinations with navigation keys `<Left> <Right> <Up> <Down> c (center) < (width -) > (width +)` are reasonably intuitive to learn.   
In addition the script to minimze all windows except the one in focus has been set as `<Ctrl> + <Shift> + m `

Standard KDE global shortcuts group "kwin" can be given alternative key mappings  for instance minimize window `<Ctrl> + <Shift> + n ` and close window `<Ctrl> + <Shift> + b ` to be in line with this scheme.

The parameters:

`WindowMove_R - %1 - top margin` `%2 - right margin` `%3 - bottom margin`

`WindowMove_L - %1 - top margin` `%2 - left margin` `%3 - bottom margin`

`WindowCenter - $1 - top margin` `$2 - bottom margin`

`WindowHeight - $1 - top margin` `$2 - bottom margin` `$3 - hight delta divider` `$4 - direction 0 ( < reduce) 1 ( > increase)`

`WindowWidth - $1 - top margin` `$2 - left margin` `$3 - width delta divider` `$4 - direction 0 ( < reduce) 1 ( > increase)`


If detection of QT or GTK can be detected then the key commands could be reduced! 

