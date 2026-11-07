# Finnish Multilingual Extension
## ⬇️ Installation
### Quick installation script:
Run either of the following commands in PowerShell (find it via start menu + searching "PowerShell") to quickly install either extension. **Windows 10 or 11 are required.**

The scripts install AutoHotkey, the extensions in itself and ask whether the user wants the extensions to be started on PC startup.
> [!NOTE]
> These scripts run entirely in user-space and do not require admin permissions. However, they will automatically install or update AutoHotkey v2 to the latest version via WinGet.
> That means they can possibly overwrite an AutoHotkey installation (if you already have it installed).
#### The standard extended layout (SFS 5966:2019)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/aallonpituus/Finnish-Multilingual-Extension/refs/heads/main/installers/Install_Finnish-Multilingual-Extension_SFS_5966_2019.ps1 | iex"
```
#### The custom extended layout with cool features
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/aallonpituus/Finnish-Multilingual-Extension/refs/heads/main/installers/Install_Finnish-Multilingual-Extension_Custom.ps1 | iex"
```
> [!NOTE]
> **If you do not know which one to pick**, read more about what each one does in the "What does this project do?" section below.
### Manual installation:
#### Prerequisites
These extensions require [AutoHotkey v2](https://www.autohotkey.com/) to run.
#### Download the extension of your choice
Pick which extension is to your liking from the repo's file tree and download it.
#### Execute your script to use it
Double-click or otherwise execute your script to begin to use it.
#### Make it start on computer startup (optional)
Press Windows + R and type `shell:startup` and drag a shortcut to the extension into the folder that appeared.
## 🤔 What does this project do?
This project provides two Windows (implemented via AutoHotkey v2) keyboard extensions for the Finnish standard (ISO105) keyboard to add more functionalities than the standard provides on its own.
They will be explained in more detail below.
### The standard-abiding extension
The `Finnish-Multilingual-Extension_SFS_5966_2019.ahk` extension amends your default keyboard layout (ISO105) into a faithful multilingual layout, which follows the [SFS 5966:2019](https://fi.wikipedia.org/wiki/SFS_5966) standard.

The expanded keyboard layout is as the following image displays:

<img width="1920" height="640" alt="image" src="https://github.com/user-attachments/assets/a4d42213-d63f-45e6-aafa-a21204d8df9b" />

### The custom extension
The `Finnish-Multilingual-Extension_Custom.ahk` extension adds a bunch of pretty sick stuff, i.e. even more glyphs on top of the SFS 5966:2019 standard and the ability to write superscript, subscript and fractions with just your keyboard.

Here is the full list of every glyph and feature the custom extension adds:
| Modifiers   | Base key | Result |
|-------------|----------|--------|
| AltGr       | 1        | ≠      |
| AltGr+Shift | 7        | √      |
| AltGr+Shift | 8        | ⟨      |
| AltGr+Shift | 9        | ⟩      |
| AltGr       | Q        | π      |
| AltGr+Shift | Q        | θ      |
| AltGr       | W        | ω      |
| AltGr+Shift | W        | ₩      |
| AltGr+Shift | E        | Σ      |
| AltGr       | R        | ®      |
| AltGr+Shift | R        | ₽      |
| AltGr       | Y        | Ω      |
| AltGr+Shift | Y        | ¥      |
| AltGr       | U        | ÷      |
| AltGr+Shift | U        | ™      |
| AltGr+Shift | I        | ∞      |
| AltGr+Shift | A        | Ə      |
| AltGr       | F        | φ      |
| AltGr+Shift | F        | Φ      |
| AltGr       | G        | γ      |
| AltGr+Shift | G        | Γ      |
| AltGr       | H        | ±      |
| AltGr+Shift | H        | ≈      |
| AltGr       | J        | ≤      |
| AltGr+Shift | J        | ≥      |
| AltGr+Shift | L        | ₺      |
| AltGr       | C        | ¢      |
| AltGr+Shift | C        | ©      |
| AltGr       | V        | δ      |
| AltGr+Shift | V        | Δ      |
| AltGr       | B        | β      |
| AltGr+Shift | B        | ₿      |

It also adds three new functionalities which allow you to create mathematical notations with just your keyboard:
1. `AltGr + Shift + K` -> Subscript mode
   Turns any digits into superscript (e.g., ¹²) until you press any non-digit key on the keyboard.
2. `AltGr + Shift + §` -> Superscript mode
   Turns any digits into subscript (e.g., ₅₇) until you press any non-digit key on the keyboard
3. `AltGr + Shift + <` -> Fraction function
   * Functions via two input modes. After the first of the bind, you shall press any digits (as many as you like) to input the numerator.
   * After you're done, you shall press any variant of the < key again (<, >, |, `AltGr + Shift + <`).
   * This begins the second mode to where you can press as many digits as you wish to input the denominator.
   * After the second mode, the fraction function will stop after any non-digit key is pressed. 
   * Also, as an edge case, if the user presses any non-number key during the first input mode (numerator), it cancels the fraction generation.
   
   More technically on how it generates the fraction glyph(s):
   * It turns any fraction that has a corresponding Unicode precomposed characters into one. These have a lookup table.
   * There is a limited number of precomposed fractions. Unicode only has built-in single glyphs for common fractions, e.g., ½, ⅓, ⅔, ¼, ¾, ⅕–⅘, ⅙, ⅚, ⅛–⅞).
   * Numbers like ¹²⁄₃₇ do not exist as single characters. If that precomposed character doesn't exist, the fraction will be done via the fraction slash method.
   * Typing superscript numbers plus ⁄ (U+2044) plus subscript numbers automatically kerns them into a clean diagonal fraction in most fonts (e.g., ¹²⁄₃₇).
