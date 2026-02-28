; =========================
; 快捷点击 v3.2 - 主入口文件
; =========================
; 模块化结构：
; - modules/common.ahk     公共变量和常量
; - modules/gui.ahk         GUI界面辅助函数
; - modules/hotkey.ahk      快捷键录入和绑定
; - modules/click.ahk       点击执行逻辑
; - modules/binds.ahk       绑定管理
; - modules/marker.ahk      标记窗口管理
; - modules/config.ahk      配置文件读写
; - modules/settings.ahk    全局设置
;
; v3.2 更新：
; - 移除hwnd依赖，直接使用屏幕坐标
; - 解决窗口句柄动态变化导致的失效问题
; =========================

; 加载公共模块
#Include modules/common.ahk

; 加载其他功能模块
#Include modules/gui.ahk
#Include modules/hotkey.ahk
#Include modules/click.ahk        ; 不移动鼠标版本
#Include modules/binds.ahk
#Include modules/marker.ahk
#Include modules/config.ahk
#Include modules/settings.ahk

; =========================
; 主界面创建
; =========================
MainGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "快捷点击 v2.0")
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
BtnSettings := MainGui.Add("Button", "x10 y300 w220 h28", "全局点击设置")
BtnToggleMarkers := MainGui.Add("Button", "x10 y335 w220 h28", "隐藏标记")

; 绑定按钮事件
BtnAdd.OnEvent("Click", (*) => AddBind())
BtnEdit.OnEvent("Click", (*) => EditBind())
BtnDel.OnEvent("Click", (*) => DeleteBind())
BtnToggle.OnEvent("Click", (*) => ToggleActive())
BtnDelAll.OnEvent("Click", (*) => DeleteAllBinds())
BtnSettings.OnEvent("Click", (*) => GlobalSettings())
BtnToggleMarkers.OnEvent("Click", (*) => ToggleMarkers())

; 显示主窗口
MainGui.Show("w240 h380 x50 y50")
MainGui.OnEvent("Close", (*) => MainGui.Hide())

; =========================
; 托盘菜单
; =========================
A_TrayMenu.Delete()
A_TrayMenu.Add("显示窗口", (*) => MainGui.Show())
A_TrayMenu.Add("新增绑定", (*) => AddBind())
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => CleanupAndExit())
A_TrayMenu.Default := "显示窗口"

; =========================
; 启动加载配置
; =========================
LoadConfig()