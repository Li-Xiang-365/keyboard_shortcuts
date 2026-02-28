; =========================
; 点击执行逻辑（不移动鼠标）
; =========================

; 在指定屏幕坐标发送点击消息（不移动鼠标）
MouseClickAtPos(x, y, button := "Left") {
    ; 获取目标窗口句柄
    targetHwnd := DllCall("WindowFromPoint", "Int", x, "Int", y, "Ptr")

    if (!targetHwnd) {
        return false
    }

    ; 转换屏幕坐标为客户区坐标
    pt := Buffer(8, 0)
    NumPut("Int", x, pt, 0)
    NumPut("Int", y, pt, 4)
    DllCall("ScreenToClient", "Ptr", targetHwnd, "Ptr", pt)
    cx := NumGet(pt, 0, "Int")
    cy := NumGet(pt, 4, "Int")

    ; 发送鼠标按下消息
    PostMessage(0x0201, 0, cx | (cy << 16), , "ahk_id " targetHwnd)  ; WM_LBUTTONDOWN = 0x0201

    ; 发送鼠标抬起消息
    PostMessage(0x0202, 0, cx | (cy << 16), , "ahk_id " targetHwnd)  ; WM_LBUTTONUP = 0x0202

    return true
}

; 执行点击（不移动鼠标）
PerformClick(hk) {
    global isActive, binds, clickCount, clickInterval, totalClicks, TotalText, markerWindows

    ; 调试：显示触发的快捷键
    ToolTip "触发快捷键：" . hk, 20, 20
    SetTimer () => ToolTip(), -1000

    if !isActive {
        ToolTip "已禁用", 20, 20
        SetTimer () => ToolTip(), -2000
        return
    }

    if !binds.Has(hk) {
        ToolTip "快捷键不存在：" . hk, 20, 20
        SetTimer () => ToolTip(), -2000
        return
    }

    b := binds[hk]

    ; 检查是否有屏幕坐标
    if !b.HasProp("sx") || !b.HasProp("sy") {
        ToolTip "请重新配置此快捷键，需要重新取点", 20, 20
        SetTimer () => ToolTip(), -2000
        return
    }

    ToolTip "准备点击: 屏幕坐标(" . b.sx . "," . b.sy . ")", 20, 20
    SetTimer () => ToolTip(), -500

    ; 使用屏幕坐标点击（不移动鼠标）
    loop clickCount {
        ToolTip "正在点击第 " . A_Index . " 次", 20, 20
        SetTimer () => ToolTip(), -500

        success := MouseClickAtPos(b.sx, b.sy, "Left")

        if (success) {
            ToolTip "点击执行完成", 20, 20
        } else {
            ToolTip "点击失败：无法获取目标窗口", 20, 20
            SetTimer () => ToolTip(), -2000
        }

        totalClicks += 1
        TotalText.Value := "累计点击：" . totalClicks

        if (A_Index < clickCount && clickInterval > 0)
            Sleep clickInterval
    }

    ToolTip "点击完成", 20, 20
    SetTimer () => ToolTip(), -2000
}

; 选择屏幕位置
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

    ; 获取屏幕坐标和窗口句柄
    MouseGetPos &sx, &sy, &hwnd
    ToolTip

    ; 返回屏幕坐标（客户区坐标设为0，表示不使用）
    return { hwnd: hwnd, sx: sx, sy: sy, cx: 0, cy: 0 }
}
