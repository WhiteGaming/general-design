#SingleInstance, Force
SetWorkingDir %A_ScriptDir%
#NoEnv
SetBatchLines, -1

; Uncomment if Gdip.ahk is not in your standard library
;#Include, Gdip.ahk

; Menu
Menu, Tray, NoStandard
Menu, Tray, Add, Open Settings, OpenSettings
Menu, Tray, Add, Reload Settings, LoadSettings
Menu, Tray, Add, Save Position, SavePosition
Menu, Tray, Add, Reload Script, Reload
Menu, Tray, Add
Menu, Tray, Add, Exit, Exit

settings_file := "settings.ini"
Gosub, LoadSettings

; Start gdi+
If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}
OnExit, Exit

; Create Gui for background and each key
Loop, 9
{
	; Create persistent background image
	Gui, %A_Index%: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
	Gui, %A_Index%: Show, NA
	hwnd%A_Index% := WinExist()
}

; Get a bitmap from the image
bGround :=  Gdip_CreateBitmapFromFile(imgDir "base.png")
btnA :=     Gdip_CreateBitmapFromFile(imgDir "a.png")
btnZ :=     Gdip_CreateBitmapFromFile(imgDir "z.png")
btnQ :=     Gdip_CreateBitmapFromFile(imgDir "q.png")
btnS :=     Gdip_CreateBitmapFromFile(imgDir "s.png")
btnD :=     Gdip_CreateBitmapFromFile(imgDir "d.png")
btnE :=     Gdip_CreateBitmapFromFile(imgDir "e.png")
btnCtrl :=  Gdip_CreateBitmapFromFile(imgDir "ctrl.png")
btnSpace := Gdip_CreateBitmapFromFile(imgDir "space.png")

; Check to ensure we actually got a bitmap from the file, in case the file was corrupt or some other error occured
If !bGround
{
	MsgBox, 48, File loading error!, Could not load the image specified
	ExitApp
}

ShowPress(bGround, 1)
OnMessage(0x201, "WM_LBUTTONDOWN")
Gdip_DisposeImage(bGround)
Return

;#######################################################################

Exit:
	; gdi+ may now be shutdown on exiting the program
	Gdip_Shutdown(pToken)
	ExitApp
Return

ClearObjects:
	; Select the object back into the hdc
	SelectObject(hdc, obm)

	; Now the bitmap may be deleted
	DeleteObject(hbm)

	; Also the device context related to the bitmap may be deleted
	DeleteDC(hdc)

	; The graphics may now be deleted
	Gdip_DeleteGraphics(G)
Return



~*q::     ShowPress(btnQ, 2)
~*z::     ShowPress(btnZ, 3)
~*e::     ShowPress(btnE, 4)
~*a::     ShowPress(btnA, 5)
~*s::     ShowPress(btnS, 6)
~*d::     ShowPress(btnD, 7)
~*LCtrl:: ShowPress(btnCtrl, 8)
~*Space:: ShowPress(btnSpace, 9)

~q Up::     Gui, 2:  Cancel
~z Up::     Gui, 3:  Cancel
~e Up::     Gui, 4:  Cancel
~a Up::     Gui, 5:  Cancel
~s Up::     Gui, 6:  Cancel
~d Up::     Gui, 7:  Cancel
~LCtrl Up:: Gui, 8:  Cancel
~Space Up:: Gui, 9:  Cancel

ShowPress(img, guiNum)
{
	global
	; Get the width and height of the bitmap we have just created from the file
	; This will be the dimensions that the file is
	Width := Gdip_GetImageWidth(img), Height := Gdip_GetImageHeight(img)

	; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
	; We are creating this "canvas" at half the size of the actual image
	; We are halving it because we want the image to show in a gui on the screen at half its dimensions
	hbm := CreateDIBSection(Width//2, Height//2)

	; Get a device context compatible with the screen
	hdc := CreateCompatibleDC()

	; Select the bitmap into the device context
	obm := SelectObject(hdc, hbm)

	; Get a pointer to the graphics of the bitmap, for use with drawing functions
	G := Gdip_GraphicsFromHDC(hdc)

	Gdip_SetInterpolationMode(G, 7)

	Gdip_DrawImage(G, img, 0, 0, Width//2, Height//2, 0, 0, Width, Height)

	; Update the second window. (Note hwnd2 not hwnd1.)
	UpdateLayeredWindow(hwnd%GuiNum%, hdc, posX, posY, Width//2, Height//2)

	OnMessage(0x201, "WM_LBUTTONDOWN")
	OnMessage(0x203, "WM_LBUTTONDBLCLK")

	Gosub, ClearObjects

	Gui %GuiNum%: Show, NA
	Return
}

; This function is called every time the user clicks on the gui
; The PostMessage will act on the last found window (this being the gui that launched the subroutine, hence the last parameter not being needed)
WM_LBUTTONDOWN()
{
	PostMessage, 0xA1, 2
}

SavePosition:
	WinGetPos, winX, winY, , , wasd-overlay.ahk
	path := ini_load(ini, settings_file)
	ini_replaceValue(ini, "zqsd", "posX", winX)
	ini_replaceValue(ini, "zqsd", "posY", winY)
	posX := winX
	posY := winY
	ini_save(ini, settings_file)
	msgbox, Position Saved.
	Return

Reload:
	Reload
	Return

OpenSettings:
	Run % settings_file
	Return

LoadSettings:
	If FileExist(settings_file)
	{
		path := ini_load(ini, settings_file)
		imgDir := ini_getValue(ini, Wasd, "imgDir")
		posX := ini_getValue(ini, Wasd, "posX")
		posY := ini_getValue(ini, Wasd, "posY")
	}
	Else
	{
		Msgbox, settings.ini not found!
		ExitApp
	}
	Return
