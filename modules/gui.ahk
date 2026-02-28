; =========================
; 列表显示相关函数
; =========================

; 刷新列表
RefreshList() {
    global ListBox, binds
    ListBox.Delete()

    for hk, pos in binds {
        ; 兼容旧版本数据
        sx := pos.HasProp("sx") ? pos.sx : (pos.HasProp("x") ? pos.x : 0)
        sy := pos.HasProp("sy") ? pos.sy : (pos.HasProp("y") ? pos.y : 0)

        ; 检查是否是旧版本数据（hwnd=0或不存在）
        isOldData := !pos.HasProp("hwnd") || (pos.hwnd = 0)

        text := hk . "  -> (" . sx . "," . sy . ")"
        if (isOldData)
            text .= " [需重新取点]"

        ListBox.Add([text])
    }
}

; 获取选中的快捷键
GetSelectedHotkey() {
    global ListBox
    text := ListBox.Text
    if (text = "")
        return ""
    ; 从 "F1  -> (x,y)" 截取快捷键
    return Trim(StrSplit(text, "->")[1])
}
