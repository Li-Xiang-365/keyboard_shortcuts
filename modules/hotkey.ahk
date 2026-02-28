; =========================
; 快捷键录入和绑定功能
; =========================

global capturedHotkey := ""  ; 存储捕获到的热键

; 录入快捷键（支持组合键）
CaptureHotkey(prompt := "请按下要绑定的快捷键（支持组合键，Esc取消）") {
    g := Gui("+AlwaysOnTop +ToolWindow", "录入快捷键")
    g.SetFont("s10", "Microsoft YaHei UI")
    g.Add("Text", "w320", prompt)
    g.Add("Text", "w320 cGray", "示例：F1 / ^+F2 (Ctrl+Shift+F2) / !#K (Alt+Win+K)")
    g.Add("Text", "w320 cBlue", "正在监听按键...")
    g.Show("AutoSize Center")

    global capturedHotkey := ""

    ; 持续监听，直到用户按下非修饰键
    while (true) {
        ; ESC 取消
        if GetKeyState("Escape", "P") {
            g.Destroy()
            return ""
        }

        ; 检测当前修饰键状态
        mods := ""
        if GetKeyState("LCtrl", "P") || GetKeyState("RCtrl", "P")
            mods .= "^"
        if GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P")
            mods .= "!"
        if GetKeyState("LShift", "P") || GetKeyState("RShift", "P")
            mods .= "+"
        if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
            mods .= "#"

        ; 检测非修饰键（除了 ESC）
        keys := ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
                 "0","1","2","3","4","5","6","7","8","9",
                 "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
                 "Space","Enter","Tab","Backspace","Insert","Delete","Home","End",
                 "PgUp","PgDn","Up","Down","Left","Right",
                 "-","=","[","]",";","'",",",".","/"]

        for key in keys {
            if GetKeyState(key, "P") {
                g.Destroy()
                ; 转换字母为大写
                if (StrLen(key) = 1)
                    key := StrUpper(key)
                capturedHotkey := mods . key
                return capturedHotkey
            }
        }

        Sleep 10
    }
}

; 绑定热键
BindHotkey(hk) {
    global isBound
    try {
        ; 调试：显示正在绑定的热键
        ToolTip "绑定热键：" . hk, 20, 20
        SetTimer () => ToolTip(), -2000

        Hotkey hk, (*) => PerformClick(hk), "On"
        isBound[hk] := true
    } catch as Err {
        MsgBox("快捷键无效或冲突：" . hk . "`n错误信息：" . Err.Message, "警告", "Icon!")
        isBound[hk] := false
    }
}

; 解绑热键
UnbindHotkey(hk) {
    global isBound
    if isBound.Has(hk) && isBound[hk] {
        try Hotkey hk, "Off"
        catch as err {
            ; 忽略解绑错误
        }
    }
    isBound[hk] := false
}
