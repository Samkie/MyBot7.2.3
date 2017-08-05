; #FUNCTION# ====================================================================================================================
; Name ..........: unitInfo.au3
; Description ...: Gets various information about units such as the number, location on the bar, clan castle spell type etc...
; Syntax ........:
; Parameters ....:
; Return values .:
; Author ........: @LunaEclipse
; Modified ......: Samkie (17 FEB 2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func unitLocation($kind) ; Gets the location of the unit type on the bar.
	Local $return = -1
	Local $i = 0

	; This loops through the bar array but allows us to exit as soon as we find our match.
	While $i < UBound($g_avAttackTroops)
		; $g_avAttackTroops[$i][0] holds the unit ID for that position on the deployment bar.
		If $g_avAttackTroops[$i][0] = $kind Then
			$return = $i
			ExitLoop
		EndIf

		$i += 1
	WEnd

	; This returns -1 if not found on the bar, otherwise the bar position number.
	Return $return
EndFunc   ;==>unitLocation

Func getUnitLocationArray() ; Gets the location on the bar for every type of unit.
	Local $result[$eCCSpell + 1]
	For $i = 0 To UBound($result) - 1
		$result[$i] = -1
	Next

	; Loop through all the bar and assign it position to the respective unit.
	For $i = 0 To UBound($g_avAttackTroops) - 1
		If Number($g_avAttackTroops[$i][0]) <> -1 Then
			$result[Number($g_avAttackTroops[$i][0])] = $i
		EndIf
	Next
	; Return the positions as an array.
	Return $result
EndFunc   ;==>getUnitLocationArray

Func unitCount($kind) ; Gets a count of the number of units of the type specified.
	Local $numUnits = 0
	Local $barLocation = unitLocation($kind)
	; $barLocation is -1 if the unit/spell type is not found on the deployment bar.
	If $barLocation <> -1 Then
		$numUnits = $g_avAttackTroops[unitLocation($kind)][1]
	EndIf

	Return $numUnits
EndFunc   ;==>unitCount

Func unitCountArray() ; Gets a count of the number of units for every type of unit.
	;Local $result[$eCCSpell + 1] = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
	Local $result[$eCCSpell + 1]
	For $i = 0 To UBound($result) - 1
		$result[$i] = -1
	Next

	; Loop through all the bar and assign its unit count to the respective unit.
	For $i = 0 To UBound($g_avAttackTroops) - 1
		If Number($g_avAttackTroops[$i][1]) > 0 Then
			$result[Number($g_avAttackTroops[$i][0])] = $g_avAttackTroops[$i][1]
		EndIf
	Next

	; Return the positions as an array.
	Return $result
EndFunc   ;==>unitCountArray

; Calculate how many troops to drop for the wave
Func calculateDropAmount($unitCount, $remainingWaves, $position = 0, $minTroopsPerPosition = 1)
;~ 	If $g_iSamM0dDebug = 1 Then Setlog("$unitCount: " & $unitCount)
;~ 	If $g_iSamM0dDebug = 1 Then Setlog("$remainingWaves: " & $remainingWaves)
;~ 	If $g_iSamM0dDebug = 1 Then Setlog("$position: " & $position)
;~ 	If $g_iSamM0dDebug = 1 Then Setlog("$minTroopsPerPosition: " & $minTroopsPerPosition)

	;Local $return = Ceiling(($unitCount+1) / $remainingWaves)
	Local $return = Ceiling($unitCount / $remainingWaves)
	If $position <> 0 Then
		If $unitCount < ($position * $minTroopsPerPosition) Then
			$position = Floor($unitCount / $minTroopsPerPosition)
			$return = $position * $minTroopsPerPosition
		ElseIf $unitCount >= ($position * $minTroopsPerPosition) And $return < ($position * $minTroopsPerPosition) Then
			$return = $position * $minTroopsPerPosition
		EndIf
	EndIf

	Return $return
EndFunc  ;==>calculateDropAmount

; Convert X,Y coords to a point array
Func convertToPoint($x = 0, $y = 0)
	Local $aResult[2] = [0, 0]

	$aResult[0] = $x
	$aResult[1] = $y

	Return $aResult
EndFunc   ;==>convertToPoint


; Adds a new drop vector to the list of already existing vectors
Func addVector(ByRef $vectorArray, $waveNumber, $sideNumber, $startPoint, $endPoint, $dropPoints)
	Local $aDropPoints[$dropPoints][2]

	Local $m = ($endPoint[1] - $startPoint[1]) / ($endPoint[0] - $startPoint[0])
	Local $c = $startPoint[1] - ($m * $startPoint[0])
	Local $stepX = ($endPoint[0] - $startPoint[0]) / ($dropPoints - 1)

	$aDropPoints[0][0] = $startPoint[0]
	$aDropPoints[0][1] = $startPoint[1]

	For $i = 1 to $dropPoints - 2
		$aDropPoints[$i][0] = Round($startPoint[0] + ($i * $stepX))
		$aDropPoints[$i][1] = Round(($m * $aDropPoints[$i][0]) + $c)
	Next

	$aDropPoints[$dropPoints - 1][0] = $endPoint[0]
	$aDropPoints[$dropPoints - 1][1] = $endPoint[1]

	$vectorArray[$waveNumber][$sideNumber] = $aDropPoints
EndFunc   ;==>addVector

; Drop the troops in a standard drop along a vector
Func standardSideDrop($dropVectors, $waveNumber, $sideIndex, $currentSlot, $troopsPerSlot, $useDelay = False)
	Local $delay = ($useDelay = True) ? SetSleep(0): 0
	Local $dropPoints
	$dropPoints = $dropVectors[$waveNumber][$sideIndex]
	If $currentSlot < UBound($dropPoints) Then AttackClick($dropPoints[$currentSlot][0], $dropPoints[$currentSlot][1], $troopsPerSlot, $delay, 0)
EndFunc   ;==>standardSideDrop

; Drop the troops in a standard drop from two points along vectors at once
Func standardSideTwoFingerDrop($dropVectors, $waveNumber, $sideIndex, $currentSlot, $troopsPerSlot, $useDelay = False)
	standardSideDrop($dropVectors, $waveNumber, $sideIndex, $currentSlot, $troopsPerSlot)
	standardSideDrop($dropVectors, $waveNumber, $sideIndex + 1, $currentSlot + 1, $troopsPerSlot, $useDelay)
EndFunc   ;==>twoFingerStandardSideDrop

; Drop the troops from a single point on all sides at once
Func multiSingle($totalDrop, $useDelay = False)
	Local $dropAmount = Ceiling($totalDrop / 4)

	; Progressively adjust the drop amount
	sideSingle($g_aaiTopLeftDropPoints, $dropAmount)
	$totalDrop -= $dropAmount
	$dropAmount = Ceiling($totalDrop / 3)

	; Progressively adjust the drop amount
	sideSingle($g_aaiTopRightDropPoints, $dropAmount)
	$totalDrop -= $dropAmount
	$dropAmount = Ceiling($totalDrop / 2)

	; Progressively adjust the drop amount
	sideSingle($g_aaiBottomRightDropPoints, $dropAmount)
	$totalDrop -= $dropAmount

	; Drop whatever is left
	sideSingle($g_aaiBottomLeftDropPoints, $totalDrop, True)
EndFunc   ;==>multiSingle

; Drop the troops from two points on all sides at once
Func multiDouble($totalDrop, $useDelay = False)
	Local $dropAmount = Ceiling($totalDrop / 4)

	; Progressively adjust the drop amount
	sideDouble($g_aaiTopLeftDropPoints, $dropAmount)
	$totalDrop -= $dropAmount
	$dropAmount = Ceiling($totalDrop / 3)

	; Progressively adjust the drop amount
	sideDouble($g_aaiTopRightDropPoints, $dropAmount)
	$totalDrop -= $dropAmount
	$dropAmount = Ceiling($totalDrop / 2)

	; Progressively adjust the drop amount
	sideDouble($g_aaiBottomRightDropPoints, $dropAmount)
	$totalDrop -= $dropAmount

	; Drop whatever is left
	sideDouble($g_aaiBottomLeftDropPoints, $totalDrop, True)
EndFunc   ;==>multiDouble

; Drop the troops from a single point on a single side
Func sideSingle($dropSide, $dropAmount, $useDelay = False)
	Local $delay = ($useDelay = True) ? SetSleep(0): 0
	;Setlog("AttackClick: " & $dropSide[2][0] & "," &  $dropSide[2][1] & "," & $dropAmount & "," & $delay, $COLOR_ERROR, "Verdana", "7.5", 0)
	AttackClick($dropSide[2][0], $dropSide[2][1], $dropAmount, $delay, 0)
EndFunc   ;==>sideSingle

; Drop the troops from two points on a single side
Func sideDouble($dropSide, $dropAmount, $useDelay = False)
	Local $delay = ($useDelay = True) ? SetSleep(0): 0
	Local $half = Ceiling($dropAmount / 2)
	;Setlog("AttackClick: " & $dropSide[1][0] & "," &  $dropSide[1][1] & "," & $half & ",0", $COLOR_ERROR, "Verdana", "7.5", 0)
	AttackClick($dropSide[1][0], $dropSide[1][1], $half, 0, 0)
	;Setlog("AttackClick: " & $dropSide[3][0] & "," &  $dropSide[3][1] & "," & $dropAmount - $half & "," & $delay, $COLOR_ERROR, "Verdana", "7.5", 0)
	AttackClick($dropSide[3][0], $dropSide[3][1], $dropAmount - $half, $delay, 0)
EndFunc   ;==>sideDouble
