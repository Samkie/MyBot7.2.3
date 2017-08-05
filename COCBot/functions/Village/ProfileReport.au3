
; #FUNCTION# ====================================================================================================================
; Name ..........: ProfileReport
; Description ...: This function will report Attacks Won, Defenses Won, Troops Donated and Troops Received from Profile info page
; Syntax ........: ProfileReport()
; Parameters ....:
; Return values .: None
; Author ........: Sardo
; Modified ......: KnowJack (July 2015) add wait loop for slow PC read of OCR
;                  Sardo 2015-08, CodeSlinger69 9(2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once

Func ProfileReport()
	Local $AttacksWon = 0, $DefensesWon = 0

	Local $iCount
	ClickP($aAway, 1, 0, "#0221") ;Click Away
	If _Sleep($DELAYPROFILEREPORT1) Then Return

	SetLog("Profile Report", $COLOR_INFO)
	SetLog("Opening Profile page to read atk, def, donated and received...", $COLOR_INFO)
	Click(30, 40, 1, 0, "#0222") ; Click Info Profile Button
	If _Sleep($DELAYPROFILEREPORT2) Then Return

	While _ColorCheck(_GetPixelColor(400, 104 + $g_iMidOffsetY, True), Hex(0xA2A6BE, 6), 20) = False ; wait for Info Profile to open
		If $g_iDebugSetlog = 1 Then Setlog("Profile wait time: " & $iCount & ", color= " & _GetPixelColor(400, 104 + $g_iMidOffsetY, True) & " pos (400," & 104 + $g_iMidOffsetY & ")", $COLOR_DEBUG)
		$iCount += 1
		If _Sleep($DELAYPROFILEREPORT1) Then Return
		If $iCount >= 25 Then ExitLoop
	WEnd
	If $g_iDebugSetlog = 1 And $iCount >= 25 Then Setlog("Excess wait time for profile to open: " & $iCount, $COLOR_DEBUG)
	If _Sleep($DELAYPROFILEREPORT1) Then Return
	$AttacksWon = ""

	If _ColorCheck(_GetPixelColor($ProfileRep01[0], $ProfileRep01[1], True), Hex($ProfileRep01[2], 6), $ProfileRep01[3]) = True Then
		If $g_iDebugSetlog = 1 Then Setlog("Village have no attack and no defenses " & $ProfileRep01[0] & "," & $ProfileRep01[1] + $g_iMidOffsetY, $COLOR_DEBUG)
		$AttacksWon = 0
		$DefensesWon = 0
	Else
		$AttacksWon = getProfile(578, 268 + $g_iMidOffsetY)
		If $g_iDebugSetlog = 1 Then Setlog("$AttacksWon 1st read: " & $AttacksWon, $COLOR_DEBUG)
		$iCount = 0
		While $AttacksWon = "" ; Wait for $attacksWon to be readable in case of slow PC
			If _Sleep($DELAYPROFILEREPORT1) Then Return
			$AttacksWon = getProfile(578, 268 + $g_iMidOffsetY)
			If $g_iDebugSetlog = 1 Then Setlog("Read Loop $AttacksWon: " & $AttacksWon & ", Count: " & $iCount, $COLOR_DEBUG)
			$iCount += 1
			If $iCount >= 20 Then ExitLoop
		WEnd
		If $g_iDebugSetlog = 1 And $iCount >= 20 Then Setlog("Excess wait time for reading $AttacksWon: " & getProfile(578, 268 + $g_iMidOffsetY), $COLOR_DEBUG)
		$DefensesWon = getProfile(790, 268 + $g_iMidOffsetY)
	EndIf
	$g_iTroopsDonated = getProfile(158, 268 + $g_iMidOffsetY)
	$g_iTroopsReceived = getProfile(360, 268 + $g_iMidOffsetY)

	SetLog(" [ATKW]: " & _NumberFormat($AttacksWon) & " [DEFW]: " & _NumberFormat($DefensesWon) & " [TDON]: " & _NumberFormat($g_iTroopsDonated) & " [TREC]: " & _NumberFormat($g_iTroopsReceived), $COLOR_SUCCESS)
	Click(830, 80, 1, 0, "#0223") ; Close Profile page
	If _Sleep($DELAYPROFILEREPORT3) Then Return

	$iCount = 0
	While _CheckPixel($aIsMain, $g_bCapturePixel) = False ; wait for profile report window very slow close
		If _Sleep($DELAYPROFILEREPORT3) Then Return
		$iCount += 1
		If $g_iDebugSetlog = 1 Then Setlog("End ProfileReport $iCount= " & $iCount, $COLOR_DEBUG)
		If $iCount > 50 Then
			If $g_iDebugSetlog = 1 Then Setlog("Excess wait time clearing ProfileReport window: " & $iCount, $COLOR_DEBUG)
			ExitLoop
		EndIf
	WEnd

EndFunc   ;==>ProfileReport
