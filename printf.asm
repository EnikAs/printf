section .text
global _start

_start:;str_from, '+', str, 42, 42, 42, 42, "love", 3802, 100, 33, 15
                push 15
                push 33
                push 100
                push 3802
                push StrToPrint
                push 0
                push 0
                push 0
                push 0
                push StrToPrint
                push '+'
                push StrToPrint

                mov rcx, BUFFER_SIZE
                mov rax, InpStr
                mov rbx, Buffer

                call BufWrite

                mov rax, 4
                mov rbx, 1
                mov rcx, Buffer
                mov rdx, BUFFER_SIZE
                int 0x80

                jmp end_of_prog           ; this is the end))

BufWrite:
;===============================================================
; This function copy input string into printf's buffer and call
; special function for '%' operators
; INPUT:        RCX - input string size
;               RAX - addr of input string
;               RBX - addr of buffer
;
; OUTPUT:       buffer = input string
; DESTR:        
;===============================================================
                pop r10                   ; return addr
.loop_strt:
                cmp byte [rax], '%'
                je .op_hndl               ; if it is '%' => it is operator => call operator handler
                jmp .not_op
.op_hndl:
                inc rax
                call OpHandler            ; TODO: call of operator handler
                jmp .loop_end

.not_op:
                mov dh, byte [rax]
                mov byte [rbx], dh

                inc rax
                inc rbx

.loop_end:
                loop .loop_strt


.ret            push r10
                ret
;===============================================================

OpHandler:
;===============================================================
; This function is made for special operators 
; For example '%c' will put next argument in buffer as a char
; '%s'          - as a string
; '%d'          - as a decimal
; '%x'          - as a hex
; '%o'          - as a vos'mirichnoe chislo
; '%b'          - as a binary
; '%%'          - just put '%' symbol in buffer
;
; INPUT:        RAX - addr of input string current position
;               RBX - addr of buffer corrent position
; DESTR:        RCX, RDX, r8
;===============================================================
                pop r11                   ; return addr
                push rcx                  ; save rcx value
                mov rcx, NUMBER_OF_OP
                xor rdx, rdx
                xor r8, r8

.loop_strt:
                mov byte dl, [rax]
                cmp byte dl, [OPmas + r8]
                je .equal                
                add r8, 1
                loop .loop_strt
                jmp .default              ; TODO: default case      

.equal:
                jmp [JMPmas + r8 * 8]

.default:       jmp jopa_happend
;---------------------------------------------
.op_is_c:       pop rcx
                pop rdx
                mov byte [rbx], dl

                inc rbx
                inc rax
                jmp .return
;---------------------------------------------
.op_is_perc:    pop rcx
                mov byte dl, '%'
                mov byte [rbx], dl

                inc rbx
                inc rax
                jmp .return
;---------------------------------------------
.strcmp_no_zero:
                pop rcx
                pop r8
.zero_skip:     
                mov dl, [r8]
                cmp byte dl, '$'
                je .it_is_zero
                cmp byte dl, '0'
                jne .strncmp_loop
                inc r8
                jmp .zero_skip

.op_is_s:       pop rcx
                pop r8                         ; addr of str to input
                                                
.strncmp_loop   mov dl, byte [r8]
                cmp byte dl, '$'
                je .strncmp_loop_end
                mov byte [rbx], dl

                inc rbx
                inc r8
                jmp .strncmp_loop

.strncmp_loop_end:
                inc rax

                jmp .return
.it_is_zero:
                mov dl, '0'
                mov byte [rbx], dl
                inc rbx
                jmp .strncmp_loop_end
;---------------------------------------------
.op_is_x:       pop rcx                        ; разобраться с rcx
                pop rdx
                push rcx
                push rdx

                mov r8, 15
                mov rcx, 15

                mov r9, HexTransform
                and rdx, 0x0F
                add r9, rdx
                mov dl, byte [r9]
                mov byte [HexToPrint + r8], byte dl

                add r8, -1

.hex_loop_strt:
                pop rdx
                shr rdx, 4
                push rdx

                mov r9, HexTransform
                and rdx, 0x0F
                add r9, rdx
                mov dl, byte [r9]
                mov byte [HexToPrint + r8], dl

                add r8, -1
                loop .hex_loop_strt 


                pop rdx

                pop rcx
                push HexToPrint
                push rcx

                
                jmp .strcmp_no_zero

                pop rcx
                jmp .return
;---------------------------------------------
.op_is_d:       pop rcx
                pop r8                         ; now in r8 decimal number to print
                push rcx
                push rax
                mov r9, 19
                mov rcx, 20

.dec_loop_strt:
                mov rdx, r8
                xor edx, edx
                mov rax, r8
                mov r8, 10                     
                div r8                         ; теперь отсаток от деления на 10 лежит в rdx, частное - в rax
                mov r8, rax
                add rdx, '0'
                mov byte [DecToPrint + r9], dl

                add r9, -1
                loop .dec_loop_strt

                pop rax
                pop rcx
                push DecToPrint
                push rcx

                jmp .strcmp_no_zero

                jmp .return
;---------------------------------------------
.op_is_o:       pop rcx                        ; разобраться с rcx
                pop rdx
                push rcx
                push rdx

                mov r8, 21
                mov rcx, 21

                mov r9, '0'
                and rdx, 0x07
                add r9, rdx
                mov rdx, r9
                mov byte [OctToPrint + r8], byte dl

                add r8, -1

.oct_loop_strt:
                pop rdx
                shr rdx, 3
                push rdx

                mov r9, '0'
                and rdx, 0x07
                add r9, rdx
                mov rdx, r9
                mov byte [OctToPrint + r8], dl

                add r8, -1
                loop .oct_loop_strt 


                pop rdx

                pop rcx
                push OctToPrint
                push rcx

                jmp .strcmp_no_zero

                pop rcx
                jmp .return
;---------------------------------------------
.op_is_b:       pop rcx
                pop rdx
                push rcx

                mov rcx, 64

                cmp rdx, 0
                je .it_is_zero_bin

.zero_skip_loop:
                shl rdx, 1
                jc .one_detected
                loop .zero_skip_loop                
                
.binary_loop:   shl rdx, 1
                jc .one_detected 

.zero_detected: mov byte [rbx], '0'
                jmp .skip

.one_detected:  mov byte [rbx], '1'
                
.skip:          inc rbx
                loop .binary_loop

.end_of_bin:    inc rax 

                pop rcx
                jmp .return
.it_is_zero_bin:
                mov byte [rbx], '0'
                inc rbx
                jmp .end_of_bin
;---------------------------------------------

.return:        push r11
                ret
;==============================================================
end_of_prog:
                mov rax, 1
                xor rbx, rbx
                int 0x80
;==============================================================
jopa_happend:
                mov rax, 4
                mov rbx, 1
                mov rcx, jopa
                mov rdx, 44
                int 0x80
                jmp end_of_prog
;==============================================================

section .data

NUMBER_OF_OP    equ 7
BUFFER_SIZE     equ 200
;---------------------------------------------
JMPmas:         dq  OpHandler.op_is_c, OpHandler.op_is_perc, OpHandler.op_is_s, OpHandler.op_is_x, OpHandler.op_is_d, OpHandler.op_is_o, OpHandler.op_is_b
OPmas:          db "c%sxdob"
;---------------------------------------------
Buffer:         times BUFFER_SIZE db '_'
;---------------------------------------------
HexTransform:   db "0123456789ABCDEF"
;---------------------------------------------
StrToPrint:     db "Asskar$"
HexToPrint:     db "0000000000000000$"
OctToPrint:     db "0000000000000000000000$"
DecToPrint:     db "00000000000000000000$"
;---------------------------------------------
jopa:           db "default case is running... full jopa happend", 0x0a

;string %s|char %c|percent %%|binary %b|hex %x|oct %o|dec is %d
InpStr:         db "im %s and i listen %% %c %s %%. %d in d its %o in o %b in b %x in x",0x0a,"I %s %x %d%%%c%b",0x0a,"$", 0x0a
InpStrLen       equ $ - InpStr
Trash_clean:    times BUFFER_SIZE db ' '
;_printf ("im %s and i listen %% %c %s %%. %d in d its %o in o %b in b %x in x\n I %s %x %d%%%c%b\n$", str_from, '+', str, 42, 42, 42, 42, "love", 3802, 100, 33, 15);