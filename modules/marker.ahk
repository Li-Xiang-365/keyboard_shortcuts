; =========================
; 标记窗口管理
; =========================

; 创建或更新标记
CreateOrUpdateMarker(hk, x, y) {
    global markerWindows, markerVisible
    if !markerVisible
        return

    DestroyMarker(hk)

    colors := ["FF6347", "4169E1", "32CD32", "FFD700", "FF1493", "00CED1", "FF8C00"]
    hash := HashText(hk)
    idx := Mod(Abs(hash), colors.Length) + 1
    color := colors[idx]

    g := Gui("+AlwaysOnTop +ToolWindow -Caption +LastFound +E0x08000000", "MK_" hk)
    g.BackColor := color
    g.SetFont("s9", "Microsoft YaHei UI")
    g.Add("Text", "Center cWhite w26 h26", hk)
    g.Show("x" . (x - 13) . " y" . (y - 13) . " w26 h26")
    markerWindows[hk] := g
}

; 销毁标记
DestroyMarker(hk) {
    global markerWindows
    if markerWindows.Has(hk) {
        try markerWindows[hk].Destroy()
        markerWindows.Delete(hk)
    }
}

; 切换标记显示/隐藏
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
        global BtnToggleMarkers
        BtnToggleMarkers.Text := "隐藏标记"
    } else {
        ; 隐藏所有标记（先收集所有键，避免遍历时删除）
        keysToDelete := []
        for hk, g in markerWindows {
            keysToDelete.Push(hk)
        }
        for hk in keysToDelete {
            try markerWindows[hk].Destroy()
        }
        markerWindows.Clear()
        global BtnToggleMarkers
        BtnToggleMarkers.Text := "显示标记"
    }
}

; 简单hash用于颜色分配
HashText(s) {
    h := 0
    loop parse s
        h := (h * 131 + Ord(A_LoopField)) & 0x7fffffff
    return h
}
