; Conways Game of Life

section .data

LIVE equ 35
DEAD equ 46
ROWS equ 32
COLS equ 2*ROWS
grid1 times ROWS*COLS db DEAD
grid2 times ROWS*COLS db DEAD
clrscreen db "clear",0

section .bss
nextgrid resb 8
grid resb 8

extern system
extern srand
extern rand
extern time
extern usleep
global main
global updateGrid
global drawToGrid
global renderGrid

section .text

main:
	push rbp
	mov rbp,rsp
	sub rsp,16
	mov qword [rbp-16],grid1
	mov qword [rbp-8],ROWS*COLS

	mov rax,grid1
	mov [grid],rax
	mov rax,grid2
	mov [nextgrid],rax

	mov rdi,0x0
	call time
	mov rdi,rax
	call srand
        
	grid_init_loop:
		call rand
		mov edx,0
		mov ebx,2
		div ebx
		mov rcx,LIVE
		cmp edx,1
		cmove rbx,rcx
		mov rax,qword [rbp-16]
		mov byte [rax],bl
		inc qword [rbp-16]
		dec qword [rbp-8]
		jnz grid_init_loop

	main_loop:
		mov rdi,clrscreen
		call system
		call renderGrid
		call updateGrid
		mov rdi,200000
		call usleep
		jmp main_loop

	pop rbp
	mov eax,0x0
	ret

updateGrid:
	; actually just 3 rules
	; if(live == 3) cell = true;
	; else if(live == 4) cell = cell;
	; else cell = false;

	; N1(-1 -1)  N2(-1  0)  N3(-1  1)
	; N4( 0 -1)             N5( 0  1)
	; N6( 1 -1)  N7( 1  0)  N8( 1  1)

	push rbp
	mov rbp,rsp
	mov qword [rbp-24],0 ; u64 row = 0
	mov qword [rbp-16],0 ; u64 col = 0
	mov qword [rbp-8],0  ; u64 live = 0

	updateGrid_loop:
		mov rdi,qword [rbp-24]
		dec rdi
		and rdi,ROWS-1
		mov r8,3
		mov r9,3
		neighbour_row_loop:
			mov rsi,qword [rbp-16]
			dec rsi
			and rsi,COLS-1
			neighbour_col_loop:
				mov eax,edi
				mov ecx,COLS
				mul ecx
				; result of mul is in eax
				add rax,rsi
				add rax,[grid]

				mov rbx,0
				mov rcx,1
				cmp byte [rax],byte LIVE
				cmove rbx,rcx
				add qword [rbp-8],rbx

				; update neighbour col
				inc rsi
				and rsi,COLS-1
				dec r9
				jnz neighbour_col_loop

			; update neighbour row
			mov r9,3
			inc rdi
			and rdi,ROWS-1
			dec r8
			jnz neighbour_row_loop
		
		mov rdi,qword [rbp-24]
		mov rsi,qword [rbp-16]
		mov eax,edi
		mov ecx,COLS
		mul ecx
		; result of mul is in eax
		add rax,rsi
		add rax,[nextgrid]
		mov rbx,[grid]
		add rbx,rsi
		mov bl, byte [rbx]

		cmp qword [rbp-8],3 ; if live == 3, cell lives
		jne live_not_3
		mov byte [rax],LIVE
		je live_check_end
		live_not_3:
		cmp qword [rbp-8],4 ; else if live == 4, cell remains same
		mov byte [rax],bl
		je live_check_end
		mov byte [rax],DEAD ; else cell dies

		live_check_end:

		mov dword [rbp-8],0

		inc qword [rbp-16]
		cmp qword [rbp-16],COLS
		jne updateGrid_loop

		mov qword [rbp-16],0
		inc qword [rbp-24]
		cmp qword [rbp-24],ROWS
		jne updateGrid_loop
	
	mov rax,[grid]
	mov rbx,[nextgrid]
	mov [grid],rbx
	mov [nextgrid],rax

	pop rbp
	ret

renderGrid:
	push rbp
	mov rbp,rsp
	mov byte [rbp-0x9],byte 0xa
	mov qword [rbp-0x8],qword 0x0
	renderGrid_loop:
		mov rax,1
		mov rdi,1
		mov rsi,[grid]
		add rsi,qword [rbp-0x8]
		mov rdx,COLS
		syscall
		mov rax,1
		mov rdi,1
		mov rsi,rbp
		sub rsi,0x9
		mov rdx,0x1
		syscall
		add qword [rbp-0x8],qword COLS
		cmp qword [rbp-0x8],qword ROWS*COLS
		jne renderGrid_loop
	pop rbp
	ret
