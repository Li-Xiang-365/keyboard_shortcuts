; =========================
; 全局设置和状态管理
; =========================

; 切换激活状态
ToggleActive() {
    global isActive, StatusText
    isActive := !isActive
    StatusText.Value := "状态：" . (isActive ? "已激活" : "已禁用")
    StatusText.SetFont(isActive ? "cGreen" : "cGray")
    SaveConfig()
}

; 全局点击设置
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

; 清理并退出
CleanupAndExit() {
    global binds, markerWindows
    for hk, _ in binds
        UnbindHotkey(hk)
    ; 清理标记
    for hk, g in markerWindows {
        try g.Destroy()
    }
    SaveConfig()
    ExitApp
}
