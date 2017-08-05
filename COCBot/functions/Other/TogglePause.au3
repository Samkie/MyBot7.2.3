
; #FUNCTION# ====================================================================================================================
; Name ..........: TogglePause
; Description ...:
; Syntax ........: TogglePause()
; Parameters ....:
; Return values .: None
; Author ........:
; Modified ......: CodeSlinger69 (01-2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once

Func TogglePause()
	TogglePauseImpl("Button")
EndFunc   ;==>TogglePause

Func TogglePauseImpl($Source)
	If Not $g_bRunState Then Return
	ResumeAndroid()
	$g_bBotPaused = Not $g_bBotPaused
	If $g_bTogglePauseAllowed = False Then
		$g_bTogglePauseUpdateState = True
		Return
	EndIf
	TogglePauseUpdateState($Source)
	TogglePauseSleep()
EndFunc   ;==>TogglePauseImpl

Func TogglePauseUpdateState($Source)
	$g_iActualTrainSkip = 0

	$g_bTogglePauseUpdateState = False

    If $g_bBotPaused Then
		AndroidShield("TogglePauseImpl paused", False)
		TrayTip($g_sBotTitle, "", 1)
		TrayTip($g_sBotTitle, "was Paused!", 1, $TIP_ICONEXCLAMATION)
		Setlog("Bot was Paused!", $COLOR_ERROR)
		If Not $g_bSearchMode Then
			$g_iTimePassed += Int(__TimerDiff($g_hTimerSinceStarted))
			;AdlibUnRegister("SetTime")
		EndIf
		PushMsg("Pause", $Source)
		GUICtrlSetState($g_hBtnPause, $GUI_HIDE)
		GUICtrlSetState($g_hBtnResume, $GUI_SHOW)
		;GUICtrlSetState($btnMakeScreenshot, $GUI_ENABLE)
	Else
		AndroidShield("TogglePauseImpl resumed")
		TrayTip($g_sBotTitle, "", 1)
		TrayTip($g_sBotTitle, "was Resumed.", 1, $TIP_ICONASTERISK)
		Setlog("Bot was Resumed.", $COLOR_SUCCESS)
		If Not $g_bSearchMode Then
			$g_hTimerSinceStarted = __TimerInit()
			;AdlibRegister("SetTime", 1000)
		EndIf
		PushMsg("Resume", $Source)
		GUICtrlSetState($g_hBtnPause, $GUI_SHOW)
		GUICtrlSetState($g_hBtnResume, $GUI_HIDE)
		;GUICtrlSetState($btnMakeScreenshot, $GUI_DISABLE)
		;ZoomOut()
	EndIf
	SetRedrawBotWindow(True, Default, Default, Default, "TogglePauseUpdateState")
EndFunc	  ;==>TogglePauseUpdateState

Func TogglePauseSleep()
	Local $counter = 0
	Local $hTimerAutoResume = __TimerInit()
	While $g_bBotPaused ; Actual Pause loop
		If _Sleep($DELAYTOGGLEPAUSE1, True, True, False) Then ExitLoop
		If $g_bAutoResumeEnable And __TimerDiff($hTimerAutoResume) >= ($g_iAutoResumeTime * 60000) Then
			SetLog("Auto resume bot after " & $g_iAutoResumeTime & " minutes of waiting", $COLOR_INFO)
			TogglePause()
		EndIf
		$counter = $counter + 1
		If ($g_bNotifyPBEnable = True Or $g_bNotifyTGEnable = True) And $g_bNotifyRemoteEnable = True And $counter = 200 Then
			NotifyRemoteControl()
			$counter = 0
		EndIf
	WEnd
	; everything below this WEnd is executed when unpaused!
	$g_bSkipFirstZoomout = False
	;ZoomOut() ; moved to resume
	If _Sleep($DELAYTOGGLEPAUSE2, True, True, False) Then Return
EndFunc	  ;==>TogglePauseSleep
