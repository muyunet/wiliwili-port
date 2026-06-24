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
# PortMaster's get_controls (called above) provides mappings for 40+ devices.
# However, on some CFW/driver combinations the mapping GUID matches but the
# evdev button indices differ.  As a universal fallback, we build a correct
# mapping directly from the kernel input device's key capability bitmap.
# Kernel key codes are standardised across all Linux drivers, so this works
# on ANY handheld without per-device hardcoding.
#
# SDL2 evdev assigns joystick button indices by scanning key bits from
# BTN_MISC (0x100 = 256) upward.  We mirror that scan to compute the exact
# index SDL2 will use for each gamepad button code.

build_evdev_mapping() {
    local dev="" guid="" name="" keymap="" hexbyte byte_idx bit_idx
    local code idx=0

    # ── Find the first joystick-capable event device ──
    for dev in /dev/input/event*; do
        [ -e "$dev" ] || continue
        local SYSBASE="/sys/class/input/$(basename "$dev")/device"
        [ -r "${SYSBASE}/capabilities/key" ] || continue
        [ -r "${SYSBASE}/capabilities/ev" ] || continue

        # Check for EV_ABS (bit 3 in byte 0 of ev bitmap)
        local evmap=$(xxd -p "${SYSBASE}/capabilities/ev" 2>/dev/null | tr -d '\n')
        evbyte=${evmap:0:2}
        [ -z "$evbyte" ] && continue
        [ $(( (0x$evbyte >> 3) & 1 )) -ne 1 ] && continue

        # ── Read device identity ──
        name=$(cat "${SYSBASE}/name" 2>/dev/null | tr -d '\n' | tr ',' '_')
        [ -z "$name" ] && name="Unknown"

        local BUS=$(cat "${SYSBASE}/id/bustype" 2>/dev/null | tr -d '[:space:]')
        local VEN=$(cat "${SYSBASE}/id/vendor"  2>/dev/null | tr -d '[:space:]')
        local PRD=$(cat "${SYSBASE}/id/product" 2>/dev/null | tr -d '[:space:]')
        local VER=$(cat "${SYSBASE}/id/version" 2>/dev/null | tr -d '[:space:]')
        : "${BUS:=0019}"; : "${VEN:=0001}"; : "${PRD:=0001}"; : "${VER:=0100}"

        # SDL2 evdev GUID (little-endian fields)
        guid=$(printf "%02x%02x0000%02x%02x%02x%02x%02x%02x0000000000000000" \
            $((16#$BUS & 0xFF)) $(((16#$BUS >> 8) & 0xFF)) \
            $((16#$VEN & 0xFF)) $(((16#$VEN >> 8) & 0xFF)) \
            $((16#$PRD & 0xFF)) $(((16#$PRD >> 8) & 0xFF)) \
            $((16#$VER & 0xFF)) $(((16#$VER >> 8) & 0xFF)))

        # ── Read key bitmap into memory ──
        keymap=$(xxd -p "${SYSBASE}/capabilities/key" 2>/dev/null | tr -d '\n')
        [ -z "$keymap" ] && continue

        # ── Map: SDL button name → kernel key code ──
        local -A BTN_NAME
        BTN_NAME[304]="a"  BTN_NAME[305]="b"
        BTN_NAME[307]="x"  BTN_NAME[308]="y"
        BTN_NAME[310]="leftshoulder"   BTN_NAME[311]="rightshoulder"
        BTN_NAME[312]="lefttrigger"    BTN_NAME[313]="righttrigger"
        BTN_NAME[314]="back"           BTN_NAME[315]="start"
        BTN_NAME[316]="guide"

        # ── Single pass: compute evdev index for each present button ──
        local mapping="" sdl_name
        for code in $(seq 256 320); do
            byte_idx=$((code / 8))
            hexbyte=${keymap:$((byte_idx * 2)):2}
            [ -z "$hexbyte" ] && continue
            bit_idx=$((code % 8))
            if [ $(( (0x$hexbyte >> bit_idx) & 1 )) -eq 1 ]; then
                sdl_name="${BTN_NAME[$code]}"
                if [ -n "$sdl_name" ]; then
                    mapping="${mapping}${sdl_name}:b${idx},"
                fi
                idx=$((idx + 1))
            fi
        done

        # ── Read axis capabilities ──
        local axmap="" absmap="" absbyte absbit abs_idx=0 axcode
        absmap=$(xxd -p "${SYSBASE}/capabilities/abs" 2>/dev/null | tr -d '\n')
        if [ -n "$absmap" ]; then
            for axcode in $(seq 0 63); do
                byte_idx=$((axcode / 8))
                absbyte=${absmap:$((byte_idx * 2)):2}
                [ -z "$absbyte" ] && continue
                bit_idx=$((axcode % 8))
                if [ $(( (0x$absbyte >> bit_idx) & 1 )) -eq 1 ]; then
                    case $axcode in
                        0)  axmap="${axmap}leftx:a${abs_idx},"  ;;  # ABS_X
                        1)  axmap="${axmap}lefty:a${abs_idx},"  ;;  # ABS_Y
                        3)  axmap="${axmap}rightx:a${abs_idx}," ;;  # ABS_RX
                        4)  axmap="${axmap}righty:a${abs_idx}," ;;  # ABS_RY
                    esac
                    abs_idx=$((abs_idx + 1))
                fi
            done
        fi

        # ── Assemble final config string ──
        sdl_controllerconfig="${guid},${name},${mapping}\
dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,\
${axmap}\
platform:Linux,"

        echo "Gamepad: $name ($dev) GUID=$guid idx_count=$idx ax_count=$abs_idx"
        return 0
    done
    return 1
}

# Build the mapping directly from sysfs to match SDL2 evdev button indices.
# Kernel key codes are standardised (BTN_SOUTH=304, BTN_EAST=305, etc.) so
# this works universally across ALL Linux handhelds.  PortMaster's
# get_controls (called above) targets SDL2's X11/libinput backend; its
# button indices may not match evdev order on every CFW/driver combination.
if ! build_evdev_mapping; then
    # Last-resort fallback: PortMaster mapping (if sysfs scan failed)
    echo "WARNING: evdev scan failed, trying PortMaster fallback"
    [ -z "$sdl_controllerconfig" ] && echo "ERROR: no gamepad mapping available"
fi

# Allow users to swap A↔B and X↔Y for Nintendo-layout devices.
# Create "$GAMEDIR/swap_abxy.flag" to enable this swap.
if [ -f "$GAMEDIR/swap_abxy.flag" ]; then
    sdl_controllerconfig=$(printf '%s' "$sdl_controllerconfig" | sed -E '
        s/,a:b([0-9]+),b:b([0-9]+),/,a:b\2,b:b\1,/
        s/,x:b([0-9]+),y:b([0-9]+),/,x:b\2,y:b\1,/')
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
#   SDL_JOYSTICK_DRIVER=evdev — bypass XWayland/libinput; EVIOCGRAB blocks keyboard
#                                events from dual-mode (Keyboard+Joystick) input devices,
#                                preventing borealis's keyboard fallback from overriding
#                                the correct SDL gamepad mapping
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
        SDL_JOYSTICK_DRIVER=evdev \
        SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" \
        ./wiliwili

$ESUDO $weston_dir/westonwrap.sh cleanup
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "${weston_dir}"
fi

pm_finish
