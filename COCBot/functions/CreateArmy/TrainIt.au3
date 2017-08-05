; #FUNCTION# ====================================================================================================================
; Name ..........: TrainIt
; Description ...: validates and sends click in barrack window to actually train troops
; Syntax ........: TrainIt($iIndex[, $howMuch = 1[, $iSleep = 400]])
; Parameters ....: $iIndex           - index of troop/spell to train from the Global Enum $eBarb, $eArch, ..., $eHaSpell, $eSkSpell
;                  $howMuch          - [optional] how many to train Default is 1.
;                  $iSleep           - [optional] delay value after click. Default is 400.
; Return values .: None
; Author ........:
; Modified ......: KnowJack(07-2015), MonkeyHunter (05-2016), ProMac (01-2017), CodeSlinger69 (01-2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......: GetTrainPos, GetFullName, GetGemName
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once

Func TrainIt($iIndex, $iQuantity = 1, $iSleep = 400)
	If $g_iDebugSetlogTrain = 1 Then SetLog("Func TrainIt $iIndex=" & $iIndex & " $howMuch=" & $iQuantity & " $iSleep=" & $iSleep, $COLOR_DEBUG)
	Local $bDark = ($iIndex >= $eMini And $iIndex <= $eBowl)

	Local $aTrainPos = GetTrainPos($iIndex)
	If IsArray($aTrainPos) And $aTrainPos[0] <> -1 Then
		If _ColorCheck(_GetPixelColor($aTrainPos[0], $aTrainPos[1], $g_bCapturePixel), Hex($aTrainPos[2], 6), $aTrainPos[3]) = True Then
			Local $FullName = GetFullName($iIndex, $aTrainPos)
			If IsArray($FullName) Then
				Local $RNDName = GetRNDName($iIndex, $aTrainPos)
				If IsArray($RNDName) Then
					TrainClickP($aTrainPos, $iQuantity, $g_iTrainClickDelay, $FullName, "#0266", $RNDName)
					If _Sleep($iSleep) Then Return
					If $g_bOutOfElixir Then
						Setlog("Not enough " & ($bDark ? "Dark " : "") & "Elixir to train position " & GetTroopName($iIndex) & " troops!", $COLOR_ERROR)
						Setlog("Switching to Halt Attack, Stay Online Mode...", $COLOR_ERROR)
						If Not $g_bFullArmy Then $g_bRestart = True ;If the army camp is full, If yes then use it to refill storages
						Return ; We are out of Elixir stop training.
					EndIf
					Return True
				Else
					Setlog("TrainIt position " & GetTroopName($iIndex) & " - RNDName did not return array?", $COLOR_ERROR)
				EndIf
			Else
				Setlog("TrainIt " & GetTroopName($iIndex) & " - FullName did not return array?", $COLOR_ERROR)
			EndIf
		Else
			Local $sBadPixelColor = _GetPixelColor($aTrainPos[0], $aTrainPos[1], $g_bCapturePixel)
			If $g_iDebugSetlogTrain Then Setlog("Positon X: " & $aTrainPos[0] & "| Y : " & $aTrainPos[1] & " |Color get: " & $sBadPixelColor & " | Need: " & $aTrainPos[2])
			If StringMid($sBadPixelColor, 1, 2) = StringMid($sBadPixelColor, 3, 2) And StringMid($sBadPixelColor, 1, 2) = StringMid($sBadPixelColor, 5, 2) Then
				; Pixel is gray, so queue is full -> nothing to inform the user about
				Setlog("Troop " & GetTroopName($iIndex) & " is not available due to full queue", $COLOR_DEBUG)
			Else
				Setlog("Bad pixel check on troop position " & GetTroopName($iIndex), $COLOR_ERROR)
				If $g_iDebugSetlogTrain = 1 Then Setlog("Train Pixel Color: " & $sBadPixelColor, $COLOR_DEBUG)
			EndIf
		EndIf
	Else
		Setlog("Impossible happened? TrainIt troop position " & GetTroopName($iIndex) & " did not return array", $COLOR_ERROR)
	EndIf
EndFunc   ;==>TrainIt

Func GetTrainPos(Const $iIndex)
	If $g_iDebugSetlogTrain = 1 Then SetLog("GetTrainPos($iIndex=" & $iIndex & ")", $COLOR_DEBUG)

	Local $aTrainPos = $aTrainArmy[$iIndex]

	If $aTrainPos[0] <> -1 Then
		Return $aTrainPos
	Else
	; Get the Image path to search
	If $iIndex >= $eBarb And $iIndex <= $eBowl Then
		Local $sDirectory = @ScriptDir & "\imgxml\Train\Train_Train\"
		Local $sFilter = String($g_asTroopShortNames[$iIndex]) & "*"
		Local $asImageToUse = _FileListToArray($sDirectory, $sFilter, $FLTA_FILES, True)
		If $g_iDebugSetlogTrain Then setlog("$asImageToUse Troops: " & $asImageToUse[1])
		$aTrainPos = GetVariable($asImageToUse[1], $iIndex)
		$aTrainArmy[$iIndex] = $aTrainPos
		Return $aTrainPos
	EndIf

	If $iIndex >= $eLSpell And $iIndex <= $eSkSpell Then
		Local $sDirectory = @ScriptDir & "\imgxml\Train\Spell_Train\"
		Local $sFilter = String($g_asSpellShortNames[$iIndex - $eLSpell]) & "*"
		Local $asImageToUse = _FileListToArray($sDirectory, $sFilter, $FLTA_FILES, True)
		If $g_iDebugSetlogTrain Then setlog("$asImageToUse Spell: " & $asImageToUse[1])
		$aTrainPos = GetVariable($asImageToUse[1], $iIndex)
		$aTrainArmy[$iIndex] = $aTrainPos
		Return $aTrainPos
	EndIf

	EndIf

	Return 0
EndFunc   ;==>GetTrainPos

Func GetFullName(Const $iIndex, Const $aTrainPos)
	If $g_iDebugSetlogTrain = 1 Then SetLog("GetFullName($iIndex=" & $iIndex & ")", $COLOR_DEBUG)

	If $iIndex >= $eBarb And $iIndex <= $eBowl Then
		Local $sTroopType = ($iIndex >= $eMini ? "Dark" : "Normal")
		Return GetFullNameSlot($aTrainPos, $sTroopType)
	EndIf

	If $iIndex >= $eLSpell And $iIndex <= $eSkSpell Then
		Return GetFullNameSlot($aTrainPos, "Spell")
	EndIf

	SetLog("Don't know how to find the full name of troop with index " & $iIndex & " yet")

	Local $aTempSlot[4] = [-1, -1, -1, -1]

	Return $aTempSlot
EndFunc   ;==>GetFullName


Func GetRNDName(Const $iIndex, Const $aTrainPos)
	If $g_iDebugSetlogTrain = 1 Then SetLog("GetRNDName($iIndex=" & $iIndex & ")", $COLOR_DEBUG)
	Local $aTrainPosRND[4]

	If $iIndex <> -1 Then
		Local $aTempCoord = $aTrainPos
		$aTrainPosRND[0] = $aTempCoord[0] - 5
		$aTrainPosRND[1] = $aTempCoord[1] - 5
		$aTrainPosRND[2] = $aTempCoord[0] + 5
		$aTrainPosRND[3] = $aTempCoord[1] + 5
		Return $aTrainPosRND
	EndIf

	SetLog("Don't know how to find the RND name of troop with index " & $iIndex & " yet!", $COLOR_ERROR)
	Return 0
EndFunc   ;==>GetRNDName

Func GetVariable(Const $ImageToUse, Const $iIndex)
	Local $aTrainPos[4] = [-1, -1, -1, -1]
	; Capture the screen for comparison
	_CaptureRegion2(25, 375, 840, 548)

	;Local $asResult = DllCallMybot($g_hLibImgLoc, "str", "FindTile", "handle", $g_hHBitmap2, "str", $ImageToUse, "str", "FV", "int", 1)
	Local $asResult = DllCall($g_hLibImgLoc, "str", "FindTile", "handle", $g_hHBitmap2, "str", $ImageToUse, "str", "FV", "int", 1)

	If @error Then _logErrorDLLCall($g_sLibImgLocPath, @error)

	If IsArray($asResult) Then
		If $asResult[0] = "0" Then
			SetLog("No " & GetTroopName($iIndex) & " Icon found!", $COLOR_ERROR)
		ElseIf $asResult[0] = "-1" Then
			SetLog("TrainIt.au3 GetVariable(): ImgLoc DLL Error Occured!", $COLOR_ERROR)
		ElseIf $asResult[0] = "-2" Then
			SetLog("TrainIt.au3 GetVariable(): Wrong Resolution used for ImgLoc Search!", $COLOR_ERROR)
		Else
			If $g_iDebugSetlogTrain Then Setlog("String: " & $asResult[0])
			Local $aResult = StringSplit($asResult[0], "|", $STR_NOCOUNT)
			Local $aCoordinates = StringSplit($aResult[1], ",", $STR_NOCOUNT)
			Local $iButtonX = 25 + Int($aCoordinates[0])
			Local $iButtonY = 375 + Int($aCoordinates[1])
			Local $sColorToCheck = "0x" & _GetPixelColor($iButtonX, $iButtonY, $g_bCapturePixel)
			Local $iTolerance = 40
			Local $aTrainPos[4] = [$iButtonX, $iButtonY, $sColorToCheck, $iTolerance]
			If $g_iDebugSetlogTrain Then SetLog("Found: [" & $iButtonX & "," & $iButtonY & "]", $COLOR_SUCCESS)
			If $g_iDebugSetlogTrain Then SetLog("$sColorToCheck: " & $sColorToCheck, $COLOR_SUCCESS)
			If $g_iDebugSetlogTrain Then SetLog("$iTolerance: " & $iTolerance, $COLOR_SUCCESS)
			Return $aTrainPos
		EndIf
	Else
		SetLog("Don't know how to train the troop with index " & $iIndex & " yet")
	EndIf
	Return $aTrainPos
EndFunc   ;==>GetVariable


; Function to use on GetFullName() , returns slot and correct [i] symbols position on train window
Func GetFullNameSlot(Const $iTrainPos, Const $sTroopType)

	Local $iSlotH, $iSlotV

	If $sTroopType = "Spell" Then
		Switch $iTrainPos[0]
			Case 0 To 101 ; 1 Column
				$iSlotH = 101
			Case 105 To 199 ; 2 Column
				$iSlotH = 199
			Case 203 To 297 ; 3 Column
				$iSlotH = 297
			Case 302 To 395 ; 4 Column
				$iSlotH = 404
			Case 400 To 498 ; 5 Column
				$iSlotH = 502
			Case 499 To 597 ; 6 Column
				$iSlotH = 597
			Case Else
				If _ColorCheck(_GetPixelColor($iTrainPos[0], $iTrainPos[1], True), Hex(0xd3d3cb, 6), 5) Then
					Setlog("GetFullNameSlot(): It seems that there is no Slot for an Spell on: " & $iTrainPos[0] & "," & $iTrainPos[1] & "!", $COLOR_ERROR)
				EndIf
		EndSwitch

		Switch $iTrainPos[1]
			Case 0 To 445
				$iSlotV = 387 ; First ROW
			Case 446 To 550 ; Second ROW
				$iSlotV = 488
		EndSwitch

		Local $aSlot[4] = [$iSlotH, $iSlotV, 0x9d9d9d, 20] ; Gray [i] icon
		If $g_iDebugSetlogTrain Then SetLog("GetFullNameSlot(): Spell Icon found on: " & $iSlotH & "," & $iSlotV, $COLOR_DEBUG)
		Return $aSlot
	EndIf

	If $sTroopType = "Normal" Then
		Switch $iTrainPos[0]
			Case 0 To 101 ; 1 Column
				$iSlotH = 101
			Case 105 To 199 ; 2 Column
				$iSlotH = 199
			Case 200 To 297 ; 3 Column
				$iSlotH = 297
			Case 298 To 395 ; 4 Column
				$iSlotH = 395
			Case 396 To 494 ; 5 Column
				$iSlotH = 494
			Case 495 To 592 ; 6 Column
				$iSlotH = 592
			Case 593 To 690 ; 7 Column
				$iSlotH = 690
			Case Else
				If _ColorCheck(_GetPixelColor($iTrainPos[0], $iTrainPos[1], True), Hex(0xd3d3cb, 6), 5) Then
					Setlog("GetFullNameSlot(): It seems that there is no Slot for an Elixir Troop on: " & $iTrainPos[0] & "," & $iTrainPos[1] & "!", $COLOR_ERROR)
				EndIf
		EndSwitch

		Switch $iTrainPos[1]
			Case 0 To 445
				$iSlotV = 387 ; First ROW
			Case 446 To 550 ; Second ROW
				$iSlotV = 488
		EndSwitch

		Local $aSlot[4] = [$iSlotH, $iSlotV, 0x9F9F9F, 20] ; Gray [i] icon
		If $g_iDebugSetlogTrain Then SetLog("GetFullNameSlot(): Elixir Troop Icon found on: " & $iSlotH & "," & $iSlotV, $COLOR_DEBUG)

		Return $aSlot
	EndIf

	If $sTroopType = "Dark" Then
		Switch $iTrainPos[0]
			Case 440 To 517
				$iSlotH = 517
			Case 518 To 615
				$iSlotH = 615
			Case 616 To 714
				$iSlotH = 714
			Case 715 To 812
				$iSlotH = 812
			Case Else
				If _ColorCheck(_GetPixelColor($iTrainPos[0], $iTrainPos[1], True), Hex(0xd3d3cb, 6), 5) Then
					Setlog("GetFullNameSlot(): It seems that there is no Slot for a Dark Elixir Troop on: " & $iTrainPos[0] & "," & $iTrainPos[1] & "!", $COLOR_ERROR)
				EndIf
		EndSwitch

		Switch $iTrainPos[1]
			Case 0 To 445
				$iSlotV = 397 ; First ROW
			Case 446 To 550 ; Second ROW
				$iSlotV = 498
		EndSwitch

		Local $aSlot[4] = [$iSlotH, $iSlotV, 0x9f9f9f, 20] ; Gray [i] icon
		If $g_iDebugSetlogTrain Then SetLog("GetFullNameSlot(): Dark Elixir Troop Icon found on: " & $iSlotH & "," & $iSlotV, $COLOR_DEBUG)
		Return $aSlot
	EndIf

EndFunc   ;==>GetFullNameSlot
