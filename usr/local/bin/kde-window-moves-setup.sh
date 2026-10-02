#!/bin/bash
# kde-window-moves-setup.sh - per-user session setup for kde-window-moves:
# enables ydotoold, sets the flat pointer profile and registers the
# "KDE Window Moves" global shortcut set with KGlobalAccel.
# Run once per user from a KDE session; safe to re-run.
#
# Usage: kde-window-moves-setup.sh [kksrc_file] [desktop_file]

set -e

kksrc="${1:-/usr/share/kde-window-moves/WindowMovesKeys.kksrc}"
desktop_file="${2:-/usr/share/applications/kde-window-moves.desktop}"
desktop_id="kde-window-moves.desktop"

# 1. Start/enable the ydotoold daemon for the logged-in user
systemctl --user enable --now ydotool

# 2. The user needs read/write access to /dev/uinput (udev grants this to the logged-in
#    user on most distributions, otherwise add the user to the input group)
if [ ! -w /dev/uinput ]; then
    echo "WARNING: no read/write access to /dev/uinput."
    echo "         Add the user to the input group, then log out and back in:"
    echo "             sudo usermod -aG input $USER"
fi

# 3. Give the ydotoold virtual device a Flat acceleration profile so relative moves are 1:1
#    (the physical mouse keeps its own profile)
kwriteconfig6 --file kcminputrc --group "Libinput" --group "2333" --group "6666" \
    --group "ydotoold virtual device" --key PointerAccelerationProfile 2

# Re-apply the input settings without re-login
if ! qdbus org.kde.KWin /KWin reconfigure 2>/dev/null; then
    echo "NOTE: run 'qdbus org.kde.KWin /KWin reconfigure' or re-login to apply the acceleration profile."
fi

# 4. Populate the application shortcuts from the exported key set
#    (WindowMovesKeys.kksrc as exported from System Settings > Shortcuts)

# Translate a QKeySequence string like Ctrl+Shift+Left into the Qt key code
# (Qt::Key | Qt::KeyboardModifiers) that the KGlobalAccel D-Bus API expects
key_to_int() {
    local seq="$1" label="$2" part mods code name
    local -A mod_map=([ctrl]=0x04000000 [control]=0x04000000 [shift]=0x02000000 \
        [alt]=0x08000000 [meta]=0x10000000 [win]=0x10000000)
    local -A key_map=([left]=0x01000012 [up]=0x01000013 [right]=0x01000014 [down]=0x01000015 \
        [return]=0x01000004 [enter]=0x01000005 [space]=0x20 [tab]=0x01000001 \
        [escape]=0x01000000 [backspace]=0x01000003 [insert]=0x01000006 [delete]=0x01000007 \
        [home]=0x01000010 [end]=0x01000011 [pageup]=0x01000016 [pagedown]=0x01000017 \
        [print]=0x01000009)
    local -a parts=() codes=()
    while [[ $seq == *", "* ]]; do # multi-key sequences are comma separated
        parts+=("${seq%%, *}")
        seq=${seq#*, }
    done
    parts+=("$seq")
    for part in "${parts[@]}"; do
        mods=0
        while [[ $part == *"+"* ]]; do
            name=${part%%+*}
            part=${part#*+}
            name=${name,,}
            if [[ -n $name && -n ${mod_map[$name]:-} ]]; then
                mods=$((mods | ${mod_map[$name]}))
            else
                echo "WARNING: unsupported modifier '$name' in shortcut '$label'." >&2
                return 1
            fi
        done
        name=${part,,}
        if [[ -n ${key_map[$name]:-} ]]; then
            code=${key_map[$name]}
        elif [[ $name =~ ^f([0-9]+)$ ]] && ((BASH_REMATCH[1] >= 1 && BASH_REMATCH[1] <= 24)); then
            code=$((0x01000030 + BASH_REMATCH[1] - 1))
        elif [[ ${#name} -eq 1 ]]; then
            code=$(printf '%d' "'${part^^}") # printable characters use their (uppercase) ASCII code
        else
            echo "WARNING: unsupported key '$part' in shortcut '$label'." >&2
            return 1
        fi
        codes+=($((mods | code)))
    done
    local IFS=,
    echo "${codes[*]}"
}

declare -A shortcut_for=()
if [ ! -r "$kksrc" ]; then
    echo "WARNING: $kksrc not found - assign the shortcuts manually via System Settings > Shortcuts."
else
    # The action the application itself runs (Exec=window-moves.sh moveC) becomes the _launch shortcut
    launch_action=$(sed -n 's/^Exec=window-moves\.sh \([^ ;]\{1,\}\).*/\1/p' "$desktop_file" | head -n 1)

    # Map the shortcuts in the .kksrc to action names. Two forms are recognised:
    # custom commands ([Custom Commands][id] Exec=window-moves.sh <action>, keyed
    # by _launch in [id][Global Shortcuts]) and a direct export of the
    # application's shortcuts ([kde-window-moves.desktop][Global Shortcuts],
    # keyed by action name)
    declare -A exec_for=() key_for=()
    section_id=""
    in_shortcuts=""
    while IFS= read -r line; do
        line=${line%$'\r'}
        case $line in
            "[Custom Commands]["*"]")
                section_id=${line#"[Custom Commands]["}
                section_id=${section_id%"]"}
                in_shortcuts=""
                ;;
            "["*"][Global Shortcuts]")
                section_id=${line%"][Global Shortcuts]"}
                section_id=${section_id#"["}
                in_shortcuts=1
                ;;
            "["*"]")
                section_id=""
                in_shortcuts=""
                ;;
            Exec=*) [ -n "$section_id" ] && exec_for[$section_id]=${line#Exec=} ;;
            *=*) [ -n "$in_shortcuts" ] && key_for["$section_id:${line%%=*}"]=${line#*=} ;;
        esac
    done < "$kksrc"
    for entry in "${!key_for[@]}"; do
        id=${entry%:*}
        name=${entry#*:}
        exec_cmd=${exec_for[$id]:-}
        if [[ $exec_cmd == "window-moves.sh "* ]]; then
            [ "$name" = "_launch" ] || continue
            action=${exec_cmd##* }
            [ "$action" = "$launch_action" ] && action="_launch"
        elif [[ $id == *"$desktop_id" ]]; then
            [[ $name == _* && $name != _launch ]] && continue
            action=$name
        else
            continue
        fi
        shortcut_for[$action]=${key_for[$entry]}
    done

    # Apply the shortcuts to the running session through the KGlobalAccel D-Bus
    # API (the same path System Settings uses); the daemon persists them itself
    if command -v gdbus >/dev/null 2>&1 && qdbus org.kde.kglobalaccel /kglobalaccel >/dev/null 2>&1; then
        sleep 1 # let ksycoca propagate the new desktop file to the daemon
        gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
            --method org.kde.KGlobalAccel.doRegister \
            "['$desktop_id','_launch','KDE Window Moves','Launch']" >/dev/null || true
        applied=0
        for action in "${!shortcut_for[@]}"; do
            if int=$(key_to_int "${shortcut_for[$action]}" "$action"); then
                if gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
                    --method org.kde.KGlobalAccel.setForeignShortcut \
                    "['$desktop_id','$action','KDE Window Moves','']" "[$int]" >/dev/null; then
                    applied=$((applied + 1))
                else
                    echo "WARNING: could not apply the $action shortcut to the running session." >&2
                fi
            fi
        done
        echo "Applied $applied shortcuts to the running session."
    else
        echo "NOTE: kglobalaccel is not reachable - shortcuts activate at the next login."
    fi

    # Record the keys in kglobalshortcutsrc as well, so they are picked up by
    # kglobalaccel at startup even without the live registration (multi-key
    # sequences are stored tab separated)
    for action in "${!shortcut_for[@]}"; do
        key=${shortcut_for[$action]}
        kwriteconfig6 --file kglobalshortcutsrc --group services --group "$desktop_id" \
            --key "$action" "${key//, /$'\t'}"
    done
fi

echo "ydotool configured."
if [ "${#shortcut_for[@]}" -gt 0 ]; then
    echo "Registered 'KDE Window Moves' with ${#shortcut_for[@]} application shortcuts."
else
    echo "Assign the 'KDE Window Moves' shortcuts via System Settings > Shortcuts."
fi
