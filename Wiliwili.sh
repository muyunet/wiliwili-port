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

# ── Detect gamepad and build SDL2 mapping from sysfs ──
KEY_BM=()
key_load() {
    KEY_BM=()
    local token
    for token in $(cat "$1" 2>/dev/null | tr -d '\n'); do
        KEY_BM=("$token" "${KEY_BM[@]}")
    done
}
key_isset() {
    local code=$1 wi=$(( code / 64 )) val
    [ "$wi" -ge "${#KEY_BM[@]}" ] && return 1
    val="${KEY_BM[$wi]}"
    (( (16#$val >> (code % 64)) & 1 ))
}

detect_gamepad() {
    GC_CONFIG=""
    for dev in /dev/input/event*; do
        [ -e "$dev" ] || continue
        local SYSBASE="/sys/class/input/$(basename "$dev")/device"

        key_load "${SYSBASE}/capabilities/ev"
        key_isset 3 || continue  # need EV_ABS

        key_load "${SYSBASE}/capabilities/key"
        local has_btn=0 code=304
        while [ "$code" -le 319 ]; do
            if key_isset "$code"; then has_btn=1; break; fi
            code=$((code + 1))
        done
        [ "$has_btn" -eq 0 ] && continue

        local NAME=$(cat "${SYSBASE}/name" 2>/dev/null)
        local IDBASE="${SYSBASE}/id"
        local BUS=$(cat "${IDBASE}/bustype" 2>/dev/null | tr -d '[:space:]')
        local VEN=$(cat "${IDBASE}/vendor"  2>/dev/null | tr -d '[:space:]')
        local PRD=$(cat "${IDBASE}/product" 2>/dev/null | tr -d '[:space:]')
        : "${BUS:=0019}"; : "${VEN:=0001}"; : "${PRD:=0001}"

        local B0=$(printf "%02x" $((16#$BUS & 0xFF)))
        local B1=$(printf "%02x" $(((16#$BUS >> 8) & 0xFF)))
        local V0=$(printf "%02x" $((16#$VEN & 0xFF)))
        local V1=$(printf "%02x" $(((16#$VEN >> 8) & 0xFF)))
        local P0=$(printf "%02x" $((16#$PRD & 0xFF)))
        local P1=$(printf "%02x" $(((16#$PRD >> 8) & 0xFF)))
        local GUID="${B0}${B1}0000${V0}${V1}${P0}${P1}0000000000000000"

        local idx=0 c=304 a_idx b_idx x_idx y_idx l1_idx r1_idx l2_idx r2_idx
        local back_idx start_idx guide_idx
        while [ "$c" -le 319 ]; do
            if key_isset "$c"; then
                case $c in
                    304) a_idx=$idx ;; 305) b_idx=$idx ;;
                    307) x_idx=$idx ;; 308) y_idx=$idx ;;
                    310) l1_idx=$idx ;; 311) r1_idx=$idx ;;
                    312) l2_idx=$idx ;; 313) r2_idx=$idx ;;
                    314) back_idx=$idx ;; 315) start_idx=$idx ;;
                    316) guide_idx=$idx ;;
                esac
                idx=$((idx + 1))
            fi
            c=$((c + 1))
        done

        GC_CONFIG="${GUID},${NAME},"
        [ -n "$a_idx" ]     && GC_CONFIG="${GC_CONFIG}a:b${a_idx},"
        [ -n "$b_idx" ]     && GC_CONFIG="${GC_CONFIG}b:b${b_idx},"
        [ -n "$x_idx" ]     && GC_CONFIG="${GC_CONFIG}x:b${x_idx},"
        [ -n "$y_idx" ]     && GC_CONFIG="${GC_CONFIG}y:b${y_idx},"
        [ -n "$l1_idx" ]    && GC_CONFIG="${GC_CONFIG}leftshoulder:b${l1_idx},"
        [ -n "$r1_idx" ]    && GC_CONFIG="${GC_CONFIG}rightshoulder:b${r1_idx},"
        [ -n "$l2_idx" ]    && GC_CONFIG="${GC_CONFIG}lefttrigger:b${l2_idx},"
        [ -n "$r2_idx" ]    && GC_CONFIG="${GC_CONFIG}righttrigger:b${r2_idx},"
        [ -n "$back_idx" ]  && GC_CONFIG="${GC_CONFIG}back:b${back_idx},"
        [ -n "$start_idx" ] && GC_CONFIG="${GC_CONFIG}start:b${start_idx},"
        [ -n "$guide_idx" ] && GC_CONFIG="${GC_CONFIG}guide:b${guide_idx},"
        GC_CONFIG="${GC_CONFIG}\
dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,\
leftx:a0,lefty:a1,\
platform:Linux,"

        echo "Gamepad: $NAME ($dev) GUID=$GUID"
        return 0
    done
    return 1
}

detect_gamepad || echo "WARNING: no gamepad found"

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
        LIBGL_ES=2 \
        LIBGL_GL=21 \
        LIBGL_FB=4 \
        SDL_GAMECONTROLLERCONFIG="${GC_CONFIG}" \
        ./wiliwili

$ESUDO $weston_dir/westonwrap.sh cleanup
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
    $ESUDO umount "${weston_dir}"
fi

pm_finish
