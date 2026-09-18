<div align="center">

# 🥩 Butcher Burst

**One key. Hundreds of altar clicks in a tenth of a second.**

Built for Diablo IV altars. Record so far: **25 Butchers on screen at once.**

![Windows 10 | 11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6)
![Install](https://img.shields.io/badge/install-none-2ea44f)
![Diablo IV](https://img.shields.io/badge/Diablo%20IV-altar%20spam-8B0000)

</div>

---

## ⚡ Quick start

No GitHub account or coding needed.

1. Click the green **`<> Code`** button near the top of this page, then **Download ZIP** at the bottom of the menu
2. Open your **Downloads** folder, right-click **`auto_click-main.zip`** and choose **Extract All…** → **Extract**
3. In the window that opens, go into the **`auto_click-main`** folder and double-click **`clicker.bat`** (it may show as just **clicker** with a gear icon)
4. A small black window opens and says **Ready**. Leave it open while you play
5. In game, put your cursor on the altar and press **F6**
6. Press **F7** (or close the small window) when you're done

> **Blue "Windows protected your PC" box?** Windows shows this for any downloaded file that isn't from a big publisher. Click **More info**, then **Run anyway**.

Nothing gets installed and no system settings change. It runs on the PowerShell already built into Windows. To uninstall, delete the folder and the zip.

## 🎛️ Tweaking the count

Open `clicker.bat` in Notepad (right-click → **Edit**) and change the `SETTINGS` block at the top:

| Setting | Default | What it does |
|:--|:--:|:--|
| `$Clicks` | `450` | Clicks per burst. **This is the main knob.** |
| `$DurationMs` | `100` | How long each burst lasts, in milliseconds |
| `$BurstKey` | `F6` | Fires a burst (reserved system-wide while running) |
| `$QuitKey` | `F7` | Closes the clicker |

Save, close the clicker window, and double-click it again. Settings are only read at startup.

## 🧊 Finding your sweet spot

More clicks does **not** mean more Butchers. Push too many and the game freezes, and **when it freezes, the spawns don't come through**. You want the highest count that causes **no freeze at all**.

- **450** is the sweet spot on the machine this was built on. Yours may be a bit different
- Game hitches or freezes? Drop `$Clicks` by **50**
- Perfectly smooth? Raise it by **25** until it hitches, then go back one step
- `$DurationMs` controls how tightly the clicks are packed. Longer is gentler on the game, so test changes to it the same way

## 🛡️ Built-in safety

- Won't fire over the desktop, taskbar, File Explorer or console windows
- A burst stops instantly if your cursor leaves the game window or another window pops up
- Holding or mashing F6 won't stack bursts
- Each click is a single press-and-release, so your mouse button can never get stuck down

## 🔧 Troubleshooting

- **Nothing happens in game:** if you run Battle.net or Diablo IV as administrator, run `clicker.bat` as administrator too
- **"Could not grab the burst key":** another program, or a second copy of the clicker, is using F6. Close it or change `$BurstKey`

## ⚠️ Disclaimer

Automating input in an online game may break Blizzard's terms of use. Use at your own risk.