;# Copyright (c) 2018 tevador
;#
;# This file is part of RandomX.
;#
;# RandomX is free software: you can redistribute it and/or modify
;# it under the terms of the GNU General Public License as published by
;# the Free Software Foundation, either version 3 of the License, or
;# (at your option) any later version.
;#
;# RandomX is distributed in the hope that it will be useful,
;# but WITHOUT ANY WARRANTY; without even the implied warranty of
;# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;# GNU General Public License for more details.
;#
;# You should have received a copy of the GNU General Public License
;# along with RandomX.  If not, see<http://www.gnu.org/licenses/>.

_RANDOMX_EXECUTE_PROGRAM SEGMENT PAGE READ EXECUTE

PUBLIC executeProgram

executeProgram PROC
	; REGISTER ALLOCATION:
	; rax -> temporary
	; rbx -> beginning of VM stack
	; rcx -> temporary
	; rdx -> temporary
	; rsi -> convertible_t& scratchpad
	; rdi -> "mx"
	; rbp	-> "ic"
	; rsp -> end of VM stack
	; r8 	-> "r0"
	; r9 	-> "r1"
	; r10 -> "r2"
	; r11 -> "r3"
	; r12 -> "r4"
	; r13 -> "r5"
	; r14 -> "r6"
	; r15 -> "r7"
	; xmm0 -> temporary
	; xmm1 -> temporary
	; xmm2 -> "f2"
	; xmm3 -> "f3"
	; xmm4 -> "f4"
	; xmm5 -> "f5"
	; xmm6 -> "f6"
	; xmm7 -> "f7"
	; xmm8 -> "f0"
	; xmm9 -> "f1"
	; xmm10 -> absolute value mask

	; STACK STRUCTURE:
	;   |
	;   |
	;   | saved registers
	;   |
	;   v
	; [rbx+8] RegisterFile& registerFile
	; [rbx+0] uint8_t* dataset
	;   |
	;   |
	;   | VM stack
	;   |
	;   v
	; [rsp] last element of VM stack

	; store callee-saved registers
	push rbx
	push rbp
	push rdi
	push rsi
	push r12
	push r13
	push r14
	push r15
	sub rsp, 80
	movdqu xmmword ptr [rsp+64], xmm6
	movdqu xmmword ptr [rsp+48], xmm7
	movdqu xmmword ptr [rsp+32], xmm8
	movdqu xmmword ptr [rsp+16], xmm9
	movdqu xmmword ptr [rsp+0], xmm10

	; function arguments
	push rcx                    ; RegisterFile& registerFile
	mov edi, dword ptr [rdx]    ; "mx"
	mov rax, qword ptr [rdx+8]  ; uint8_t* dataset
	push rax
	mov rsi, r8                 ; convertible_t* scratchpad

	mov rbx, rsp                ; beginning of VM stack
	mov ebp, 1048577            ; number of VM instructions to execute + 1

	xorps xmm10, xmm10
	cmpeqpd xmm10, xmm10
	psrlq xmm10, 1		          ; mask for absolute value = 0x7fffffffffffffff7fffffffffffffff

	; reset rounding mode
	mov dword ptr [rsp-8], 40896
	ldmxcsr dword ptr [rsp-8]

	; load integer registers
	mov r8, qword ptr [rcx+0]
	mov r9, qword ptr [rcx+8]
	mov r10, qword ptr [rcx+16]
	mov r11, qword ptr [rcx+24]
	mov r12, qword ptr [rcx+32]
	mov r13, qword ptr [rcx+40]
	mov r14, qword ptr [rcx+48]
	mov r15, qword ptr [rcx+56]

	; load register f0 hi, lo
	xorps xmm8, xmm8
	cvtsi2sd xmm8, qword ptr [rcx+72]
	pslldq xmm8, 8
	cvtsi2sd xmm8, qword ptr [rcx+64]

	; load register f1 hi, lo
	xorps xmm9, xmm9
	cvtsi2sd xmm9, qword ptr [rcx+88]
	pslldq xmm9, 8
	cvtsi2sd xmm9, qword ptr [rcx+80]

	; load register f2 hi, lo
	xorps xmm2, xmm2
	cvtsi2sd xmm2, qword ptr [rcx+104]
	pslldq xmm2, 8
	cvtsi2sd xmm2, qword ptr [rcx+96]

	; load register f3 hi, lo
	xorps xmm3, xmm3
	cvtsi2sd xmm3, qword ptr [rcx+120]
	pslldq xmm3, 8
	cvtsi2sd xmm3, qword ptr [rcx+112]

	lea rcx, [rcx+64]

	; load register f4 hi, lo
	xorps xmm4, xmm4
	cvtsi2sd xmm4, qword ptr [rcx+72]
	pslldq xmm4, 8
	cvtsi2sd xmm4, qword ptr [rcx+64]

	; load register f5 hi, lo
	xorps xmm5, xmm5
	cvtsi2sd xmm5, qword ptr [rcx+88]
	pslldq xmm5, 8
	cvtsi2sd xmm5, qword ptr [rcx+80]

	; load register f6 hi, lo
	xorps xmm6, xmm6
	cvtsi2sd xmm6, qword ptr [rcx+104]
	pslldq xmm6, 8
	cvtsi2sd xmm6, qword ptr [rcx+96]

	; load register f7 hi, lo
	xorps xmm7, xmm7
	cvtsi2sd xmm7, qword ptr [rcx+120]
	pslldq xmm7, 8
	cvtsi2sd xmm7, qword ptr [rcx+112]

	; program body

	include program.inc

rx_finish:
	; unroll the stack
	mov rsp, rbx

	; save VM register values
	pop rcx
	pop rcx
	mov qword ptr [rcx+0], r8
	mov qword ptr [rcx+8], r9
	mov qword ptr [rcx+16], r10
	mov qword ptr [rcx+24], r11
	mov qword ptr [rcx+32], r12
	mov qword ptr [rcx+40], r13
	mov qword ptr [rcx+48], r14
	mov qword ptr [rcx+56], r15
	movdqa xmmword ptr [rcx+64], xmm8
	movdqa xmmword ptr [rcx+80], xmm9
	movdqa xmmword ptr [rcx+96], xmm2
	movdqa xmmword ptr [rcx+112], xmm3
	lea rcx, [rcx+64]
	movdqa xmmword ptr [rcx+64], xmm4
	movdqa xmmword ptr [rcx+80], xmm5
	movdqa xmmword ptr [rcx+96], xmm6
	movdqa xmmword ptr [rcx+112], xmm7

	; load callee-saved registers
	movdqu xmm10, xmmword ptr [rsp]
	movdqu xmm9, xmmword ptr [rsp+16]
	movdqu xmm8, xmmword ptr [rsp+32]
	movdqu xmm7, xmmword ptr [rsp+48]
	movdqu xmm6, xmmword ptr [rsp+64]
	add rsp, 80
	pop r15
	pop r14
	pop r13
	pop r12
	pop rsi
	pop rdi
	pop rbp
	pop rbx

	; return
	ret
	
TransformAddress MACRO reg32, reg64
;# Transforms the address in the register so that the transformed address
;# lies in a different cache line than the original address (mod 2^N).
;# This is done to prevent a load-store dependency.
;# There are 3 different transformations that can be used: x -> 9*x+C, x -> x+C, x -> x^C
	lea reg32, [reg64+reg64*8+127]  ;# C = -119 -110 -101 -92 -83 -74 -65 -55 -46 -37 -28 -19 -10 -1 9 18 27 36 45 54 63 73 82 91 100 109 118 127
	;lea reg32, [reg64-128]         ;# C = all except -7 to +7
	;xor reg32, -8                  ;# C = all except 0 to 7
ENDM

ReadMemoryRandom MACRO spmask, float
;# IN     ecx = random 32-bit address
;# OUT    rax = 64-bit integer return value
;# OUT   xmm0 = 128-bit floating point return value
;# GLOBAL rbp = "ic" number of instructions until the end of the program
;# GLOBAL rbx = address of the dataset address
;# GLOBAL rsi = address of the scratchpad
;# GLOBAL rdi = "mx" random 32-bit dataset address
;# MODIFY rcx, rdx
LOCAL L_prefetch, L_read, L_return
	mov eax, ebp
	and al, 63
	jz short L_prefetch     ;# "ic" divisible by 64 -> prefetch
	xor edx, edx
	cmp al, 14
	je short L_read         ;# "ic" = 14 (mod 64) -> random read
	cmovb edx, ecx          ;# "ic" < 14 (mod 64) -> modify random read address
	xor edi, edx
L_return:
	and ecx, spmask                 ;# limit address to the specified scratchpad size
IF float
	cvtdq2pd xmm0, qword ptr [rsi+rcx*8]
ELSE
	mov rax, qword ptr [rsi+rcx*8]
ENDIF
	ret	
L_prefetch:
	mov rax, qword ptr [rbx]        ;# load the dataset address
	and edi, -64                    ;# align "mx" to the start of a cache line
	prefetchnta byte ptr [rax+rdi]
	jmp short L_return
L_read:
	push rcx
	TransformAddress ecx, rcx       ;# TransformAddress function
	and ecx, spmask-7               ;# limit address to the specified scratchpad size aligned to multiple of 8
	call rx_read_dataset
	pop rcx
	jmp short L_return
ENDM

ALIGN 64
rx_readint_l1:
ReadMemoryRandom 2047, 0

ALIGN 64
rx_readint_l2:
ReadMemoryRandom 32767, 0

ALIGN 64
rx_readfloat_l1:
ReadMemoryRandom 2047, 1

ALIGN 64
rx_readfloat_l2:
ReadMemoryRandom 32767, 1

ALIGN 64
rx_read_dataset:
;# IN     rcx = scratchpad index - must be divisible by 8
;# GLOBAL rbx = address of the dataset address
;# GLOBAL rsi = address of the scratchpad
;# GLOBAL rdi = "mx" random 32-bit dataset address
;# MODIFY rax, rcx, rdx
	mov rax, qword ptr [rbx]        ;# load the dataset address
	lea rcx, [rsi+rcx*8]            ;# scratchpad cache line
	lea rax, [rax+rdi]              ;# dataset cache line	              
	mov rdx, qword ptr [rax+0]      ;# load first dataset quadword (prefetched into the cache by now)
	xor qword ptr [rcx+0], rdx      ;# XOR the dataset item with a scratchpad item, repeat for the rest of the cacheline
	mov rdx, qword ptr [rax+8]
	xor qword ptr [rcx+8], rdx
	mov rdx, qword ptr [rax+16]
	xor qword ptr [rcx+16], rdx
	mov rdx, qword ptr [rax+24]
	xor qword ptr [rcx+24], rdx
	mov rdx, qword ptr [rax+32]
	xor qword ptr [rcx+32], rdx
	mov rdx, qword ptr [rax+40]
	xor qword ptr [rcx+40], rdx
	mov rdx, qword ptr [rax+48]
	xor qword ptr [rcx+48], rdx
	mov rdx, qword ptr [rax+56]
	xor qword ptr [rcx+56], rdx
	ret
executeProgram ENDP

_RANDOMX_EXECUTE_PROGRAM ENDS

END
