; =========================
; 配置文件读写
; =========================

; 保存配置（保存hwnd、屏幕坐标和客户区坐标）
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

; 加载配置（加载hwnd、屏幕坐标和客户区坐标）
LoadConfig() {
    global binds, isActive, clickCount, clickInterval, StatusText

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

        ; 尝试加载新版本数据（hwnd + 屏幕 + 客户区坐标）
        hwnd := IniRead(ini, "Binds", "Hwnd" A_Index, "")
        screenStr := IniRead(ini, "Binds", "Screen" A_Index, "")
        clientStr := IniRead(ini, "Binds", "Client" A_Index, "")

        ; 如果新版本数据不完整，尝试加载旧版本数据
        if (hwnd = "" || screenStr = "" || clientStr = "") {
            ; 尝试加载旧版本的Pos字段
            posStr := IniRead(ini, "Binds", "Pos" A_Index, "")
            if (posStr = "")
                continue

            parts := StrSplit(posStr, ",")
            if (parts.Length < 2)
                continue

            ; 旧版本数据，hwnd设为0，提示用户重新取点
            binds[hk] := {
                hwnd: 0,
                sx: Integer(parts[1]),
                sy: Integer(parts[2]),
                cx: 0,
                cy: 0
            }
        } else {
            ; 新版本完整数据
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
            }
        }

        if binds.Has(hk) {
            BindHotkey(hk)
            CreateOrUpdateMarker(hk, binds[hk].sx, binds[hk].sy)
        }
    }

    ; 刷新界面显示
    StatusText.Value := "状态：" . (isActive ? "已激活" : "已禁用")
    StatusText.SetFont(isActive ? "cGreen" : "cGray")

    RefreshList()
}
