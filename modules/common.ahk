#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetWorkingDir A_ScriptDir

; =========================
; 公共变量
; =========================
global isActive := true
global binds := Map()
global isBound := Map()     ; hotkey -> true/false
global totalClicks := 0

global clickCount := 1
global clickInterval := 80

global markerWindows := Map() ; hotkey -> Gui
global markerVisible := true  ; 标记是否可见

global MainGui
global StatusText
global TotalText
global ListBox
