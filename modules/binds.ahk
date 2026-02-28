; =========================
; 绑定管理（新增、修改、删除）
; =========================

; 新增绑定
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

; 修改绑定（可改坐标/改快捷键）
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

; 删除绑定
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

; 删除所有绑定
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
