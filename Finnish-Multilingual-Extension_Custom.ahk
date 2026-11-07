#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
Persistent

; ============================================================================
;  A pretty sick extension that turns your keyboard into charmap and a math
;  editor
;  (i.e. A keyboard extension that is based on the SFS 5966:2019 standard
;  that adds a lot of new glyphs and functions to create superscripts,
;  subscripts and fractions)
;
;  Version: v1.0.0
;
;  Programmed by aallon-pituus in 2026.
;    
;  This extension is implemented through the AutoHotkey v2 program.
;
;  Adds the extra AltGr and AltGr+Shift characters of the Finnish
;  multilingual layout (SFS 5966:2019) on top of the standard Finnish (ISO105) 
;  layout, including dead-key diacritics and the 2019 amendments. More on the
;  fun extra features below.
;
;  Keys are bound by SCANCODE, so they follow the physical key position.
;  Characters are given as Unicode code points (the glyph is in the comment).
;
;  Notes:
;   * AltGr+5 gives ‰ (per mille), as in the standard. The default Finnish
;     AltGr+5 = € is therefore replaced; € stays on AltGr+E.
;   * Dead keys: press the dead key, then a letter. Valid combinations give
;     the accented letter (e.g. AltGr+' then s -> š). Dead key + Space gives
;     the accent on its own. Pressing Esc, Backspace, Enter, Tab, Delete,
;     arrows, Home/End or PgUp/PgDn.
;   * Invalid combinations (e.g. caron + "x" has no precomposed form):
;     accents that have a spacing form output "accent + letter", like
;     Windows does; the others (horn, hook above, dot below, comma below,
;     stroke) output just the letter, so no stray combining mark can
;     attach itself to the previous character.
;
;  CUSTOM VERSION:
;   Everything above is unchanged. On top of it, the "CustomChars" table
;   further down adds personal AltGr / AltGr+Shift bindings (Greek letters,
;   math and currency symbols, etc.).
;
;  SUBSCRIPT / SUPERSCRIPT / FRACTION MODES:
;   * AltGr+Shift+K   Subscript mode:   digits type as ₀₁₂₃…
;   * AltGr+Shift+§   Superscript mode: digits type as ⁰¹²³…
;     Both last until any non-digit key is pressed (that key then works
;     normally). Pressing the same mode key again also ends the mode;
;     pressing the other mode key switches directly to it.
;   * AltGr+Shift+<   Fraction mode:
;       1. type the numerator (digits only, nothing is shown yet)
;       2. press any variant of the < key (< > | or AltGr+Shift+<) once
;       3. type the denominator; the first non-digit key ends the mode,
;          the fraction is typed, and then that key works normally.
;     Any non-digit key during step 1 cancels the fraction (nothing is typed).
;     Fractions that exist as one Unicode character (½ ⅓ ⅔ ¼ ¾ ⅕–⅘ ⅙ ⅚ ⅐ ⅛–⅞
;     ⅑ ⅒ ↉) are typed as that character, exactly as entered (2/4 is not
;     reduced to ½). Everything else uses the fraction slash: ¹²⁄₃₇.
;   * A small tooltip shows the active mode; set ShowModeTooltip to false
;     below to turn it off.
; ============================================================================

; ----------------------------------------------------------------------------
;  State
; ----------------------------------------------------------------------------
Pending := ""      ; currently waiting dead key (object) or ""
NextId  := 0
Mode    := ""      ; active subscript / superscript / fraction mode (object) or ""

ShowModeTooltip := true   ; small tooltip near the mouse while a mode is active

; Superscript digits 0-9:  ⁰ ¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹   (subscripts are U+2080 + digit)
SupCodes := [0x2070, 0xB9, 0xB2, 0xB3, 0x2074, 0x2075, 0x2076, 0x2077, 0x2078, 0x2079]

; Fractions that exist as a single Unicode character (typed exactly as entered)
FracMap := Map(
    "1/2",  0xBD,    ; ½
    "1/3",  0x2153,  ; ⅓
    "2/3",  0x2154,  ; ⅔
    "1/4",  0xBC,    ; ¼
    "3/4",  0xBE,    ; ¾
    "1/5",  0x2155,  ; ⅕
    "2/5",  0x2156,  ; ⅖
    "3/5",  0x2157,  ; ⅗
    "4/5",  0x2158,  ; ⅘
    "1/6",  0x2159,  ; ⅙
    "5/6",  0x215A,  ; ⅚
    "1/7",  0x2150,  ; ⅐
    "1/8",  0x215B,  ; ⅛
    "3/8",  0x215C,  ; ⅜
    "5/8",  0x215D,  ; ⅝
    "7/8",  0x215E,  ; ⅞
    "1/9",  0x2151,  ; ⅑
    "1/10", 0x2152,  ; ⅒
    "0/3",  0x2189   ; ↉
)

; ----------------------------------------------------------------------------
;  Dead key definitions: name, combining mark, spacing form (0 = none),
;  optional explicit letter map (for letters Unicode can't compose)
; ----------------------------------------------------------------------------
Dead := Map()

; Stroke: Unicode has no decompositions for these, so list them explicitly.
StrokeMap := Map()
for pair in [
    ["d", 0x111, 0x110],   ; đ Đ
    ["h", 0x127, 0x126],   ; ħ Ħ
    ["l", 0x142, 0x141],   ; ł Ł
    ["o", 0xF8,  0xD8 ],   ; ø Ø
    ["t", 0x167, 0x166],   ; ŧ Ŧ
    ["b", 0x180, 0x243],   ; ƀ Ƀ
    ["g", 0x1E5, 0x1E4],   ; ǥ Ǥ
    ["i", 0x268, 0x197],   ; ɨ Ɨ
    ["j", 0x249, 0x248],   ; ɉ Ɉ
    ["z", 0x1B6, 0x1B5],   ; ƶ Ƶ
    ["e", 0x247, 0x246],   ; ɇ Ɇ
    ["r", 0x24D, 0x24C],   ; ɍ Ɍ
    ["y", 0x24F, 0x24E],   ; ɏ Ɏ
    ["u", 0x289, 0x244],   ; ʉ Ʉ
    ["a", 0x2C65, 0x23A],  ; ⱥ Ⱥ
    ["c", 0x23C, 0x23B],   ; ȼ Ȼ
    ["p", 0x1D7D, 0x2C63]  ; ᵽ Ᵽ
] {
    StrokeMap[pair[1]] := Chr(pair[2])
    StrokeMap[StrUpper(pair[1])] := Chr(pair[3])
}

; Comma below: Unicode composes s/t (Romanian ș ț) natively. The Latvian
; letters ģ ķ ļ ņ ŗ are encoded as "with cedilla" but drawn with a comma,
; so map them explicitly.
CommaMap := Map(
    "g", Chr(0x123), "G", Chr(0x122),   ; ģ Ģ
    "k", Chr(0x137), "K", Chr(0x136),   ; ķ Ķ
    "l", Chr(0x13C), "L", Chr(0x13B),   ; ļ Ļ
    "n", Chr(0x146), "N", Chr(0x145),   ; ņ Ņ
    "r", Chr(0x157), "R", Chr(0x156)    ; ŗ Ŗ
)

AddDead("stroke",      0x0335, 0,     StrokeMap)  ; d-  (combining short stroke)
AddDead("cedilla",     0x0327, 0xB8)              ; ¸
AddDead("ogonek",      0x0328, 0x2DB)             ; ˛
AddDead("horn",        0x031B, 0)                 ; ̛
AddDead("hookabove",   0x0309, 0)                 ; ̉
AddDead("doubleacute", 0x030B, 0x2DD)             ; ˝
AddDead("ringabove",   0x030A, 0x2DA)             ; ˚
AddDead("macron",      0x0304, 0xAF)              ; ¯
AddDead("caron",       0x030C, 0x2C7)             ; ˇ
AddDead("breve",       0x0306, 0x2D8)             ; ˘
AddDead("dotbelow",    0x0323, 0)                 ; ̣
AddDead("dotabove",    0x0307, 0x2D9)             ; ˙
AddDead("commabelow",  0x0326, 0,     CommaMap)   ; ̦

AddDead(name, mark, spacing, letterMap := "") {
    Dead[name] := {
        mark: Chr(mark),
        spacing: spacing ? Chr(spacing) : "",
        map: letterMap
    }
}

; ----------------------------------------------------------------------------
;  Dead key bindings:  [hotkey, dead key name]
;  "<^>!" = AltGr,  "<^>!+" = AltGr+Shift
; ----------------------------------------------------------------------------
DeadKeys := [
    ["<^>!SC029",  "stroke"],       ; AltGr+§        d-  (stroke)
    ["<^>!SC026",  "stroke"],       ; AltGr+L        d-  (stroke, duplicate)
    ["<^>!SC00D",  "cedilla"],      ; AltGr+´        ¸
    ["<^>!+SC00D", "ogonek"],       ; AltGr+Shift+´  ˛
    ["<^>!SC019",  "horn"],         ; AltGr+P        horn (Vietnamese)
    ["<^>!+SC019", "hookabove"],    ; AltGr+Shift+P  hook above (Vietnamese)
    ["<^>!SC01A",  "doubleacute"],  ; AltGr+Å        ˝   (Hungarian)
    ["<^>!+SC01A", "ringabove"],    ; AltGr+Shift+Å  ˚
    ["<^>!+SC01B", "macron"],       ; AltGr+Shift+¨  ¯
    ["<^>!SC02B",  "caron"],        ; AltGr+'        ˇ
    ["<^>!+SC02B", "breve"],        ; AltGr+Shift+'  ˘
    ["<^>!SC034",  "dotbelow"],     ; AltGr+.        dot below
    ["<^>!+SC034", "dotabove"],     ; AltGr+Shift+.  ˙
    ["<^>!+SC035", "commabelow"]    ; AltGr+Shift+-  comma below (2019)
]

for k in DeadKeys
    Hotkey(k[1], StartDead.Bind(k[2]))

; ----------------------------------------------------------------------------
;  Plain character bindings:  [scancode, AltGr char, AltGr+Shift char]
;  (0 = nothing assigned)
;  Characters already present on the default Finnish layout are omitted.
; ----------------------------------------------------------------------------
Chars := [
    ["SC002", 0,      0xA1  ],   ; 1        AltGr+Shift: ¡
    ["SC003", 0,      0x201D],   ; 2        AltGr+Shift: ”
    ["SC004", 0,      0xBB  ],   ; 3        AltGr+Shift: »
    ["SC005", 0,      0xAB  ],   ; 4        AltGr+Shift: «
    ["SC006", 0x2030, 0x201C],   ; 5        AltGr: ‰    AltGr+Shift: “
    ["SC007", 0x201A, 0x201E],   ; 6        AltGr: ‚    AltGr+Shift: „
    ["SC00B", 0,      0xB0  ],   ; 0        AltGr+Shift: °
    ["SC00C", 0,      0xBF  ],   ; +        AltGr+Shift: ¿
    ["SC014", 0xFE,   0xDE  ],   ; T        AltGr: þ    AltGr+Shift: Þ
    ["SC017", 0x131,  0     ],   ; I        AltGr: ı
    ["SC018", 0x153,  0x152 ],   ; O        AltGr: œ    AltGr+Shift: Œ
    ["SC01E", 0x259,  0     ],   ; A        AltGr: ə
    ["SC01F", 0xDF,   0x1E9E],   ; S        AltGr: ß    AltGr+Shift: ẞ (2019)
    ["SC020", 0xF0,   0xD0  ],   ; D        AltGr: ð    AltGr+Shift: Ð
    ["SC025", 0x138,  0     ],   ; K        AltGr: ĸ
    ["SC027", 0xF8,   0xD8  ],   ; Ö        AltGr: ø    AltGr+Shift: Ø
    ["SC028", 0xE6,   0xC6  ],   ; Ä        AltGr: æ    AltGr+Shift: Æ
    ["SC02C", 0x292,  0x1B7 ],   ; Z        AltGr: ʒ    AltGr+Shift: Ʒ
    ["SC02D", 0xD7,   0xB7  ],   ; X        AltGr: ×    AltGr+Shift: ·
    ["SC031", 0x14B,  0x14A ],   ; N        AltGr: ŋ    AltGr+Shift: Ŋ
    ["SC032", 0xB5,   0x2014],   ; M        AltGr: µ     AltGr+Shift: —
    ["SC033", 0x2019, 0x2018],   ; ,        AltGr: ’    AltGr+Shift: ‘
    ["SC035", 0x2013, 0     ],   ; -        AltGr: –    (AltGr+Shift is a dead key)
    ["SC039", 0xA0,   0x202F]    ; Space    AltGr: NBSP AltGr+Shift: NNBSP (2019)
]

; ----------------------------------------------------------------------------
;  CUSTOM character bindings (personal additions), same format as above:
;  [scancode, AltGr char, AltGr+Shift char]   (0 = nothing assigned)
;  None of these touch a key combination used by the standard table above.
; ----------------------------------------------------------------------------
CustomChars := [
    ["SC002", 0x2260, 0     ],   ; 1        AltGr: ≠
    ["SC008", 0,      0x221A],   ; 7        AltGr+Shift: √
    ["SC009", 0,      0x27E8],   ; 8        AltGr+Shift: ⟨
    ["SC00A", 0,      0x27E9],   ; 9        AltGr+Shift: ⟩
    ["SC010", 0x3C0,  0x3B8 ],   ; Q        AltGr: π    AltGr+Shift: θ
    ["SC011", 0x3C9,  0x20A9],   ; W        AltGr: ω    AltGr+Shift: ₩
    ["SC012", 0,      0x3A3 ],   ; E        AltGr+Shift: Σ  (AltGr+E stays €)
    ["SC013", 0xAE,   0x20BD],   ; R        AltGr: ®    AltGr+Shift: ₽
    ["SC015", 0x3A9,  0xA5  ],   ; Y        AltGr: Ω    AltGr+Shift: ¥
    ["SC016", 0xF7,   0x2122],   ; U        AltGr: ÷    AltGr+Shift: ™
    ["SC017", 0,      0x221E],   ; I        AltGr+Shift: ∞  (AltGr+I stays ı)
    ["SC01E", 0,      0x18F ],   ; A        AltGr+Shift: Ə  (AltGr+A stays ə)
    ["SC021", 0x3C6,  0x3A6 ],   ; F        AltGr: φ    AltGr+Shift: Φ
    ["SC022", 0x3B3,  0x393 ],   ; G        AltGr: γ    AltGr+Shift: Γ
    ["SC023", 0xB1,   0x2248],   ; H        AltGr: ±    AltGr+Shift: ≈
    ["SC024", 0x2264, 0x2265],   ; J        AltGr: ≤    AltGr+Shift: ≥
    ["SC026", 0,      0x20BA],   ; L        AltGr+Shift: ₺  (AltGr+L stays stroke)
    ["SC02E", 0xA2,   0xA9  ],   ; C        AltGr: ¢    AltGr+Shift: ©
    ["SC02F", 0x3B4,  0x394 ],   ; V        AltGr: δ    AltGr+Shift: Δ
    ["SC030", 0x3B2,  0x20BF]    ; B        AltGr: β    AltGr+Shift: ₿
]

for table in [Chars, CustomChars] {
    for row in table {
        if row[2]
            Hotkey("<^>!" . row[1], Emit.Bind(Chr(row[2])))
        if row[3]
            Hotkey("<^>!+" . row[1], Emit.Bind(Chr(row[3])))
    }
}

; ----------------------------------------------------------------------------
;  Subscript / superscript / fraction mode keys
; ----------------------------------------------------------------------------
Hotkey("<^>!+SC025", ScriptKey.Bind("sub"))   ; AltGr+Shift+K  subscript mode
Hotkey("<^>!+SC029", ScriptKey.Bind("sup"))   ; AltGr+Shift+§  superscript mode
Hotkey("<^>!+SC056", FractionKey)             ; AltGr+Shift+<  fraction mode

; ----------------------------------------------------------------------------
;  Functions
; ----------------------------------------------------------------------------

; Output a character. If a dead key is waiting, combine with it first.
Emit(ch, *) {
    global Pending
    EndMode()                       ; any other key press ends a script/fraction mode
    if IsObject(Pending) {
        p := Pending
        Pending := ""
        p.ih.Stop()
        ch := Resolve(p.name, ch)
    }
    SendText(ch)
}

; A dead key was pressed: wait for the next character.
StartDead(name, *) {
    global Pending, NextId
    EndMode()
    if IsObject(Pending) {
        if (Pending.name = name) {
            ; Same dead key twice -> the accent itself, twice (like Windows)
            CancelPending()
            SendText(Standalone(name) . Standalone(name))
            return
        }
        ; A different dead key: flush the previous accent on its own
        prev := Pending.name
        CancelPending()
        SendText(Standalone(prev))
    }
    NextId += 1
    ih := InputHook("L1")
    ih.EndKeys := "{Escape}{Backspace}{Enter}{Tab}{Delete}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}"
    ih.OnEnd := DeadEnded.Bind(NextId)
    Pending := {name: name, ih: ih, id: NextId}
    ih.Start()
}

; Called when the InputHook finishes (one character typed, or an end key).
DeadEnded(id, ih) {
    global Pending
    if !IsObject(Pending) || Pending.id != id
        return                      ; already handled elsewhere
    p := Pending
    Pending := ""
    if (ih.EndReason = "Max")
        SendText(Resolve(p.name, ih.Input))
    ; any other reason (Esc, Backspace, arrows, ...) just cancels the dead key
}

CancelPending(*) {
    global Pending
    if !IsObject(Pending)
        return
    p := Pending
    Pending := ""
    p.ih.Stop()
}

; Accent on its own (dead key + Space, or dead key pressed twice)
Standalone(name) {
    d := Dead[name]
    return d.spacing != "" ? d.spacing : d.mark
}

; Combine dead key `name` with typed character `ch`.
Resolve(name, ch) {
    d := Dead[name]
    if (ch = " ")
        return Standalone(name)
    out := Compose(d, ch)
    if (out != "")
        return out
    ; Not a valid combination: spacing accents behave like Windows
    ; (accent + letter); marks without a spacing form just give the letter.
    return d.spacing . ch
}

; Returns the single precomposed character, or "" if there is none.
Compose(d, ch) {
    if (StrLen(ch) != 1)
        return ""
    if IsObject(d.map) && d.map.Has(ch)
        return d.map[ch]
    ; Unicode NFC normalisation composes e.g. "e" + U+0301 -> "é".
    ; If the result is still two code units, the letter doesn't take that accent.
    buf := Buffer(64, 0)
    n := DllCall("Normaliz.dll\NormalizeString"
        , "Int", 1                 ; NormalizationC
        , "Str", ch . d.mark
        , "Int", -1
        , "Ptr", buf
        , "Int", 32
        , "Int")
    if (n <= 0)
        return ""
    res := StrGet(buf, "UTF-16")
    return StrLen(res) = 1 ? res : ""
}

; ----------------------------------------------------------------------------
;  Subscript / superscript / fraction modes
; ----------------------------------------------------------------------------

; AltGr+Shift+K (sub) / AltGr+Shift+§ (sup)
ScriptKey(kind, *) {
    global Mode
    CancelPending()
    if IsObject(Mode) && Mode.kind = kind {
        EndMode()                   ; same key again: switch the mode off
        return
    }
    EndMode()                       ; the other mode key: switch directly
    BeginMode(kind)
}

; AltGr+Shift+<
FractionKey(*) {
    global Mode
    CancelPending()
    if IsObject(Mode) && Mode.kind = "frac" {
        if (Mode.phase = 1 && Mode.num != "") {
            Mode.phase := 2         ; numerator done -> denominator
            ShowTip()
            return
        }
        EndMode()                   ; empty numerator: cancel; denominator: finish
        return
    }
    EndMode()
    BeginMode("frac")
}

BeginMode(kind) {
    global Mode, NextId
    NextId += 1
    ih := InputHook("I")            ; I: ignore text we send ourselves
    ih.BackspaceIsUndo := false
    ; Non-text keys end the mode. They are blocked and re-sent afterwards, so
    ; that a finished fraction is typed *before* e.g. Enter takes effect.
    ih.KeyOpt("{Escape}{Backspace}{Enter}{Tab}{Delete}{Insert}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}", "+E+S")
    ih.OnChar := ModeChar.Bind(NextId)
    ih.OnEnd := ModeEnded.Bind(NextId)
    Mode := {kind: kind, phase: 1, num: "", den: "", ih: ih, id: NextId}
    ih.Start()
    ShowTip()
}

; Ends the active mode (typing a finished fraction if there is one).
EndMode(*) {
    global Mode
    if !IsObject(Mode)
        return
    m := Mode
    Mode := ""
    m.ih.Stop()
    HideTip()
    FinishFraction(m)
}

; A character was typed while a mode is active.
ModeChar(id, ih, ch) {
    global Mode
    Critical
    if !IsObject(Mode) || Mode.id != id
        return
    m := Mode
    if (StrLen(ch) = 1 && InStr("0123456789", ch)) {
        if (m.kind = "sub")
            SendText(ToSub(ch))
        else if (m.kind = "sup")
            SendText(ToSup(ch))
        else {
            if (m.phase = 1)
                m.num .= ch
            else
                m.den .= ch
            ShowTip()
        }
        return
    }
    ; Any variant of the < key (< > |) moves from numerator to denominator
    if (m.kind = "frac" && m.phase = 1 && m.num != "" && StrLen(ch) = 1 && InStr("<>|", ch)) {
        m.phase := 2
        ShowTip()
        return
    }
    ; Any other character ends the mode; the key itself still works normally.
    Mode := ""
    ih.Stop()
    HideTip()
    FinishFraction(m)
    SendText(ch)
}

; A non-text key (Enter, arrows, Esc, ...) ended the input.
ModeEnded(id, ih) {
    global Mode
    Critical
    if !IsObject(Mode) || Mode.id != id
        return
    m := Mode
    Mode := ""
    HideTip()
    if (ih.EndReason != "EndKey")
        return
    FinishFraction(m)
    Send("{Blind}{" . ih.EndKey . "}")
}

; Types the fraction if both parts were entered (otherwise nothing: cancelled).
FinishFraction(m) {
    if (m.kind = "frac" && m.phase = 2 && m.num != "" && m.den != "")
        SendText(FractionText(m.num, m.den))
}

; Precomposed character if one exists, otherwise ¹²⁄₃₇ style (fraction slash).
FractionText(num, den) {
    key := num . "/" . den
    if FracMap.Has(key)
        return Chr(FracMap[key])
    return ToSup(num) . Chr(0x2044) . ToSub(den)
}

ToSub(digits) {
    out := ""
    for d in StrSplit(digits)
        out .= Chr(0x2080 + Integer(d))
    return out
}

ToSup(digits) {
    out := ""
    for d in StrSplit(digits)
        out .= Chr(SupCodes[Integer(d) + 1])
    return out
}

ShowTip() {
    global Mode, ShowModeTooltip
    if !ShowModeTooltip || !IsObject(Mode)
        return
    if (Mode.kind = "sub")
        txt := "Subscript mode"
    else if (Mode.kind = "sup")
        txt := "Superscript mode"
    else if (Mode.phase = 1)
        txt := "Fraction: " . Mode.num . "_  (numerator)"
    else
        txt := "Fraction: " . Mode.num . " / " . Mode.den . "_  (denominator)"
    ToolTip(txt)
}

HideTip() {
    ToolTip()
}
