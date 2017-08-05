; #FUNCTION# ====================================================================================================================
; Name ..........: CheckTombs.au3
; Description ...: This file Includes function to perform defense farming.
; Syntax ........:
; Parameters ....: None
; Return values .: False if regular farming is needed to refill storage
; Author ........: barracoda/KnowJack (2015)
; Modified ......: sardo (05-2015/06-2015) , ProMac (04-2016), MonkeyHuner (06-2015)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func CheckTombs()
	If Not TestCapture() Then
		If $g_bChkTombstones = False Then Return False
		If $g_abNotNeedAllTime[1] = False Then Return
	EndIf
	; Timer
	Local $hTimer = __TimerInit()

	; tombs function to Parallel Search
	Local $directory = @ScriptDir & "\imgxml\Resources\Tombs"

	; Setup arrays, including default return values for $return
	Local $return[7] = ["None", "None", 0, 0, 0, "", ""]
	Local $TombsXY[2] = [0, 0]

	; Perform a parallel search with all images inside the directory
	Local $aResult = returnSingleMatchOwnVillage($directory)

	If UBound($aResult) > 1 Then
		; Now loop through the array to modify values, select the highest entry to return
		For $i = 1 To UBound($aResult) - 1
			; Check to see if its a higher level then currently stored
			If Number($aResult[$i][2]) > Number($return[2]) Then
				; Store the data because its higher
				$return[0] = $aResult[$i][0] ; Filename
				$return[1] = $aResult[$i][1] ; Type
				$return[4] = $aResult[$i][4] ; Total Objects
				$return[5] = $aResult[$i][5] ; Coords
			EndIf
		Next
		$TombsXY = $return[5]

		If $g_iDebugSetlog = 1 Then SetLog("Filename :" & $return[0])
		If $g_iDebugSetlog = 1 Then SetLog("Type :" & $return[1])
		If $g_iDebugSetlog = 1 Then SetLog("Total Objects :" & $return[4])

		Local $bRemoved = False
		If IsArray($TombsXY) Then
			; Loop through all found points for the item and click them to clear them, there should only be one
			For $j = 0 To UBound($TombsXY) - 1
				If isInsideDiamondXY($TombsXY[$j][0], $TombsXY[$j][1]) Then
					If $g_iDebugSetlog = 1 Then Setlog("Coords :" & $TombsXY[$j][0] & "," & $TombsXY[$j][1])
					If IsMainPage() Then
						Click($TombsXY[$j][0], $TombsXY[$j][1], 1, 0, "#0430")
						If $bRemoved = False Then $bRemoved = IsMainPage()
					EndIf
				EndIf
			Next
		EndIf
		If $bRemoved Then
			Setlog("Tombs removed!", $COLOR_DEBUG1)
			$g_abNotNeedAllTime[1] = False
		Else
			Setlog("Tombs not removed, please do manually!", $COLOR_WARNING)
		EndIf
	Else
		Setlog("No Tombs Found!", $COLOR_SUCCESS)
		$g_abNotNeedAllTime[1] = False
	EndIf

	checkMainScreen(False) ; check for screen errors while function was running
EndFunc   ;==>CheckTombs

Func CleanYard()

	; Early exist if noting to do
	If $g_bChkCleanYard = False And $g_bChkGemsBox = False And Not TestCapture() Then Return

	; Timer
	Local $hObstaclesTimer = __TimerInit()

	; Get Builders available
	If getBuilderCount() = False Then Return ; update builder data, return if problem
	If _Sleep($DELAYRESPOND) Then Return

	; Obstacles function to Parallel Search , will run all pictures inside the directory
	Local $directory = @ScriptDir & "\imgxml\Resources\Obstacles"

	If $g_iDetectedImageType = 1 Then $directory = @ScriptDir & "\imgxml\Obstacles_Snow" ; Snow theme

	; Setup arrays, including default return values for $return
	Local $Filename = ""
	Local $Locate = 0
	Local $CleanYardXY
	Local $sCocDiamond = $CocDiamondECD
	Local $redLines = $sCocDiamond
	Local $minLevel = 0
	Local $maxLevel = 1000
	Local $maxReturnPoints = 10 ; $g_iFreeBuilderCount
	Local $returnProps = "objectname,objectlevel,objectpoints"
	Local $bForceCapture = True
	Local $NoBuilders = $g_iFreeBuilderCount < 1

	If $g_iFreeBuilderCount > 0 And $g_bChkCleanYard = True And Number($g_aiCurrentLoot[$eLootElixir]) > 50000 Then
		Local $aResult = findMultiple($directory, $sCocDiamond, $redLines, $minLevel, $maxLevel, $maxReturnPoints, $returnProps, $bForceCapture)
		If IsArray($aResult) Then
			For $matchedValues In $aResult
				Local $aPoints = decodeMultipleCoords($matchedValues[2])
				$Filename = $matchedValues[0] ; Filename
				For $i = 0 To UBound($aPoints) - 1
					$CleanYardXY = $aPoints[$i] ; Coords
					If isInsideDiamondXY($CleanYardXY[0], $CleanYardXY[1]) Then ; secure x because of clan chat tab
						If $g_iDebugSetlog = 1 Then SetLog($Filename & " found (" & $CleanYardXY[0] & "," & $CleanYardXY[1] & ")", $COLOR_SUCCESS)
						If IsMainPage() Then Click($CleanYardXY[0], $CleanYardXY[1], 1, 0, "#0430")
						$Locate = 1
						If _Sleep($DELAYCOLLECT3) Then Return
						If IsMainPage() Then GemClick($aCleanYard[0], $aCleanYard[1], 1, 0, "#0431") ; Click Obstacles button to clean
						If _Sleep($DELAYCHECKTOMBS2) Then Return
						ClickP($aAway, 2, 300, "#0329") ;Click Away
						If _Sleep($DELAYCHECKTOMBS1) Then Return
						If getBuilderCount() = False Then Return ; update builder data, return if problem
						If _Sleep($DELAYRESPOND) Then Return
						If $g_iFreeBuilderCount = 0 Then
							Setlog("No More Builders available")
							If _Sleep(2000) Then Return
							ExitLoop (2)
						EndIf
					EndIf
				Next
			Next
		EndIf
	EndIf

	; GemBox function to Parallel Search , will run all pictures inside the directory
	Local $directoryGemBox = @ScriptDir & "\imgxml\Resources\GemBox"

	; Setup arrays, including default return values for $return
	Local $return[7] = ["None", "None", 0, 0, 0, "", ""]
	Local $GemBoxXY[2] = [0, 0]

	; Perform a parallel search with all images inside the directory
	If ($g_iFreeBuilderCount > 0 And $g_bChkGemsBox = True And Number($g_aiCurrentLoot[$eLootElixir]) > 50000) Or TestCapture() Then
		Local $aResult = multiMatches($directoryGemBox, 1, $sCocDiamond, $sCocDiamond)
		If UBound($aResult) > 1 Then
			; Now loop through the array to modify values, select the highest entry to return
			For $i = 1 To UBound($aResult) - 1
				; Check to see if its a higher level then currently stored
				If Number($aResult[$i][2]) > Number($return[2]) Then
					; Store the data because its higher
					$return[0] = $aResult[$i][0] ; Filename
					$return[1] = $aResult[$i][1] ; Type
					$return[4] = $aResult[$i][4] ; Total Objects
					$return[5] = $aResult[$i][5] ; Coords
				EndIf
			Next
			$GemBoxXY = $return[5]

			If $g_iDebugSetlog = 1 Then SetLog("Filename :" & $return[0])
			If $g_iDebugSetlog = 1 Then SetLog("Type :" & $return[1])
			If $g_iDebugSetlog = 1 Then SetLog("Total Objects :" & $return[4])

			If IsArray($GemBoxXY) Then
				; Loop through all found points for the item and click them to remove it, there should only be one
				For $j = 0 To UBound($GemBoxXY) - 1
					If $g_iDebugSetlog = 1 Then Setlog("Coords :" & $GemBoxXY[$j][0] & "," & $GemBoxXY[$j][1])
					If isInsideDiamondXY($GemBoxXY[$j][0], $GemBoxXY[$j][1]) Then
						If IsMainPage() Then Click($GemBoxXY[$j][0], $GemBoxXY[$j][1], 1, 0, "#0430")
						If _Sleep($DELAYCHECKTOMBS2) Then Return
						$Locate = 1
						If _Sleep($DELAYCOLLECT3) Then Return
						If IsMainPage() Then Click($aCleanYard[0], $aCleanYard[1], 1, 0, "#0431") ; Click GemBox button to remove item
						If _Sleep($DELAYCHECKTOMBS2) Then Return
						ClickP($aAway, 2, 300, "#0329") ;Click Away
						If _Sleep($DELAYCHECKTOMBS1) Then Return
						If getBuilderCount() = False Then Return ; update builder data, return if problem
						If _Sleep($DELAYRESPOND) Then Return
						If $g_iFreeBuilderCount = 0 Then
							Setlog("No More Builders available")
							If _Sleep(2000) Then Return
							ExitLoop
						EndIf
					EndIf
				Next
			EndIf
			Setlog("GemBox removed!", $COLOR_DEBUG1)
		Else
			Setlog("No GemBox Found!", $COLOR_SUCCESS)
		EndIf
	EndIf

	If $NoBuilders Then
		SetLog("No Builders available to remove Obstacles!")
	Else
		If $Locate = 0 And $g_bChkCleanYard = True And Number($g_aiCurrentLoot[$eLootElixir]) > 50000 Then SetLog("No Obstacles found, Yard is clean!", $COLOR_SUCCESS)
		If $g_iDebugSetlog = 1 Then SetLog("Time: " & Round(__TimerDiff($hObstaclesTimer) / 1000, 2) & "'s", $COLOR_SUCCESS)
	EndIf
	UpdateStats()
	ClickP($aAway, 1, 300, "#0329") ;Click Away

EndFunc   ;==>CleanYard


