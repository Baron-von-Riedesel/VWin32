
	.386
	.model flat,stdcall
	option casemap:none
	option proc:private
	option dotname

ifdef @pe_file_flags
	include pe.inc
else
VxDCall2 proto :dword, :dword, :dword
endif

;--- 09/2001, v1.0: initial
;--- 10/2002, v1.0.1: "unit" added
;--- 01/2006, v1.1: source changed to use WinInc include files 
;--- 01/2007, v1.2: set focus to committed memory item on startup
;--- 05/2022: v1.3: removed WinInc dependancy.

	.nolist
	.nocref
	include winbase.inc
	include winuser.inc
	.list
	.cref

	include rsrc.inc

FillMemory equ <RtlFillMemory>

@ macro procname,args:VARARG
ifnb <args>
	invoke procname,args
else
	invoke procname
endif
	exitm <eax>
	endm

	.data

szFStr1 db "%u",0
szFStr2 db "%u %s",0
szFStr3 db "%u,%u %s",0
szMemStat db "VWin32 Memory Status",0
szUnitPg	db "Pg",0
szUnitKb	db "kB",0
szUnitMB	db "MB",0

DemandInfoStruct struct
Lin_Total_Count dd ?; /* total address space in pages */
Phys_Count		dd ?; /* Count of phys pages */
Free_Count		dd ?; /* Count of free phys pages */
Unlock_Count	dd ?; /* Count of unlocked Phys Pages */
Linear_Base_Addr	dd ?; /* Base of pageable address space */
Lin_Total_Free	dd ?; /* free address space in pages */
Page_Faults		dd ?; /* total page faults */
Page_Ins		dd ?; /* calls to pagers to page in a page */
Page_Outs		dd ?; /* calls to pagers to page out a page*/
Page_Discards	dd ?; /* pages discarded w/o calling pager */
Instance_Faults	dd ?; /* instance page faults */
PagingFileMax	dd ?; /* maximum # of pages that could be in paging file */ file */
PagingFileInUse	dd ?; /* # of pages of paging file currently in use */
Commit_Count	dd ?; /* Total committed memory, in pages */
Reserved1		dd ?; /* Reserved for expansion */
Reserved2		dd ?; /* Reserved for expansion */
DemandInfoStruct ends


dis		DemandInfoStruct <>
dis2	DemandInfoStruct <-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1>

g_dwFlags	dd 0
g_dwID		dd 0
g_dwMode	dd 0
g_pszUnit	LPSTR 0

MODE_PAGES	equ 0
MODE_KB		equ 1
MODE_MB		equ 2

	.code

memcpy proc c uses esi edi pDest:ptr,pSrc:ptr,dwSize:dword
	mov edi,pDest
	mov esi,pSrc
	mov ecx,dwSize
	rep movsb
	ret
memcpy endp

SetText proc hWnd:HWND, dwID:dword, dwValue:dword, dwUnit:DWORD

local	szStr[128]:byte

	mov eax,dwValue
	.if (dwUnit)
		.if (g_dwMode == MODE_MB)
			mov cl,al
			shr eax,8
			push eax
			movzx eax,cl
			mov cl,26
			div cl
			movzx ecx,al
			pop eax
			invoke wsprintf,addr szStr,addr szFStr3,eax,ecx,g_pszUnit
		.else
			.if (g_dwMode == MODE_KB)
				shl eax,2
			.endif
			invoke wsprintf,addr szStr,addr szFStr2,eax,g_pszUnit
		.endif
	.else
		invoke wsprintf,addr szStr,addr szFStr1,eax
	.endif

	invoke SetDlgItemText,hWnd,dwID,addr szStr
    
;--- if dialog window is minimized, set its window text    
;--- with the text from the control which has the focus
    
	mov eax,dwID
	.if ((g_dwFlags == SIZE_MINIMIZED) && (eax == g_dwID))
		invoke lstrlen, addr szStr
		lea ecx,szStr
		add ecx,eax
		mov edx,sizeof szStr
		sub edx,eax

		mov word ptr [ecx],' '
		inc ecx
		dec edx

		mov eax,g_dwID
		sub eax,IDC_EDIT1
		add eax,IDC_STATIC1
		invoke GetDlgItemText, hWnd, eax, ecx, edx
		invoke SetWindowText, hWnd, addr szStr
	.endif
	ret
SetText endp

;*** PutData: update output data

PutData proc hWnd:HWND


	invoke VxDCall2,0001001Eh,addr dis,NULL

	mov eax,dis.Lin_Total_Count
	.if (eax != dis2.Lin_Total_Count)
		invoke SetText,hWnd,IDC_EDIT1,eax,1
	.endif
	mov eax,dis.Lin_Total_Free
	.if (eax != dis2.PagingFileMax)
		invoke SetText,hWnd,IDC_EDIT10,eax,1
	.endif

	mov eax,dis.Phys_Count
	.if (eax != dis2.Lin_Total_Count)
		invoke SetText,hWnd,IDC_EDIT2,eax,1
	.endif
	mov eax,dis.Free_Count
	.if (eax != dis2.Free_Count)
		invoke SetText,hWnd,IDC_EDIT3,eax,1
	.endif
	mov eax,dis.Unlock_Count
	.if (eax != dis2.Unlock_Count)
		invoke SetText,hWnd,IDC_EDIT4,eax,1
	.endif
	mov eax,dis.Page_Faults
	.if (eax != dis2.Page_Faults)
		invoke SetText,hWnd,IDC_EDIT5,eax,0
	.endif
	mov eax,dis.Page_Ins
	.if (eax != dis2.Page_Ins)
		invoke SetText,hWnd,IDC_EDIT6,eax,0
	.endif
	mov eax,dis.Page_Outs
	.if (eax != dis2.Page_Outs)
		invoke SetText,hWnd,IDC_EDIT7,eax,0
	.endif
	mov eax,dis.Page_Discards
	.if (eax != dis2.Page_Discards)
		invoke SetText,hWnd,IDC_EDIT8,eax,0
	.endif
	mov eax,dis.Instance_Faults
	.if (eax != dis2.Instance_Faults)
		invoke SetText,hWnd,IDC_EDIT9,eax,0
	.endif
	mov eax,dis.PagingFileInUse
	.if (eax != dis2.PagingFileInUse)
		invoke SetText,hWnd,IDC_EDIT11,eax,1
	.endif
if 1
	mov eax,dis.PagingFileMax
	.if (eax != dis2.PagingFileMax)
		invoke SetText,hWnd,IDC_EDIT13,eax,1
	.endif
endif
	mov eax,dis.Commit_Count
	.if (eax != dis2.Commit_Count)
		invoke SetText,hWnd,IDC_EDIT12,eax,1
	.endif

	invoke memcpy,addr dis2,addr dis,sizeof DemandInfoStruct
	ret

PutData endp

;*** main dialog proc

DialogProc proc hWnd:HWND,message:dword,wParam:WPARAM,lParam:LPARAM


	mov eax,message
	.if (eax == WM_INITDIALOG)
		mov g_dwMode,MODE_MB
		mov g_pszUnit,offset szUnitMB
		invoke CheckRadioButton,hWnd,IDC_RADIO1,IDC_RADIO3,IDC_RADIO3
		invoke PutData,hWnd
		invoke SetTimer,hWnd,1,1000,NULL
		invoke GetDlgItem, hWnd, IDC_EDIT12
		invoke SetFocus, eax
		mov eax,0
	.elseif (eax == WM_TIMER)
		invoke PutData,hWnd
		xor eax,eax
	.elseif (eax == WM_SIZE)
		mov eax,wParam
		mov g_dwFlags,eax
		.if (eax == SIZE_RESTORED)
			invoke SetWindowText, hWnd, addr szMemStat
		.else
			invoke FillMemory,addr dis2, sizeof DemandInfoStruct, -1
		.endif
	.elseif (eax == WM_CLOSE)
		invoke KillTimer,hWnd,1
		invoke EndDialog,hWnd,0
		xor eax,eax
	.elseif (eax == WM_COMMAND)
		movzx eax,word ptr wParam+0
		movzx ecx,word ptr wParam+2
		.if (eax == IDCANCEL)
			invoke PostMessage,hWnd,WM_CLOSE,0,0
		.elseif (eax == IDC_RADIO1)
			mov g_dwMode,MODE_PAGES
			mov g_pszUnit,offset szUnitPg
			invoke FillMemory,addr dis2, sizeof DemandInfoStruct, -1
		.elseif (eax == IDC_RADIO2)
			mov g_dwMode,MODE_KB
			mov g_pszUnit,offset szUnitKb
			invoke FillMemory,addr dis2, sizeof DemandInfoStruct, -1
		.elseif (eax == IDC_RADIO3)
			mov g_dwMode,MODE_MB
			mov g_pszUnit,offset szUnitMB
			invoke FillMemory,addr dis2, sizeof DemandInfoStruct, -1
		.elseif (ecx == EN_SETFOCUS)
			mov g_dwID,eax
		.endif
		xor eax,eax
	.else
		xor eax,eax
	.endif
	ret	
DialogProc endp

;*** WinMain: display main dialog

WinMain proc hInstance:HINSTANCE,hPrev:HINSTANCE,lpszCmdLine:LPSTR, iCmdShow:dword

	invoke DialogBoxParam,hInstance,IDD_DIALOG1,0,DialogProc,0
	ret
WinMain endp


WinMainCRTStartup proc public

	invoke ExitProcess,@(WinMain,@(GetModuleHandle,NULL),0,0,0)

WinMainCRTStartup endp

	end WinMainCRTStartup

