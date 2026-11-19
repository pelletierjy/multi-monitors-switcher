# multi-monitors-switcher

Handy scripts to switch Windows multi-display profiles with one click or a keyboard shortcut.

| Profile           | Description                                                                 |
| ----------------- | --------------------------------------------------------------------------- |
| **Central Only**  | Only the center monitor is on. The left and right monitors are off.         |
| **Triple Screen** | All three monitors are on, at the positions and resolutions saved by setup. |

### Shortcuts (on the desktop)

| Shortcut            | Keys         |
| ------------------- | ------------ |
| Central Screen Only | `Ctrl+Alt+1` |
| Triple Screens      | `Ctrl+Alt+3` |

## Folder contents

Installed in `C:\Tools\DisplayProfiles\`:

| File                        | Purpose                                                                         |
| --------------------------- | ------------------------------------------------------------------------------- |
| `CentralOnly.bat`           | Launcher for profile 1 (calls `CentralOnly.ps1`)                                |
| `TripleScreen.bat`          | Launcher for profile 2 (calls `TripleScreen.ps1`)                               |
| `CentralOnly.ps1`           | Turns the side monitors off, makes the center monitor primary                   |
| `TripleScreen.ps1`          | Restores the saved triple layout (`TripleScreen.cfg`)                           |
| `Setup-DisplayProfiles.ps1` | Detects monitors, saves the layout, writes `profiles.json`, creates the desktop shortcuts |
| `Common.ps1`                | Shared functions used by the scripts above                                      |
| `TripleScreen.cfg`          | Saved monitor layout (positions, resolutions, orientation)                      |
| `profiles.json`             | Detected monitor IDs and the center monitor                                     |
| `monitors-snapshot.csv`     | Last monitor query (created automatically; safe to delete)                      |
| `MultiMonitorTool\`         | NirSoft MultiMonitorTool, downloaded automatically by setup                     |

## How it works

1. Setup asks MultiMonitorTool for the connected monitors and their positions.
2. The center monitor is the one whose midpoint is closest to the midpoint of the whole display layout. Ties go to the primary monitor. You never type monitor IDs.
3. The full triple layout is saved to `TripleScreen.cfg` with MultiMonitorTool.
4. **Central Only** disables every monitor that is not the center one.
5. **Triple Screen** reloads `TripleScreen.cfg`, which turns all monitors back on at their saved positions and resolutions.

All scripts are safe to run repeatedly. Running a profile twice gives the same result.

## How to change the shortcuts

1. Right-click the desktop shortcut, choose **Properties**.
2. Click in the **Shortcut key** field and press the new key combination.
   (Windows requires `Ctrl+Alt` or `Shift+Alt` plus a key, and will not accept a bare key.)
3. Click **OK**.

To change the shortcuts permanently, edit the `Hotkey` values in the list in `Setup-DisplayProfiles.ps1` and run setup again. Setup overwrites the shortcuts.

## When you change the monitor setup

Regenerate the profiles after any of these:

- You rearranged the monitors in Windows Display Settings.
- You changed a monitor's resolution, scale, or orientation.
- You replaced or added a monitor, or moved it to another port or graphics adapter.

Steps:

1. Turn **on** all three monitors (run `TripleScreen.bat`, or press `Ctrl+Alt+3`).
2. Arrange them the way you want in Windows Display Settings.
3. Open PowerShell and run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Tools\DisplayProfiles\Setup-DisplayProfiles.ps1"
   ```

4. Check the output: the center monitor and side monitors should be the ones you expect.

If a monitor is off and setup cannot load the saved layout, it stops with a message. Turn all monitors on, then run setup again.

## Troubleshooting

- **An error box appears when a profile runs**
  The message says what is wrong. Usually the center monitor is disconnected or the saved layout no longer matches the hardware. Follow the steps above.
- **A monitor does not turn back on with `Ctrl+Alt+3`**
  Run `TripleScreen.bat` directly to see whether it shows an error. Then re-run setup with all monitors on.
- **The wrong monitor is treated as the center**
  Re-arrange the monitors in Display Settings so the intended center monitor is physically in the middle, then run setup again.
- **The shortcut keys do nothing**
  Another app or the Intel graphics software may use the same combination. Change the shortcut key in the shortcut's Properties.
- **MultiMonitorTool is missing**
  Setup downloads it from <https://www.nirsoft.net/utils/multimonitortool-x64.zip> into `MultiMonitorTool\` when the folder is missing. If the download fails (for example, no internet access), download that zip yourself and extract it into that folder.
