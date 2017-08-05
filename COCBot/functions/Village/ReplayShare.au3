; #FUNCTION# ====================================================================================================================
; Name ..........: ReplayShare
; Description ...: This function will publish replay if mimimun loot reach
; Syntax ........:
; Parameters ....: None
; Return values .: None
; Author ........: Sardo (2015-06)
; Modified ......: Sardo 2015-08, MonkeyHunter(2106-1), CodeSlinger69 (2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once

Func ReplayShare($last = 1)
	Local $dtLocal = _Date_Time_GetLocalTime()
	Local $dLastShareDate = _DateAdd("n", -60, _Date_Time_SystemTimeToDateTimeStr($dtLocal, 1))

	; remark: In sharing message "<n>" was replaced by numbers of searches
	;         Use this option  with caution or risk being reported
	Local $txtMessage, $tNew

	If $g_bShareAttackEnable = False Then Return

	If $last = 1 Then
		;--  open page of attacks -------------------------------------------------------------
		ClickP($aAway, 1, 0, "#0235") ;Click Away
		If _Sleep($DELAYREPLAYSHARE2) Then Return ;
		SetLog("Share Replay: Opening Messages Page...", $COLOR_INFO)
		If $g_iDebugSetlog = 1 Then Setlog("$last= " & $last, $COLOR_DEBUG)
		ClickP($aMessageButton, 1, 0, "#0236") ;Click Messages Button
		If _Sleep($DELAYREPLAYSHARE3) Then Return
		Click(380, 94 + $g_iMidOffsetY, 1, 0, "#0237") ; Click Attack Log Tab, move down 30 pixels for 860x780
		If _Sleep($DELAYREPLAYSHARE3) Then Return

		; publish last replay ----------------------------------------------------------------
		_CaptureRegion()

		; check if exist replay queue ----------------------------------------------------
		Local $FileListQueueName = _FileListToArray($g_sProfileTempPath, "Village*.png", 1) ; list files to an array.
		If $g_iDebugSetlog = 1 Then Setlog("Top share button pixel color 70D4E8 or BBBBBB: " & _GetPixelColor(500, 156 + $g_iMidOffsetY), $COLOR_DEBUG)
		If _ColorCheck(_GetPixelColor(500, 156 + $g_iMidOffsetY), Hex(0x70D4E8, 6), 10) = True And Not (IsArray($FileListQueueName)) Then
			;button replay blue, moved down 30 for 860x780
			Setlog("Ok, sharing!")
			Click(500, 156 + $g_iMidOffsetY, 1, 0, "#0238") ; Click Share Button, moved down 30 for 860x780
			If _Sleep($DELAYREPLAYSHARE1) Then Return
			Click(300, 120, 1, 0, "#0239") ;Select text for write comment
			If _Sleep($DELAYREPLAYSHARE1) Then Return

			;compose message txt
			Local $smessage = $g_sShareMessage
			$smessage = StringReplace($smessage, @LF, "")
			$smessage = StringReplace($smessage, @CR, "|")
			While StringInStr($smessage, "||")
				$smessage = StringReplace($smessage, "||", "|")
			WEnd
			Local $smessagearray = StringSplit($smessage, "|")
			If @error Then
				$txtMessage = $smessagearray[1]
			Else
				$txtMessage = $smessagearray[Random(1, $smessagearray[0], 1)]
			EndIf
			$txtMessage = StringReplace($txtMessage, "<n>", StringFormat("%s", $g_iSearchCount))
			ControlSend($g_hAndroidWindow, "", "", $txtMessage, 0)
			If _Sleep($DELAYREPLAYSHARE1) Then Return
			Click(530, 210 + $g_iMidOffsetY, 1, 0, "#0240") ;Click Send Button, moved down 30 for 860x780
			$tNew = _Date_Time_GetLocalTime()
			$dLastShareDate = _Date_Time_SystemTimeToDateTimeStr($tNew, 1)
		Else
			If _ColorCheck(_GetPixelColor(500, 156 + $g_iMidOffsetY), Hex(0xbbbbbb, 6), 6) = True Or IsArray($FileListQueueName) Then
				;button replay gray.. insert village in queue, moved down 30 for 860x780
				If IsArray($FileListQueueName) Then
					SetLog("Others replay in queue, Share Later Last Replay")
				Else
					Setlog("Cannot Share Now... retry later.")
				EndIf
				_CaptureRegion(87, 149 + $g_iMidOffsetY, 87 + 100, 149 + 20 + $g_iMidOffsetY)
				Local $Date = @YEAR & "-" & @MON & "-" & @MDAY
				Local $Time = @HOUR & "." & @MIN
				Local $iSaveFile = _GDIPlus_ImageSaveToFile($g_hBitmap, $g_sProfileTempPath & "Village_" & $Date & "_" & $Time & "^" & StringFormat("%s", $g_iSearchCount) & ".png")
				If Not ($iSaveFile) Then SetLog("An error occurred putting screenshot in queue", $COLOR_ERROR)
				Click(763, 86 + $g_iMidOffsetY, 1, 0, "#0241") ; Close  page
				If _Sleep($DELAYREPLAYSHARE2) Then Return ;
			Else
				;button not found, abort
				Setlog("Cannot Share Now... retry later.", $COLOR_ERROR)
			EndIf
		EndIf
		$g_bShareAttackEnableNow = False ;reset variable
	Else
		$tNew = _Date_Time_GetLocalTime()
		If _DateDiff("n", $dLastShareDate, _Date_Time_SystemTimeToDateTimeStr($tNew, 1)) > 30 Then ; latest replay share >30 minutes
			; check if exist replay to publish ----------------------------------------------------
			Local $FileListName = _FileListToArray($g_sProfileTempPath, "Village*.png", 1) ; list files to an array.
			Local $x, $t, $tmin = 0
			If Not ((Not IsArray($FileListName)) Or (@error = 1)) Then

				; get oldest filename -----------------------------------------------------------------
				Local $FileListDate
				For $x = 1 To $FileListName[0] ;array position 0 number of files found
					$t = FileGetTime($g_sProfileTempPath & $FileListName[$x], 1, 1)
					If $tmin = 0 Then
						$tmin = $t
						$FileListDate = $x
					Else
						If $t < $tmin Then
							$t = $tmin
							$FileListDate = $x
						EndIf
					EndIf
					;SetLog("Debug " & $FileListname[$x] & " t:" & $t & "tmin:  " & $tmin & " x:" & $x )
				Next
				; oldest filename: $FileListName[$FileListDate]
				;SetLog("Debug oldest filename: " & $FileListName[$FileListDate] )

				;--  open page of attacks -------------------------------------------------------------
				ClickP($aAway, 1, 0, "#0242") ;Click Away
				If _Sleep($DELAYREPLAYSHARE2) Then Return ;
				SetLog("Share Replay: Opening Messages Page...", $COLOR_INFO)
				If $g_iDebugSetlog = 1 Then Setlog("$last= " & $last, $COLOR_DEBUG)
				ClickP($aMessageButton, 1, 0, "#0243") ; Click Messages Button
				If _Sleep($DELAYREPLAYSHARE3) Then Return
				Click(380, 94 + $g_iMidOffsetY, 1, 0, "#0244") ; Click Attack Log Tab, moved down 30 for 860x780
				If _Sleep($DELAYREPLAYSHARE3) Then Return
				_CaptureRegion()
				If $g_iDebugSetlog = 1 Then Setlog("Top share button pixel color 70D4E8 or BBBBBB: " & _GetPixelColor(500, 156 + $g_iMidOffsetY), $COLOR_DEBUG)
				If _ColorCheck(_GetPixelColor(500, 156 + $g_iMidOffsetY), Hex(0x70D4E8, 6), 10) = True Then
					;button replay blue,, moved down 30 for 860x780
					Setlog("Ok, sharing!")
					Local $VilLoc, $VilX, $VilY, $VilTol
					For $VilTol = 0 To 20
						If $VilLoc = 0 Then
							$VilLoc = _ImageSearch($g_sProfileTempPath & $FileListName[$FileListDate], 1, $VilX, $VilY, $VilTol) ;
							;SetLog( "Debug: Searching " & $FileListName[$FileListDate] & " tollerance" & $VilTol   & " - Found=" & $VilLoc)
							If $VilLoc = 1 And $VilX > 35 And $VilY < 610 Then
								;SetLog("Debug: Found!, position: (" & $VilX & "," & $VilY &")", $COLOR_SUCCESS)
								Click(500, $VilY, 1, 0, "#0245") ;Click Share Button
								If _Sleep($DELAYREPLAYSHARE1) Then Return
								Click(300, 120, 1, 0, "#0246") ;Select text for write comment
								If _Sleep($DELAYREPLAYSHARE1) Then Return
								; read searchcount
								Local $a = StringInStr($FileListName[$FileListDate], "^")
								Local $b = StringInStr($FileListName[$FileListDate], ".png")
								Local $stry = "0"
								If $a > 0 And $b > 0 Then $stry = StringMid($FileListName[$FileListDate], $a + 1, $b - $a - 1)
								$g_iSearchCount = $stry

								;compose message txt
								Local $smessage = $g_sShareMessage
								$smessage = StringReplace($smessage, @LF, "")
								$smessage = StringReplace($smessage, @CR, "|")
								While StringInStr($smessage, "||")
									$smessage = StringReplace($smessage, "||", "|")
								WEnd
								Local $smessagearray = StringSplit($smessage, "|")
								If @error Then
									$txtMessage = $smessagearray[1]
								Else
									$txtMessage = $smessagearray[Random(1, $smessagearray[0], 1)]
								EndIf
								$txtMessage = StringReplace($txtMessage, "<n>", StringFormat("%s", $g_iSearchCount))
								ControlSend($g_hAndroidWindow, "", "", $txtMessage, 0)
								If _Sleep($DELAYREPLAYSHARE1) Then Return
								Click(500, 210 + $g_iMidOffsetY, 1, 0, "#0247") ;Click Send Button, moved down 30 for 860x780
								$tNew = _Date_Time_GetLocalTime()
								$dLastShareDate = _Date_Time_SystemTimeToDateTimeStr($tNew, 1)

								;only for test copy..
								Local $iCopy = FileCopy($g_sProfileTempPath & $FileListName[$FileListDate], $g_sProfileTempPath & "shared_" & $FileListName[$FileListDate])
								If Not ($iCopy) Then Setlog("An error occurred copying a temporary file", $COLOR_ERROR)
								;delete
								Local $iDelete = FileDelete($g_sProfileTempPath & $FileListName[$FileListDate])
								If Not ($iDelete) Then Setlog("An error occurred deleting a temporary file", $COLOR_ERROR)
								If _Sleep($DELAYREPLAYSHARE4) Then Return
								Return True
							EndIf
						EndIf
					Next
					If $VilLoc = 0 Then
						;delete file not found
						;only for test copy..
						Local $iCopy = FileCopy($g_sProfileTempPath & $FileListName[$FileListDate], $g_sProfileTempPath & "discard_" & $FileListName[$FileListDate])
						If Not ($iCopy) Then Setlog("An error occurred copying a temporary file", $COLOR_ERROR)
						;delete
						Local $iDelete = FileDelete($g_sProfileTempPath & $FileListName[$FileListDate])
						If Not ($iDelete) Then Setlog("An error occurred deleting a temporary file", $COLOR_ERROR)
					EndIf

				Else
					If _ColorCheck(_GetPixelColor(500, 156 + $g_iMidOffsetY), Hex(0xbbbbbb, 6), 6) = True Then
						;button replay gray.. insert village in queue, , moved down 30 for 860x780
						Setlog("Cannot Share Now... retry later.")
						Click(763, 86 + $g_iMidOffsetY, 1, 0, "#0248") ; Close  page
						$tNew = _Date_Time_GetLocalTime()
						$dLastShareDate = _DateAdd("n", -20, _Date_Time_SystemTimeToDateTimeStr($tNew, 1))
						If _Sleep($DELAYREPLAYSHARE2) Then Return ;
					Else
						;button not found, abort
						Setlog("Button Share not found, abort.", $COLOR_ERROR)
						Click(763, 86 + $g_iMidOffsetY, 1, 0, "#0249") ; Close  page
						If _Sleep($DELAYREPLAYSHARE2) Then Return ;
					EndIf
				EndIf

				Return True
			EndIf
		EndIf ; >30 min
	EndIf ;last=1
	If _Sleep($DELAYREPLAYSHARE2) Then Return
	checkMainScreen(False) ; check for screen errors while running function

EndFunc   ;==>ReplayShare
