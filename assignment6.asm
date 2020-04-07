TITLE assignment6.asm    (assignment6.asm)

; Author: Rowan Simmons
; OSU email address: simmonli@oregonstate.edu
; Course number/section: CS271
; Project Number: 6             
; Description: Designing, implementing, and calling low-level I/O procedures. 

INCLUDE Irvine32.inc

;------------------------------------------------------------------------------
;macro getString
;get string from user
;------------------------------------------------------------------------------
getString	MACRO prompt, strNum
	push	ecx
	push	edx
	mov		edx, OFFSET prompt
	call	WriteString 
	mov		edx, OFFSET strNum
	mov		ecx, (SIZEOF strNum)-1
	call	ReadString
	pop		edx
	pop		ecx
ENDM

;------------------------------------------------------------------------------
;macro displayString
;display string to user
;------------------------------------------------------------------------------
displayString MACRO buffer
	push	edx
	mov		edx, OFFSET buffer
	call	WriteString
	pop		edx
ENDM

;------------------------------------------------------------------------------
;macro writePrompt
;display prompts to user
;------------------------------------------------------------------------------
writePrompt MACRO buffer
	push	edx
	mov		edx, OFFSET buffer
	call	WriteString
	call	CrLf
	pop		edx
ENDM

MAX = 10; maximum user can enter in array

.data
; (insert variable definitions here)
intro_1			BYTE		"Designing low-level I/0			by Rowan Simmons", 0
intro_2			BYTE		"Please enter 10 unsigned decimal integers. Each number needs to be ", 0
intro_3			BYTE		"small enough to fit inside a 32 bit register. After you have finished ", 0
intro_4			BYTE		"inputting the raw numbers, I will display a list of the integers ", 0
intro_5			BYTE		"the sum of the integers, and their average values.", 0
error		    BYTE		"ERROR: You did not enter an unsigned number, or your number was too big.", 0
stringNum       BYTE		30 DUP(? )
userNum         DWORD		?
prompt			BYTE		"Please enter an unsigned number: ", 0
goodBye			BYTE		"Results certified by Rowan Simmons. Good-bye.", 0
numsList		BYTE		"You entered the following numbers: ", 0
sumList         BYTE		"The sum of these numbers is: ", 0
avgList			BYTE		"The rounded average is: ", 0
sum		        DWORD		?
array			DWORD		MAX DUP(?); array of numbers
spaces		    BYTE		" ", 0


;***************************************************
; Main Procedure
; description: start program, call procedures
;***************************************************
.code
main PROC
	writePrompt		OFFSET intro_1
	call			CrLf
	writePrompt		OFFSET intro_2
	writePrompt		OFFSET intro_3
	writePrompt		OFFSET intro_4
	writePrompt		OFFSET intro_5
	call			CrLf
;------------------------------------------------read input from user and store in string
	push			OFFSET stringNum
	push			MAX
	push 			OFFSET error
	push			OFFSET array
	call			readVal
;------------------------------------------------display string to consol
	call			CrLf
	writePrompt		numsList
	push			OFFSET array
	push			OFFSET spaces
	push			MAX
	push			sum
	call			writeVal
;------------------------------------------------display sum and average
	call			CrLf
	push			OFFSET avgList
	push			OFFSET sumList
	call			displaySum_Avg
;------------------------------------------------departing message
	call			CrLf
	call			CrLf
	push			OFFSET goodBye
	call			farewell
;------------------------------------------------end program
exit

main ENDP


;*********************************************************************
;description: calls macro to read input from user and converts to string
;receives: array address, number string, max value(10)
;returns: input string
;pre-condition: none
;registers changed: edi, ecx, eax, ebp, ebp
;*********************************************************************
readVal PROC

	push		ebp
	mov			ebp, esp
	mov			edi, [ebp + 8]					;array
	mov			ecx, [ebp+16]					;loop counter MAX

getNumbers:
	push		ecx
	mov			eax, 00000000
	mov			ebx, 00000000

	getString	prompt, stringNum

	mov			esi, [ebp+20]
	mov			ecx, eax
	mov			edx, 00000000
	cld

getLength:									; to get number of digits
	lodsb									; get first digit
	cmp				al, 0					; if equal to \0, end of string, jump out
	je				lengthKnown				
	inc				ecx						; increment digit counter
	jmp				getLength				; loop until \0

lengthKnown:
	cmp				ecx, 10					; 32 bit number will fit in 10 digits, so any more digits means the number is invalid
	jg				notValid					; invalid if 11 digits or more
	mov				esi, [ebp+20]			; point at front of string
	add				esi, ecx				; add number of digits, pointing to \0
	dec				esi		
	std

keepGoing:
	lodsb

	cmp			al, 0
	cmp			al, 48							;0=48
	jl			notValid
	cmp			al, 57							;9= 57
	jg			notValid
	jmp			validNum
	
notValid:
	pop			ecx 
	writePrompt	error
	jmp			getNumbers 

validNum:
	sub			al, 48							;byte->number
	lea			ebx, [ebx + ebx * 4]
	lea			ebx, [eax + ebx * 2]
	loop		keepGoing
	mov			[edi], ebx
	pop			ecx 
	add			edi, 4							;go to next spot in array
	loop		getNumbers


	pop ebp
	ret 16

readVal ENDP


;*********************************************************************
;description: converts string and calls macro to write string 
;receives: array address, max (10), sum 
;returns: sum value, converted string
;pre-condition: input is input and validated and stored in array
;registers changed: edi, ecx, eax, ebp, ebp, ebx, edx
;*********************************************************************
writeVal PROC
	push		ebp
	mov			ebp, esp
	mov			edi, [ebp+20]		;array
	mov			esi, [ebp + 20]

	mov			ecx, [ebp+12]		;max
	mov			ebx, 0
	cld 

looper:
	lodsd
	push		eax
	add			[ebp + 8], eax		;sum
	mov			ebx, 10

digits:
	mov			edx, 00000000
	div			ebx					;10
	add			edx, 48				;back to num
	push		edx 
	test		eax, eax
	jz			done
	jmp			digits

done:
	pop			edx

keepGoing:
	stosb		
	mov			userNum, edx
	displayString userNum
	pop			edx
	cmp			esp, ebp
	je			onWard
	jmp			keepGoing

onWard:
	mov			eax, 00000000	
	stosb
	add			ebx, eax
	push		edx
	mov			edx, [ebp+16]		;display msg
	call		WriteString
	pop			edx
	loop		looper

	mov			eax, [ebp+8]		;sum

pop ebp
ret 20

writeVal ENDP

;***********************************************************************************************
;description: prints sum and average to console 
;receives: sum
;returns: sum and average
;pre-condition: input is input and validated and stored in array, and sum is found and stored 
;registers changed: ecx, eax, ebp, ebx, edx
;***********************************************************************************************
displaySum_Avg PROC

	push		ebp
	mov			ebp, esp
	call		CrLf
	mov			edx, [ebp+8]			;display msg
	call		WriteString
	call		WriteDec				;print sum
	call		CrLf
	jmp			displayAvg

displayAvg:
	call		CrLf
	mov			edx, [ebp+12]			;display msg
	call		WriteString
	mov			ecx, eax
	mov			eax, ecx
	mov			ebx, 10
	mov			edx, 0
	div			ebx
	call		WriteDec				;display average

	pop			ebp
	ret			8

displaySum_Avg ENDP

;**************************************************************************
;description: says goodble
;receives: address for goodbye text
;registers changed: ebp, edx
;**************************************************************************

farewell PROC
	push		ebp
	mov			ebp, esp
	mov			edx, [ebp + 8]
	call		WriteString
	call		CrLf

	pop			ebp
	ret			4

farewell ENDP

END main
