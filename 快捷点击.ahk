#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetWorkingDir A_ScriptDir

; =========================
; 数据结构：
; binds := Map( "F1", {hwnd:12345,sx:100,sy:200,cx:50,cy:80}, "F2", {...} )
; hwnd: 窗口句柄, sx/sy: 屏幕坐标, cx/cy: 客户区坐标
; =========================
global isActive := true
global binds := Map()
global isBound := Map()     ; hotkey -> true/false
global totalClicks := 0

global clickCount := 1
global clickInterval := 80

global markerWindows := Map() ; hotkey -> Gui
global markerVisible := true  ; 标记是否可见

; =========================
; 主界面
; =========================
MainGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "快捷点击 v3.1")
MainGui.SetFont("s11", "Microsoft YaHei UI")

StatusText := MainGui.Add("Text", "x10 y10 w220 h22 cGreen", "状态：已激活")
TotalText := MainGui.Add("Text", "x10 y35 w220 h22 cBlue", "累计点击：0")

ListBox := MainGui.Add("ListBox", "x10 y60 w220 h160 vBindList")
RefreshList()

BtnAdd := MainGui.Add("Button", "x10 y230 w70 h28", "新增")
BtnEdit := MainGui.Add("Button", "x85 y230 w70 h28", "修改")
BtnDel := MainGui.Add("Button", "x160 y230 w70 h28", "删除")

BtnToggle := MainGui.Add("Button", "x10 y265 w105 h28", "切换启用/禁用")
BtnDelAll := MainGui.Add("Button", "x125 y265 w105 h28", "删除所有")
BtnSettings := MainGui.Add("Button", "x10 y300 w220 h28", "全局点击设置 (不移动鼠标)")
BtnToggleMarkers := MainGui.Add("Button", "x10 y335 w220 h28", "隐藏标记")

BtnAdd.OnEvent("Click", (*) => AddBind())
BtnEdit.OnEvent("Click", (*) => EditBind())
BtnDel.OnEvent("Click", (*) => DeleteBind())
BtnToggle.OnEvent("Click", (*) => ToggleActive())
BtnDelAll.OnEvent("Click", (*) => DeleteAllBinds())
BtnSettings.OnEvent("Click", (*) => GlobalSettings())
BtnToggleMarkers.OnEvent("Click", (*) => ToggleMarkers())

MainGui.Show("w240 h380 x50 y50")
MainGui.OnEvent("Close", (*) => MainGui.Hide())

; 托盘
A_TrayMenu.Delete()
A_TrayMenu.Add("显示窗口", (*) => MainGui.Show())
A_TrayMenu.Add("新增绑定", (*) => AddBind())
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => CleanupAndExit())
A_TrayMenu.Default := "显示窗口"

; 启动加载配置
LoadConfig()

; =========================
; 功能：新增绑定
; =========================
AddBind() {
    global binds

    hk := CaptureHotkey()
    if (hk = "")
        return

    if binds.Has(hk) {
        MsgBox "该快捷键已存在，请修改或换一个。", "提示", "Icon!"
        return
    }

    pos := PickPosition()
    if !IsObject(pos)
        return

    binds[hk] := pos
    BindHotkey(hk)

    CreateOrUpdateMarker(hk, pos.sx, pos.sy)
    SaveConfig()

    RefreshList()
}

; =========================
; 功能：修改绑定（可改坐标/改快捷键）
; =========================
EditBind() {
    global binds

    sel := GetSelectedHotkey()
    if (sel = "")
        return

    oldHk := sel
    oldPos := binds[oldHk]

    choice := MsgBox("选择要修改的内容：`n是=修改坐标`n否=修改快捷键`n取消=退出", "修改绑定", "YesNoCancel Icon?")
    if (choice = "Cancel")
        return

    if (choice = "Yes") {
        pos := PickPosition()
        if !IsObject(pos)
            return
        binds[oldHk] := pos
        CreateOrUpdateMarker(oldHk, pos.sx, pos.sy)
    } else {
        newHk := CaptureHotkey("请按下新的快捷键（Esc取消）")
        if (newHk = "" || newHk = oldHk)
            return
        if binds.Has(newHk) {
            MsgBox "新快捷键已存在。", "提示", "Icon!"
            return
        }

        ; 解绑旧
        UnbindHotkey(oldHk)
        DestroyMarker(oldHk)

        ; 迁移
        binds[newHk] := oldPos
        binds.Delete(oldHk)

        ; 绑定新
        BindHotkey(newHk)
        CreateOrUpdateMarker(newHk, oldPos.sx, oldPos.sy)
    }

    SaveConfig()
    RefreshList()
}

; =========================
; 功能：删除绑定
; =========================
DeleteBind() {
    global binds
    hk := GetSelectedHotkey()
    if (hk = "")
        return

    if (MsgBox("确定删除绑定：" . hk . " ?", "确认", "YesNo Icon!") != "Yes")
        return

    UnbindHotkey(hk)
    DestroyMarker(hk)
    binds.Delete(hk)

    SaveConfig()
    RefreshList()
}

; =========================
; 快捷键录入功能
; =========================
global capturedHotkey := ""  ; 存储捕获到的热键

CaptureHotkey(prompt := "请按下要绑定的快捷键（支持组合键，Esc取消）") {
    g := Gui("+AlwaysOnTop +ToolWindow", "录入快捷键")
    g.SetFont("s10", "Microsoft YaHei UI")
    g.Add("Text", "w320", prompt)
    g.Add("Text", "w320 cGray", "示例：F1 / Ctrl+Alt+K / Shift+F2")
    g.Show("AutoSize Center")

    ; InputHook 捕获单次按键
    ih := InputHook("L1 V")
    ih.KeyOpt("{All}", "E")     ; 让所有按键都可被捕获
    ih.OnEnd := (ih) => OnInputHookEnd(ih)
    ih.Start()
    ih.Wait()

    g.Destroy()

    return capturedHotkey
}

; InputHook 结束时的回调
OnInputHookEnd(ih) {
    global capturedHotkey

    if (ih.EndKey = "Escape") {
        capturedHotkey := ""
        return
    }

    ; 在按键释放前检查修饰键状态
    mods := ""
    if GetKeyState("LCtrl", "P") || GetKeyState("RCtrl", "P")
        mods .= "^"
    if GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P")
        mods .= "!"
    if GetKeyState("LShift", "P") || GetKeyState("RShift", "P")
        mods .= "+"
    if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
        mods .= "#"

    ; 处理主键
    key := ih.EndKey
    if (StrLen(key) = 1)
        key := StrUpper(key)

    capturedHotkey := mods . key
}

; =========================
; 选择屏幕位置：提示后点击取点，记录窗口和客户区坐标
; =========================
PickPosition() {
    ToolTip "请把鼠标移到目标位置，然后按下鼠标左键取点（ESC取消）", 20, 20

    ; ESC 取消：用 KeyWait 轮询方式避免卡死
    while true {
        if GetKeyState("Escape", "P") {
            ToolTip
            return false
        }
        if GetKeyState("LButton", "P")
            break
        Sleep 10
    }

    MouseGetPos &sx, &sy, &hwnd
    ToolTip

    ; 屏幕坐标 -> 窗口客户区坐标
    ; ControlClick 的 x,y 是相对窗口客户区
    pt := Buffer(8, 0)
    NumPut("Int", sx, pt, 0)
    NumPut("Int", sy, pt, 4)
    DllCall("ScreenToClient", "Ptr", hwnd, "Ptr", pt)
    cx := NumGet(pt, 0, "Int")
    cy := NumGet(pt, 4, "Int")

    return { hwnd: hwnd, sx: sx, sy: sy, cx: cx, cy: cy }
}

; =========================
; 热键绑定 / 解绑
; =========================
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

PerformClick(hk) {
    global isActive, binds, clickCount, clickInterval, totalClicks, TotalText

    ; 调试：显示触发的快捷键
    ToolTip "触发快捷键：" . hk, 20, 20
    SetTimer () => ToolTip(), -1000

    if !isActive
        return
    if !binds.Has(hk) {
        ToolTip "快捷键不存在：" . hk, 20, 20
        SetTimer () => ToolTip(), -2000
        return
    }

    b := binds[hk]

    ; 旧版本兼容：如果 hwnd=0，使用屏幕坐标点击（会移动鼠标）
    if (b.hwnd = 0) {
        loop clickCount {
            ; 获取正确的坐标属性
            sx := b.HasProp("sx") ? b.sx : (b.HasProp("x") ? b.x : 0)
            sy := b.HasProp("sy") ? b.sy : (b.HasProp("y") ? b.y : 0)

            MouseClick "Left", sx, sy

            totalClicks += 1
            TotalText.Value := "累计点击：" . totalClicks
            if (A_Index < clickCount && clickInterval > 0)
                Sleep clickInterval
        }
        ; 提示用户重新配置
        ToolTip "请重新配置此快捷键以使用不移动鼠标的点击", 20, 20
        SetTimer () => ToolTip(), -2000
        return
    }

    ; 新版本：使用 ControlClick 不移动鼠标
    ; 窗口不存在就直接退出
    if !WinExist("ahk_id " . b.hwnd) {
        ToolTip "窗口不存在，hwnd: " . b.hwnd, 20, 20
        SetTimer () => ToolTip(), -2000
        return
    }

    ToolTip "开始点击，坐标: (" . b.cx . "," . b.cy . ")", 20, 20
    SetTimer () => ToolTip(), -2000

    loop clickCount {
        ; ControlClick 不会移动鼠标
        ; 坐标在 Options 参数中传递： "x100 y100"
        try {
            opts := "x" . b.cx . " y" . b.cy
            ControlClick(, "ahk_id " . b.hwnd, , "Left", 1, opts)
            ToolTip "ControlClick 成功", 20, 20
            SetTimer () => ToolTip(), -1000
        } catch as err {
            ; 如果 ControlClick 失败，回退到 MouseClick（会移动鼠标）
            ToolTip "ControlClick 失败，回退到 MouseClick", 20, 20
            SetTimer () => ToolTip(), -1000
            MouseGetPos &mx, &my
            MouseClick "Left", b.cx, b.cy, , , , "ahk_id " . b.hwnd
            MouseMove mx, my, 0
            ToolTip "MouseClick 完成", 20, 20
            SetTimer () => ToolTip(), -1000

            totalClicks += 1
            TotalText.Value := "累计点击：" . totalClicks

            if (A_Index < clickCount && clickInterval > 0)
                Sleep clickInterval
            continue
        }

        totalClicks += 1
        TotalText.Value := "累计点击：" . totalClicks

        if (A_Index < clickCount && clickInterval > 0)
            Sleep clickInterval
    }
}

; =========================
; 状态切换
; =========================
ToggleActive() {
    global isActive, StatusText
    isActive := !isActive
    StatusText.Value := "状态：" . (isActive ? "已激活" : "已禁用")
    StatusText.SetFont(isActive ? "cGreen" : "cGray")
    SaveConfig()
}

; =========================
; 删除所有绑定
; =========================
DeleteAllBinds() {
    global binds
    if (binds.Count = 0) {
        MsgBox "当前没有可删除的绑定。", "提示", "Icon!"
        return
    }

    if (MsgBox("确定删除所有 " . binds.Count . " 个绑定？", "确认", "YesNo Icon!") != "Yes")
        return

    for hk, _ in binds {
        UnbindHotkey(hk)
        DestroyMarker(hk)
    }

    binds := Map()
    SaveConfig()
    RefreshList()
}

; =========================
; 切换标记显示/隐藏
; =========================
ToggleMarkers() {
    global markerVisible, markerWindows, binds

    if (binds.Count = 0) {
        MsgBox "当前没有标记可显示/隐藏。", "提示", "Icon!"
        return
    }

    markerVisible := !markerVisible

    if markerVisible {
        ; 显示所有标记
        for hk, pos in binds {
            CreateOrUpdateMarker(hk, pos.sx, pos.sy)
        }
        BtnToggleMarkers.Text := "隐藏标记"
    } else {
        ; 隐藏所有标记
        for hk, g in markerWindows {
            try g.Destroy()
            markerWindows.Delete(hk)
        }
        BtnToggleMarkers.Text := "显示标记"
    }
}

; =========================
; 全局点击设置
; =========================
GlobalSettings() {
    global clickCount, clickInterval

    c := InputBox("每次触发连击次数（>=1）", "全局设置", "w320 h130", clickCount).Value
    if (c != "")
        clickCount := Max(1, Integer(c))

    t := InputBox("连击间隔 ms（>=0）", "全局设置", "w320 h130", clickInterval).Value
    if (t != "")
        clickInterval := Max(0, Integer(t))

    SaveConfig()
    RefreshList()
}

; =========================
; 列表显示
; =========================
RefreshList() {
    global ListBox, binds, clickCount, clickInterval
    ListBox.Delete()

    for hk, pos in binds {
        ; 安全检查：确保坐标属性存在
        sx := pos.HasProp("sx") ? pos.sx : (pos.HasProp("x") ? pos.x : 0)
        sy := pos.HasProp("sy") ? pos.sy : (pos.HasProp("y") ? pos.y : 0)

        ; 如果是旧版本数据（hwnd=0），提示用户重新配置
        extra := (pos.hwnd = 0) ? " [需重新取点]" : ""

        ; 使用点号明确连接字符串
        text := hk . "  -> (" . sx . "," . sy . ")" . extra
        ListBox.Add([text])
    }
}

GetSelectedHotkey() {
    global ListBox
    text := ListBox.Text
    if (text = "")
        return ""
    ; 从 “F1  -> (x,y)” 截取快捷键
    return Trim(StrSplit(text, "->")[1])
}

; =========================
; 标记管理
; =========================
CreateOrUpdateMarker(hk, x, y) {
    global markerWindows, markerVisible
    if !markerVisible
        return

    DestroyMarker(hk)

    colors := ["FF6347", "4169E1", "32CD32", "FFD700", "FF1493", "00CED1", "FF8C00"]
    hash := HashText(hk)
    idx := Mod(Abs(hash), colors.Length) + 1
    color := colors[idx]

    g := Gui("+AlwaysOnTop +ToolWindow -Caption +LastFound", "MK_" hk)
    g.BackColor := color
    g.SetFont("s9", "Microsoft YaHei UI")
    g.Add("Text", "Center cWhite w26 h26", hk)
    g.Show("x" . (x - 13) . " y" . (y - 13) . " w26 h26")
    markerWindows[hk] := g
}

DestroyMarker(hk) {
    global markerWindows
    if markerWindows.Has(hk) {
        try markerWindows[hk].Destroy()
        markerWindows.Delete(hk)
    }
}

HashText(s) { ; 简单hash用于颜色分配
    h := 0
    loop parse s
        h := (h * 131 + Ord(A_LoopField)) & 0x7fffffff
    return h
}

; =========================
; 配置文件
; =========================
SaveConfig() {
    global binds, isActive, clickCount, clickInterval

    ini := "config_v31.ini"
    try FileDelete ini

    IniWrite (isActive ? "1" : "0"), ini, "Settings", "Active"
    IniWrite clickCount, ini, "Settings", "ClickCount"
    IniWrite clickInterval, ini, "Settings", "ClickInterval"
    IniWrite binds.Count, ini, "Settings", "BindCount"

    i := 0
    for hk, pos in binds {
        i++
        IniWrite hk, ini, "Binds", "Hotkey" . i
        IniWrite pos.hwnd, ini, "Binds", "Hwnd" . i
        IniWrite pos.sx "," . pos.sy, ini, "Binds", "Screen" . i
        IniWrite pos.cx "," . pos.cy, ini, "Binds", "Client" . i
    }
}

LoadConfig() {
    global binds, isActive, clickCount, clickInterval

    ini := "config_v31.ini"
    ; 优先尝试加载新版本配置
    if !FileExist(ini) {
        ; 如果新版本不存在，尝试加载旧版本（兼容性）
        ini := "config_v3.ini"
        if !FileExist(ini)
            return
    }

    isActive := (IniRead(ini, "Settings", "Active", "1") = "1")
    clickCount := Integer(IniRead(ini, "Settings", "ClickCount", "1"))
    clickInterval := Integer(IniRead(ini, "Settings", "ClickInterval", "80"))
    count := Integer(IniRead(ini, "Settings", "BindCount", "0"))

    binds := Map()
    loop count {
        hk := IniRead(ini, "Binds", "Hotkey" A_Index, "")
        ; 尝试加载新版本数据
        hwnd := IniRead(ini, "Binds", "Hwnd" A_Index, "")
        screenStr := IniRead(ini, "Binds", "Screen" A_Index, "")
        clientStr := IniRead(ini, "Binds", "Client" A_Index, "")

        if (hwnd != "" && screenStr != "" && clientStr != "") {
            ; 新版本数据
            screenParts := StrSplit(screenStr, ",")
            clientParts := StrSplit(clientStr, ",")
            if (screenParts.Length >= 2 && clientParts.Length >= 2) {
                binds[hk] := {
                    hwnd: Integer(hwnd),
                    sx: Integer(screenParts[1]),
                    sy: Integer(screenParts[2]),
                    cx: Integer(clientParts[1]),
                    cy: Integer(clientParts[2])
                }
                BindHotkey(hk)
                CreateOrUpdateMarker(hk, binds[hk].sx, binds[hk].sy)
            }
        } else {
            ; 旧版本兼容（仅屏幕坐标）
            posStr := IniRead(ini, "Binds", "Pos" A_Index, "")
            if (hk = "" || posStr = "")
                continue
            parts := StrSplit(posStr, ",")
            if (parts.Length < 2)
                continue
            ; 旧版本需要重新取点以获取窗口信息
            binds[hk] := {
                hwnd: 0,
                sx: Integer(parts[1]),
                sy: Integer(parts[2]),
                cx: 0,
                cy: 0
            }
            BindHotkey(hk)
            CreateOrUpdateMarker(hk, binds[hk].sx, binds[hk].sy)
        }
    }

    ; 刷新界面显示
    global StatusText
    StatusText.Value := "状态：" . (isActive ? "已激活" : "已禁用")
    StatusText.SetFont(isActive ? "cGreen" : "cGray")

    RefreshList()
}

CleanupAndExit() {
    global binds
    for hk, _ in binds
        UnbindHotkey(hk)
    ; 清理标记
    global markerWindows
    for hk, g in markerWindows {
        try g.Destroy()
    }
    SaveConfig()
    ExitApp
}
