
;--- definitions if jwasm is used with -pe

;--- set subsystem to "windows"
;--- the PE header is stored in section .hdr$2

.hdr$2 segment DWORD FLAT public 'HDR'
	org 5Ch ;position to IMAGE_NT_HEADER32.OptionalHeader.Subsystem
	dw 2    ;2=subsystem windows
.hdr$2 ends

;--- VxDCall2 is to be imported by number

	option dllimport:<kernel32.dll>
VxDCall2 proto service:dword, :dword, :dword
	option dllimport:none

	alias <kernel32.3> = <VxDCall2>

