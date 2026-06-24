# wiliwili - PortMaster

wiliwili 是一个开源的 B 站客户端，体验接近官方 PC 版，支持手柄/键盘操作。
本仓库为其 PortMaster 移植版，面向 aarch64 掌机设备。

---

## 安装

有两种方法：

1.手动解压 `wiliwili.zip` 然后将文件夹放入相应目录，注意Wiliwili.sh文件可能需要放到不同地方（详见你使用的系统的wiki）。（推荐）
2.将 `wiliwili.zip` 放到 SD 卡的 `ports/autoinstall/` 目录，打开PortMaster 启动即自动安装。

安装后的标准目录结构：

```
/roms/ports/wiliwili/
├── Wiliwili.sh        # 可能需要单独放到其他目录，详见你使用的系统的wiki
├── port.json
├── gameinfo.xml
├── cover.jpg
├── screenshot.jpg
└── wiliwili/
    ├── LICENSE
    ├── wiliwili
    ├── libs.aarch64/
    ├── licenses/
    └── resources/
```

## 已知问题

### 目录结构被展平

安装后可能出现`wiliwili`、`libs.aarch64/`、`resources/`、`licenses/`、`LICENSE`等文件直接出现在端口根目录而非 `wiliwili/` 子目录的情况。

**修复方式**：在端口根目录下（`/roms/ports/wiliwili/` 或你系统对应的位置）手动建立名为 `wiliwili/` 的文件夹，将 `wiliwili`、`libs.aarch64/`、`resources/`、`licenses/`、`LICENSE` 放入其中

### 按键映射错乱

部分 CFW（如 muOS）上可能出现按键映射与物理键位不一致的情况。这是由于 PortMaster 的 SDL 手柄数据库与特定 CFW 的内核驱动按键编号不完全匹配所致。

**临时缓解方式：** 在 wiliwili 设置 → 其他 → AB交叉 中切换按键映射，或自行在设备上调整。

### 视频渲染

视频播放使用 GL4ES（OpenGL→GLES2 翻译层）进行渲染。如果遇到画面异常，可尝试在 wiliwili 设置中降低画质或调整解码选项。

---

## 按键映射

| 按键 | 功能 |
|--|--|
| 方向键 / 左摇杆 | 导航 / 移动光标 |
| A | 确认 / 播放 / 暂停 |
| B | 返回 / 取消 |
| X | 选项菜单 / 字幕 / 画质 |
| Y | 开关弹幕 |
| L1 / R1 | 切换标签页 |
| L2 / R2 | 快退 / 快进 |
| SELECT + START | 退出 |

> **注意：** 部分 CFW 可能出现按键映射错乱，可在 wiliwili 设置中使用 AB交叉 开关作为临时缓解。

---

## 关于

感谢 [xfangfang](https://github.com/xfangfang) 开发 wiliwili 并以 GPL-3.0 许可证开源！

---

# wiliwili - PortMaster

wiliwili is an open-source Bilibili client with an experience similar to the official PC version. Supports gamepad/keyboard input.
This repo is a PortMaster port targeting aarch64 handheld devices.

---

## Installation

Two methods:

1. Manually extract `wiliwili.zip` and place the folder in the appropriate directory. Note that the `Wiliwili.sh` file may need to be placed elsewhere (see your system's wiki). (Recommended)
2. Place `wiliwili.zip` in the `ports/autoinstall/` directory on your SD card. PortMaster will auto-install it on launch.

Standard directory structure after installation:

```
/roms/ports/wiliwili/
├── Wiliwili.sh        # May need to be placed elsewhere; see your system's wiki
├── port.json
├── gameinfo.xml
├── cover.jpg
├── screenshot.jpg
└── wiliwili/
    ├── LICENSE
    ├── wiliwili
    ├── libs.aarch64/
    ├── licenses/
    └── resources/
```

## Known Issues

### Directory structure flattened

After installation, files like `wiliwili`, `libs.aarch64/`, `resources/`, `licenses/`, and `LICENSE` may appear directly under the port root instead of inside the `wiliwili/` subdirectory.

**Fix**: Under the port root (`/roms/ports/wiliwili/` or your system's equivalent), manually create a folder named `wiliwili/` and move `wiliwili`, `libs.aarch64/`, `resources/`, `licenses/`, and `LICENSE` into it.

### Button Layout (Nintendo vs Xbox)

### Incorrect key mappings

On some CFWs (e.g., muOS) the button mapping may not match the physical button layout. This is caused by the PortMaster SDL controller database not fully matching the kernel driver's button numbering on certain CFWs.

**Workaround:** Toggle ABXY swap in wiliwili Settings → Others → AB交叉, or adjust mappings on your device manually.

### Video Rendering

Video playback uses GL4ES (OpenGL→GLES2 translation layer) for rendering. If you encounter visual artifacts, try lowering the video quality or adjusting decoder settings in the wiliwili preferences.

---

## Controls

| Button | Action |
|--|--|
| D-pad / Left Analog | Navigate / Move Cursor |
| A | Confirm / Play / Pause |
| B | Back / Cancel |
| X | Options / Subtitles / Quality |
| Y | Toggle Danmaku |
| L1 / R1 | Switch Tabs |
| L2 / R2 | Skip Backward / Forward |
| SELECT + START | Exit |

> **Note:** Some CFWs may have incorrect button mappings. Use the in-app ABXY swap setting as a workaround.

---

## Credits

Thanks to [xfangfang](https://github.com/xfangfang) for creating wiliwili as open-source software under the GPL-3.0 license!

