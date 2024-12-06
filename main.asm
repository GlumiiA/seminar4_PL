%include "lib.inc"

global _start

section .data

init_msg: db "Введите x из [-9;9] в формате x*1000", 10, 0
err_msg: db "x не принадлежит [-9;9]", 10, 0

num1000 dq 1000.0
k_interval_0_3 dq -1.0
b_interval_0_3 dq 3.0
result dq 40

section .bss
    x resd 1      ; храним x
    y resq 1      ; храним y (в формате с плавающей точкой)

section .text
_start:
mov rdi, init_msg
call print_string ;

sub rsp, 24 ; резервируем место
mov rdi, rsp
mov rsi, 24
call read_word  ; ввод x*1000 

mov rdi, rax    
call parse_int       ; спарсили в инт
; проверяем находиться ли x в [-9;9] 
cmp rax, -9000       ; -9 * 1000
jl .error_handling
cmp rax, 9000       ; 9 * 1000
jg .error_handling
mov rdi, rax

; Загружаем x в регистр FPU
fld dword [x]        ; загрузить x в стек FPU
fild dword [x]      ; преобразовать в FPU (целое->действительное)

.error_handling:
    mov rdi, err_msg
    call print_err
