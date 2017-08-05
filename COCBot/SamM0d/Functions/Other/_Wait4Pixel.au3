Func _Wait4Pixel($x, $y, $sColor, $iColorVariation, $iWait = 1000, $iDelay = 100)
	Local $hTimer = __TimerInit()
	Local $iMaxCount = Int($iWait / $iDelay)
	For $i = 1 To $iMaxCount
		ForceCaptureRegion()
		If _ColorCheck(_GetPixelColor($x, $y, True, "Ori Color: " & Hex($sColor,6)), Hex($sColor,6), Int($iColorVariation)) Then Return True
		If _Sleep($iDelay) Then Return False
		If __TimerDiff($hTimer) >= $iWait Then ExitLoop
	Next
	Return False
EndFunc

Func _CheckColorPixel($x, $y, $sColor, $iColorVariation, $bFCapture = True)
	Return _ColorCheck(_GetPixelColor($x, $y, $bFCapture, "Ori Color: " & Hex($sColor,6)), Hex($sColor,6), Int($iColorVariation))
EndFunc