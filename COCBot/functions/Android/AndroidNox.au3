; #FUNCTION# ====================================================================================================================
; Name ..........: AndroidNox
; Description ...: Nox Android functions
; Syntax ........:
; Parameters ....: None
; Return values .: None
; Author ........: Cosote (02-2016)
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func OpenNox($bRestart = False)

	Local $PID, $hTimer, $iCount = 0, $process_killed, $cmdOutput, $connected_to, $cmdPar

	SetLog("Starting " & $g_sAndroidEmulator & " and Clash Of Clans", $COLOR_SUCCESS)

	Local $launchAndroid = (WinGetAndroidHandle() = 0 ? True : False)
	If $launchAndroid Then
		; Launch Nox
		$cmdPar = GetAndroidProgramParameter()
		$PID = LaunchAndroid($g_sAndroidProgramPath, $cmdPar, $g_sAndroidPath)
		If $PID = 0 Then
			SetError(1, 1, -1)
			Return False
		EndIf
	EndIf

	$hTimer = __TimerInit()

	If WaitForRunningVMS($g_iAndroidLaunchWaitSec - __TimerDiff($hTimer) / 1000, $hTimer) Then Return False

	; update ADB port, as that can changes when Nox just started...
	$g_bInitAndroid = True
	InitAndroid()

	; Test ADB is connected
	$connected_to = ConnectAndroidAdb(False, 60 * 1000)
	If Not $g_bRunState Then Return False

	; Wait for boot completed
	If WaitForAndroidBootCompleted($g_iAndroidLaunchWaitSec - __TimerDiff($hTimer) / 1000, $hTimer) Then Return False

	If __TimerDiff($hTimer) >= $g_iAndroidLaunchWaitSec * 1000 Then ; if it took 4 minutes, Android/PC has major issue so exit
		SetLog("Serious error has occurred, please restart PC and try again", $COLOR_ERROR)
		SetLog($g_sAndroidEmulator & " refuses to load, waited " & Round(__TimerDiff($hTimer) / 1000, 2) & " seconds for window", $COLOR_ERROR)
		SetError(1, @extended, False)
		Return False
	EndIf

	SetLog($g_sAndroidEmulator & " Loaded, took " & Round(__TimerDiff($hTimer) / 1000, 2) & " seconds to begin.", $COLOR_SUCCESS)

	Return True

EndFunc   ;==>OpenNox

Func IsNoxCommandLine($CommandLine)
	SetDebugLog($CommandLine)
	$CommandLine = StringReplace($CommandLine, GetNoxRtPath(), "")
	$CommandLine = StringReplace($CommandLine, "Nox.exe", "")
	Local $param1 = StringReplace(GetNoxProgramParameter(), """", "")
	Local $param2 = StringReplace(GetNoxProgramParameter(True), """", "")
	If StringInStr($CommandLine, $param1 & " ") > 0 Or StringRight($CommandLine, StringLen($param1)) = $param1 Then Return True
	If StringInStr($CommandLine, $param2 & " ") > 0 Or StringRight($CommandLine, StringLen($param2)) = $param2 Then Return True
	If StringInStr($CommandLine, "-clone:") = 0 And $param2 = "" Then Return True
	Return False
EndFunc   ;==>IsNoxCommandLine

Func GetNoxProgramParameter($bAlternative = False)
	; see http://en.bignox.com/blog/?p=354
	Local $customScreen = "-resolution:" & $g_iAndroidClientWidth & "x" & $g_iAndroidClientHeight & " -dpi:160"
	Local $clone = """-clone:" & ($g_sAndroidInstance = "" ? $g_avAndroidAppConfig[$g_iAndroidConfig][1] : $g_sAndroidInstance) & """"
	If $bAlternative = False Then
		; should be launched with these parameter
		Return $customScreen & " " & $clone
	EndIf
	If $g_sAndroidInstance = "" Or $g_sAndroidInstance = $g_avAndroidAppConfig[$g_iAndroidConfig][1] Then Return ""
	; default instance gets launched when no parameter was specified (this is the alternative way)
	Return $clone
EndFunc   ;==>GetNoxProgramParameter

Func GetNoxRtPath()
	Local $path = RegRead($g_sHKLM & "\SOFTWARE\BigNox\VirtualBox\", "InstallDir")
	If @error = 0 Then
		If StringRight($path, 1) <> "\" Then $path &= "\"
	EndIf
	If FileExists($path) = 0 Then
		$path = @ProgramFilesDir & "\Bignox\BigNoxVM\RT\"
	EndIf
	If FileExists($path) = 0 Then
		$path = EnvGet("ProgramFiles(x86)") & "\Bignox\BigNoxVM\RT\"
	EndIf
	If FileExists($path) = 0 Then
		$path = EnvGet("ProgramFiles") & "\Bignox\BigNoxVM\RT\"
	EndIf
	SetError(0, 0, 0)
	Return StringReplace($path, "\\", "\")
EndFunc   ;==>GetNoxRtPath

Func GetNoxPath()
	Local $path = RegRead($g_sHKLM & "\SOFTWARE" & $g_sWow6432Node & "\DuoDianOnline\SetupInfo\", "InstallPath")
	If @error = 0 Then
		If StringRight($path, 1) <> "\" Then $path &= "\"
		$path &= "bin\"
	Else
		$path = ""
		SetError(0, 0, 0)
	EndIf
	Return StringReplace($path, "\\", "\")
EndFunc   ;==>GetNoxPath

Func GetNoxAdbPath()
	Local $adbPath = GetNoxPath() & "nox_adb.exe"
	If FileExists($adbPath) Then Return $adbPath
	Return ""
EndFunc   ;==>GetNoxAdbPath

Func InitNox($bCheckOnly = False)
	Local $process_killed, $aRegExResult, $g_sAndroidAdbDeviceHost, $g_sAndroidAdbDevicePort, $oops = 0
	Local $Version = RegRead($g_sHKLM & "\SOFTWARE" & $g_sWow6432Node & "\Microsoft\Windows\CurrentVersion\Uninstall\Nox\", "DisplayVersion")
	SetError(0, 0, 0)

	Local $path = GetNoxPath()
	Local $RtPath = GetNoxRtPath()

	Local $NoxFile = $path & "Nox.exe"
	Local $AdbFile = $path & "nox_adb.exe"
	Local $VBoxFile = $RtPath & "BigNoxVMMgr.exe"

	Local $Files[3] = [$NoxFile, $AdbFile, $VBoxFile]
	Local $File

	For $File In $Files
		If FileExists($File) = False Then
			If Not $bCheckOnly Then
				SetLog("Serious error has occurred: Cannot find " & $g_sAndroidEmulator & " file:", $COLOR_ERROR)
				SetLog($File, $COLOR_ERROR)
				SetError(1, @extended, False)
			EndIf
			Return False
		EndIf
	Next

	; Read ADB host and Port
	If Not $bCheckOnly Then
		InitAndroidConfig(True) ; Restore default config

		$__VBoxVMinfo = LaunchConsole($VBoxFile, "showvminfo " & $g_sAndroidInstance, $process_killed)
		; check if instance is known
		If StringInStr($__VBoxVMinfo, "Could not find a registered machine named") > 0 Then
			; Unknown vm
			SetLog("Cannot find " & $g_sAndroidEmulator & " instance " & $g_sAndroidInstance, $COLOR_ERROR)
			Return False
		EndIf
		; update global variables
		$g_sAndroidProgramPath = $NoxFile
		$g_sAndroidAdbPath = FindPreferredAdbPath()
		If $g_sAndroidAdbPath = "" Then $g_sAndroidAdbPath = GetNoxAdbPath()
		$g_sAndroidVersion = $Version
		$__Nox_Path = $path
		$g_sAndroidPath = $__Nox_Path
		$__VBoxManage_Path = $VBoxFile
		$aRegExResult = StringRegExp($__VBoxVMinfo, ".*host ip = ([^,]+), .* guest port = 5555", $STR_REGEXPARRAYMATCH)
		If Not @error Then
			$g_sAndroidAdbDeviceHost = $aRegExResult[0]
			If $g_iDebugSetlog = 1 Then Setlog("Func LaunchConsole: Read $g_sAndroidAdbDeviceHost = " & $g_sAndroidAdbDeviceHost, $COLOR_DEBUG)
		Else
			$oops = 1
			SetLog("Cannot read " & $g_sAndroidEmulator & "(" & $g_sAndroidInstance & ") ADB Device Host", $COLOR_ERROR)
		EndIf

		$aRegExResult = StringRegExp($__VBoxVMinfo, "name = .*host port = (\d{3,5}), .* guest port = 5555", $STR_REGEXPARRAYMATCH)
		If Not @error Then
			$g_sAndroidAdbDevicePort = $aRegExResult[0]
			If $g_iDebugSetlog = 1 Then Setlog("Func LaunchConsole: Read $g_sAndroidAdbDevicePort = " & $g_sAndroidAdbDevicePort, $COLOR_DEBUG)
		Else
			$oops = 1
			SetLog("Cannot read " & $g_sAndroidEmulator & "(" & $g_sAndroidInstance & ") ADB Device Port", $COLOR_ERROR)
		EndIf

		If $oops = 0 Then
			$g_sAndroidAdbDevice = $g_sAndroidAdbDeviceHost & ":" & $g_sAndroidAdbDevicePort
		Else ; use defaults
			SetLog("Using ADB default device " & $g_sAndroidAdbDevice & " for " & $g_sAndroidEmulator, $COLOR_ERROR)
		EndIf

		;$g_sAndroidPicturesPath = "/mnt/shell/emulated/0/Download/other/"
		;$g_sAndroidPicturesPath = "/mnt/shared/Other/"
		$g_sAndroidPicturesPath = "(/mnt/shared/Other|/mnt/shell/emulated/0/Download/other)"
		$aRegExResult = StringRegExp($__VBoxVMinfo, "Name: 'Other', Host path: '(.*)'.*", $STR_REGEXPARRAYGLOBALMATCH)
		If Not @error Then
			$g_bAndroidSharedFolderAvailable = True
			$g_sAndroidPicturesHostPath = $aRegExResult[UBound($aRegExResult) - 1] & "\"
		Else
			; Check the shared folder 'Nox_share' , this is the default path on last version
			If FileExists(@MyDocumentsDir & "\Nox_share\") then
				$g_bAndroidSharedFolderAvailable = True
				$g_sAndroidPicturesHostPath = @MyDocumentsDir & "\Nox_share\Other\"
				If not FileExists($g_sAndroidPicturesHostPath) then
					; Just in case of 'Other' Folder doesn't exist
					DirCreate($g_sAndroidPicturesHostPath)
				EndIf
			Else
				$g_bAndroidSharedFolderAvailable = False
				$g_bAndroidAdbScreencap = False
				$g_sAndroidPicturesHostPath = ""
				SetLog($g_sAndroidEmulator & " Background Mode is not available", $COLOR_ERROR)
			EndIf
		EndIf

		$__VBoxGuestProperties = LaunchConsole($__VBoxManage_Path, "guestproperty enumerate " & $g_sAndroidInstance, $process_killed)

		Local $v = GetVersionNormalized($g_sAndroidVersion)
		For $i = 0 To UBound($__Nox_Config) - 1
			Local $v2 = GetVersionNormalized($__Nox_Config[$i][0])
			If $v >= $v2 Then
				SetDebugLog("Using Android Config of " & $g_sAndroidEmulator & " " & $__Nox_Config[$i][0])
				$g_sAppClassInstance = $__Nox_Config[$i][1]
				ExitLoop
			EndIf
		Next

		; Update Android Screen and Window
		;UpdateNoxConfig()
	EndIf

	Return True

EndFunc   ;==>InitNox

Func SetScreenNox()

	If Not InitAndroid() Then Return False

	Local $cmdOutput, $process_killed

	; These setting don't stick, so not used and instead using paramter: http://en.bignox.com/blog/?p=354
	; Set width and height
	;$cmdOutput = LaunchConsole($__VBoxManage_Path, "guestproperty set " & $g_sAndroidInstance & " vbox_graph_mode " & $g_iAndroidClientWidth & "x" & $g_iAndroidClientHeight & "-16", $process_killed)
	; Set dpi
	;$cmdOutput = LaunchConsole($__VBoxManage_Path, "guestproperty set " & $g_sAndroidInstance & " vbox_dpi 160", $process_killed)

	AndroidPicturePathAutoConfig(@MyDocumentsDir, "\Nox_share\Other") ; ensure $g_sAndroidPicturesHostPath is set and exists
	If $g_bAndroidSharedFolderAvailable = False And $g_bAndroidPicturesPathAutoConfig = True And FileExists($g_sAndroidPicturesHostPath) = 1 Then
		; remove tailing backslash
		Local $path = $g_sAndroidPicturesHostPath
		If StringRight($path, 1) = "\" Then $path = StringLeft($path, StringLen($path) - 1)
		$cmdOutput = LaunchConsole($__VBoxManage_Path, "sharedfolder remove " & $g_sAndroidInstance & " --name Other", $process_killed)
		$cmdOutput = LaunchConsole($__VBoxManage_Path, "sharedfolder add " & $g_sAndroidInstance & " --name Other --hostpath """ & $path & """  --automount", $process_killed)
	EndIf

	; find Nox conf.ini in C:\Users\User\AppData\Local\Nox and set "Fix window size" to Enable, "Remember size and position" to Disable and screen res also
	Local $sLocalAppData = EnvGet("LOCALAPPDATA")
	Local $sPre = ""
	If $g_sAndroidInstance <> "nox" Then $sPre = "clone_" & $g_sAndroidInstance & "_"
	Local $sConfig = $sLocalAppData & "\Nox\" & $sPre & "conf.ini"
	If FileExists($sConfig) Then
		SetDebugLog("Configure Nox screen config: " & $sConfig)
		IniWrite($sConfig, "setting", "h_resolution", $g_iAndroidClientWidth & "x" & $g_iAndroidClientHeight)
		IniWrite($sConfig, "setting", "h_dpi", "160")
		IniWrite($sConfig, "setting", "fixsize", "true")
		IniWrite($sConfig, "setting", "is_save_pos_and_size", "false")
		IniWrite($sConfig, "setting", "last_player_width", "864")
		IniWrite($sConfig, "setting", "last_player_height", "770")
	Else
		SetDebugLog("Cannot find Nox config to cnfigure screen: " & $sConfig, $COLOR_ERROR)
	EndIf

	Return True

EndFunc   ;==>SetScreenNox

Func RebootNoxSetScreen()

	Return RebootAndroidSetScreenDefault()

EndFunc   ;==>RebootNoxSetScreen

Func CloseNox()

	Return CloseVboxAndroidSvc()

EndFunc   ;==>CloseNox

Func CheckScreenNox($bSetLog = True)

	If Not InitAndroid() Then Return False

	Local $aValues[2][2] = [ _
			["vbox_dpi", "160"], _
			["vbox_graph_mode", $g_iAndroidClientWidth & "x" & $g_iAndroidClientHeight & "-16"] _
			]
	Local $i, $Value, $iErrCnt = 0, $process_killed, $aRegExResult

	For $i = 0 To UBound($aValues) - 1
		$aRegExResult = StringRegExp($__VBoxGuestProperties, "Name: " & $aValues[$i][0] & ", value: (.+), timestamp:", $STR_REGEXPARRAYMATCH)
		If @error = 0 Then $Value = $aRegExResult[0]
		If $Value <> $aValues[$i][1] Then
			If $iErrCnt = 0 Then
				If $bSetLog Then
					SetLog("MyBot doesn't work with " & $g_sAndroidEmulator & " screen configuration!", $COLOR_ERROR)
				Else
					SetDebugLog("MyBot doesn't work with " & $g_sAndroidEmulator & " screen configuration!", $COLOR_ERROR)
				EndIf
			EndIf
			If $bSetLog Then
				SetLog("Setting of " & $aValues[$i][0] & " is " & $Value & " and will be changed to " & $aValues[$i][1], $COLOR_ERROR)
			Else
				SetDebugLog("Setting of " & $aValues[$i][0] & " is " & $Value & " and will be changed to " & $aValues[$i][1], $COLOR_ERROR)
			EndIf
			$iErrCnt += 1
		EndIf
	Next

	; check if shared folder exists
	If AndroidPicturePathAutoConfig(@MyDocumentsDir, "\Nox_share\Other", $bSetLog) Then $iErrCnt += 1

	If $iErrCnt > 0 Then Return False
	Return True

EndFunc   ;==>CheckScreenNox

Func GetNoxRunningInstance($bStrictCheck = True)
	Local $a[2] = [0, ""]
	SetDebugLog("GetAndroidRunningInstance: Try to find """ & $g_sAndroidProgramPath & """")
	For $PID In ProcessesExist($g_sAndroidProgramPath, "", 1) ; find all process
		Local $currentInstance = $g_sAndroidInstance
		; assume last parameter is instance
		Local $CommandLine = ProcessGetCommandLine($PID)
		SetDebugLog("GetNoxRunningInstance: Found """ & $CommandLine & """ by PID=" & $PID)
		Local $aRegExResult = StringRegExp($CommandLine, ".*""-clone:([^""]+)"".*|.*-clone:([\S]+).*", $STR_REGEXPARRAYMATCH)
		If @error = 0 Then
			$g_sAndroidInstance = $aRegExResult[0]
			If $g_sAndroidInstance = "" Then $g_sAndroidInstance = $aRegExResult[1]
			SetDebugLog("Running " & $g_sAndroidEmulator & " instance is """ & $g_sAndroidInstance & """")
		EndIf
		; validate
		If WinGetAndroidHandle() <> 0 Then
			$a[0] = $g_hAndroidWindow
			$a[1] = $g_sAndroidInstance
			Return $a
		Else
			$g_sAndroidInstance = $currentInstance
		EndIf
	Next
	Return $a
EndFunc   ;==>GetNoxRunningInstance

Func RedrawNoxWindow()
	Return SetError(1)
	Local $aPos = WinGetPos($g_hAndroidWindow)
	;_PostMessage_ClickDrag($aPos[0] + Int($aPos[2] / 2), $aPos[1] + 3, $aPos[0] + Int($aPos[2] / 2), $aPos[1] + 53)
	;_PostMessage_ClickDrag($aPos[0] + Int($aPos[2] / 2), $aPos[1] + 53, $aPos[0] + Int($aPos[2] / 2), $aPos[1] + 3)
	Local $aMousePos = MouseGetPos()
	MouseClickDrag("left", $aPos[0] + Int($aPos[2] / 2), $aPos[1] + 3, $aPos[0] + Int($aPos[2] / 2), $aPos[1] + 53, 0)
	MouseClickDrag("left", $aPos[0] + Int($aPos[2] / 2), $aPos[1] + 53, $aPos[0] + Int($aPos[2] / 2), $aPos[1] + 3, 0)
	MouseMove($aMousePos[0], $aMousePos[1], 0)
	;WinMove2($g_hAndroidWindow, "", $AndroidWinPos[0], $AndroidWinPos[1], $aAndroidWindow[0], $aAndroidWindow[1])
	;ControlMove($g_hAndroidWindow, $g_sAppPaneName, $g_sAppClassInstance, 0, 0, $g_iAndroidClientWidth, $g_iAndroidClientHeight)
	;If _Sleep(500) Then Return False ; Just wait, not really required...
	;$new_BSsize = ControlGetPos($g_hAndroidWindow, $g_sAppPaneName, $g_sAppClassInstance)
	$aPos = WinGetPos($g_hAndroidWindow)
	ControlClick($g_hAndroidWindow, "", "", "left", 1, $aPos[2] - 46, 18)
	If _Sleep(500) Then Return False
	$aPos = WinGetPos($g_hAndroidWindow)
	ControlClick($g_hAndroidWindow, "", "", "left", 1, $aPos[2] - 46, 18)
	;If _Sleep(500) Then Return False
EndFunc   ;==>RedrawNoxWindow

Func HideNoxWindow($bHide = True)
	Return EmbedNox($bHide)
EndFunc   ;==>HideNoxWindow

Func EmbedNox($bEmbed = Default)

	If $bEmbed = Default Then $bEmbed = $g_bAndroidEmbedded

	; Find QTool Parent Window
	Local $aWin = _WinAPI_EnumProcessWindows(GetAndroidPid(), False)
	Local $i
	Local $hToolbar = 0

	For $i = 1 To UBound($aWin) - 1
		Local $h = $aWin[$i][0]
		Local $c = $aWin[$i][1]
		If $c = "Qt5QWindowToolSaveBits" Then
			Local $aPos = WinGetPos($h)
			If UBound($aPos) > 2 Then
				; found toolbar
				$hToolbar = $h
			EndIf
		EndIf
	Next

	If $hToolbar = 0 Then
		SetDebugLog("EmbedNox(" & $bEmbed & "): toolbar Window not found, list of windows:" & $c, Default, True)
		For $i = 1 To UBound($aWin) - 1
			Local $h = $aWin[$i][0]
			Local $c = $aWin[$i][1]
			SetDebugLog("EmbedNox(" & $bEmbed & "): Handle = " & $h & ", Class = " & $c, Default, True)
		Next
	Else
		SetDebugLog("EmbedNox(" & $bEmbed & "): $hToolbar=" & $hToolbar, Default, True)
		WinMove2($hToolbar, "", -1, -1, -1, -1, $HWND_NOTOPMOST, 0, False)
		_WinAPI_ShowWindow($hToolbar, ($bEmbed ? @SW_HIDE : @SW_SHOWNOACTIVATE))
	EndIf

EndFunc   ;==>EmbedNox
