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

# ── Controller configuration ──
# Use PortMaster's built-in gamepad detection (get_controls from control.txt)
# which provides the correct SDL_GAMECONTROLLERCONFIG for 40+ supported devices.
# This replaces the previous custom sysfs scanning approach.

# Allow users to swap A↔B and X↔Y for Nintendo-layout devices.
# Create "$GAMEDIR/swap_abxy.flag" to enable this swap.
if [ -f "$GAMEDIR/swap_abxy.flag" ]; then
    sdl_controllerconfig=$(printf '%s' "$sdl_controllerconfig" | sed -E '
        s/,a:b([0-9]+),b:b([0-9]+),/,a:b\2,b:b\1,/
        s/,x:b([0-9]+),y:b([0-9]+),/,x:b\2,y:b\1,/')
fi

# Fallback: if get_controls produced no mapping, provide a sane generic mapping
# with standard Xbox-style button layout.
if [ -z "$sdl_controllerconfig" ]; then
    sdl_controllerconfig="05000000ffffffffffffffffffffffff,Generic Gamepad,platform:Linux,a:b0,b:b1,x:b3,y:b2,back:b10,start:b9,guide:b11,leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,rightx:a2,righty:a3,"
    echo "WARNING: using fallback gamepad mapping"
fi

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

# Kill gptokeyb — this port uses native SDL2 gamepad support.
# gptokeyb translates gamepad → keyboard events, causing double-input
# chaos when both streams reach borealis's keyboard fallback path.
$ESUDO kill -9 $(pidof gptokeyb) 2>/dev/null

# ── Launch ──
# GL4ES (OpenGL→GLES2) configuration:
#   LIBGL_ES=2        — use GLES 2.0 backend
#   LIBGL_GL=21       — expose desktop OpenGL 2.1
#   LIBGL_FB=4        — PortMaster framebuffer mode (forces texture color attachment)
#   LIBGL_DEFAULTWRAP=0 — force GL_REPEAT; fixes chroma-sampling skew with NPOT video textures
#   LIBGL_FORCENPOT=1   — enable full non-power-of-two texture support for video frames
# If video rendering issues persist, try adding: LIBGL_NOXJIT=1 LIBGL_FBOUNBIND=1
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
        LIBGL_ES=2 \
        LIBGL_GL=21 \
        LIBGL_FB=4 \
        LIBGL_DEFAULTWRAP=0 \
        LIBGL_FORCENPOT=1 \
        SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" \
        ./wiliwili

$ESUDO $weston_dir/westonwrap.sh cleanup
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "${weston_dir}"
fi

pm_finish
