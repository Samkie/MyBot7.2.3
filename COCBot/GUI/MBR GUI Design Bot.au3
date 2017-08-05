; #FUNCTION# ====================================================================================================================
; Name ..........: MBR GUI Design
; Description ...: This file creates the "Bot" tab
; Syntax ........:
; Parameters ....: None
; Return values .: None
; Author ........:
; Modified ......: CodeSlinger69 (2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once

Global $g_hGUI_BOT = 0

#include "MBR GUI Design Child Bot - Options.au3"
#include "MBR GUI Design Child Bot - Android.au3"
#include "MBR GUI Design Child Bot - Debug.au3"
#include "MBR GUI Design Child Bot - Profiles.au3"
#include "MBR GUI Design Child Bot - Stats.au3"

Global $g_hGUI_BOT_TAB = 0, $g_hGUI_BOT_TAB_ITEM1 = 0, $g_hGUI_BOT_TAB_ITEM2 = 0, $g_hGUI_BOT_TAB_ITEM3 = 0, $g_hGUI_BOT_TAB_ITEM4 = 0, $g_hGUI_BOT_TAB_ITEM5 = 0

Func CreateBotTab()
   $g_hGUI_BOT = _GUICreate("", $g_iSizeWGrpTab1, $g_iSizeHGrpTab1, $_GUI_CHILD_LEFT, $_GUI_CHILD_TOP, BitOR($WS_CHILD, $WS_TABSTOP), -1, $g_hFrmBotEx)
   ;GUISetBkColor($COLOR_WHITE, $g_hGUI_BOT)

   $g_hGUI_STATS = _GUICreate("", $g_iSizeWGrpTab2, $g_iSizeHGrpTab2, 5, 25, BitOR($WS_CHILD, $WS_TABSTOP), -1, $g_hGUI_BOT)

   GUISwitch($g_hGUI_BOT)
   $g_hGUI_BOT_TAB = GUICtrlCreateTab(0, 0, $g_iSizeWGrpTab1, $g_iSizeHGrpTab1, BitOR($TCS_MULTILINE, $TCS_RIGHTJUSTIFY))
   $g_hGUI_BOT_TAB_ITEM1 = GUICtrlCreateTabItem(GetTranslatedFileIni("MBR Main GUI", "Tab_04_STab_01", "Options"))
   CreateBotOptions()
   $g_hGUI_BOT_TAB_ITEM2 = GUICtrlCreateTabItem(GetTranslatedFileIni("MBR Main GUI", "Tab_04_STab_02", "Android"))
   CreateBotAndroid()
   $g_hGUI_BOT_TAB_ITEM3 = GUICtrlCreateTabItem(GetTranslatedFileIni("MBR Main GUI", "Tab_04_STab_03", "Debug"))
   CreateBotDebug()
   $g_hGUI_BOT_TAB_ITEM4 = GUICtrlCreateTabItem(GetTranslatedFileIni("MBR Main GUI", "Tab_04_STab_04", "Profiles"))
   CreateBotProfiles()
   $g_hGUI_BOT_TAB_ITEM5 = GUICtrlCreateTabItem(GetTranslatedFileIni("MBR Main GUI", "Tab_04_STab_05", "Stats"))
	; This dummy is used in btnStart and btnStop to disable/enable all labels, text, buttons etc. on all tabs.
   $g_hLastControlToHide = GUICtrlCreateDummy()
   ReDim $g_aiControlPrevState[$g_hLastControlToHide + 1]
   CreateBotStats()
   GUICtrlCreateTabItem("")

	; samm0d
	Local $x = 220
	Local $y = 380
	$g_hLblProfileName = GUICtrlCreateLabel("Profile", $x+9, $y, 190, 17, $SS_CENTER)
	Local $sTxtTip = GetTranslatedFileIni("sam m0d",26, "Better result is pause bot before view stats.")
	_GUICtrlSetTip(-1, $sTxtTip)
	$arrowleft2 = GUICtrlCreatePic(@ScriptDir & "\Images\triangle_left.bmp", $x, $y+1, 8, 14)
	$sTxtTip = GetTranslatedFileIni("sam m0d",25, "Switch between profile stats")
	_GUICtrlSetTip(-1, $sTxtTip)
	GUICtrlSetOnEvent(-1, "DoViewStats1")
	$arrowright2 = GUICtrlCreatePic(@ScriptDir & "\Images\triangle_right.bmp", $x + 198, $y+1, 8, 14)
	_GUICtrlSetTip(-1, $sTxtTip)
	GUICtrlSetOnEvent(-1, "DoViewStats2")

EndFunc
