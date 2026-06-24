#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR=/$directory/ports/wiliwili
CONFDIR="$GAMEDIR/conf"
mkdir -p "$CONFDIR"
cd $GAMEDIR/wiliwili

> "$GAMEDIR/log.txt" && exec > >(tee -a "$GAMEDIR/log.txt") 2>&1

export XDG_CONFIG_HOME="$CONFDIR"
export XDG_DATA_HOME="$CONFDIR"
export HOME="$GAMEDIR"
GAME_LIBS="$GAMEDIR/wiliwili/libs.${DEVICE_ARCH}"

# ── GL4ES configuration (PortMaster standard) ──
if [ -f "${controlfolder}/libgl_${CFW_NAME}.txt" ]; then
    source "${controlfolder}/libgl_${CFW_NAME}.txt"
else
    source "${controlfolder}/libgl_default.txt"
fi
: "${LIBGL_ES:=2}"
: "${LIBGL_GL:=21}"
: "${LIBGL_FB:=4}"

# ── Mount Weston runtime ──
weston_dir=/tmp/weston
$ESUDO mkdir -p "${weston_dir}"
weston_runtime="weston_pkg_0.2"

if [ ! -f "$controlfolder/libs/${weston_runtime}.squashfs" ]; then
  if [ ! -f "$controlfolder/harbourmaster" ]; then
    pm_message "This port requires the latest PortMaster to run, please go to https://portmaster.games/ for more info."
    sleep 5
    exit 1
  fi
  $ESUDO $controlfolder/harbourmaster --quiet --no-check runtime_check "${weston_runtime}.squashfs"
fi

if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "${weston_dir}"
fi
$ESUDO mount "$controlfolder/libs/${weston_runtime}.squashfs" "${weston_dir}"

pm_platform_helper "wiliwili"

# ── Launch ──
$ESUDO env \
    CRUSTY_RESOLUTION="${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}" \
    CRUSTY_SHOW_CURSOR=0 \
    WESTON_HEADLESS_WIDTH="$DISPLAY_WIDTH" \
    WESTON_HEADLESS_HEIGHT="$DISPLAY_HEIGHT" \
    WESTON_KIOSK_NO_RESIZE=0 \
    WRAPPED_LIBRARY_PATH="${GAME_LIBS}" \
    "$weston_dir/westonwrap.sh" \
        headless noop kiosk crusty_glx_gl4es \
        WAYLAND_DISPLAY= \
        LIBGL_ES="$LIBGL_ES" \
        LIBGL_GL="$LIBGL_GL" \
        LIBGL_FB="$LIBGL_FB" \
        LIBGL_DEFAULTWRAP=0 \
        LIBGL_FORCENPOT=1 \
        SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" \
        ./wiliwili

$ESUDO $weston_dir/westonwrap.sh cleanup
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "${weston_dir}"
fi

pm_finish
