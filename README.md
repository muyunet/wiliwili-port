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

部分设备可能出现按键失灵或映射错乱的情况。

暂时比较难修

错乱时一般情况 `x` 为确认，`L1` 为取消

---

## 按键映射（可能不正常）

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

### Incorrect key mappings

Some devices may experience non-responsive or incorrectly mapped buttons.

Hard to fix at the moment.

When mappings are wrong, `x` usually acts as confirm and `L1` as cancel.

---

## Controls (may not work correctly)

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

---

## Credits

Thanks to [xfangfang](https://github.com/xfangfang) for creating wiliwili as open-source software under the GPL-3.0 license!

