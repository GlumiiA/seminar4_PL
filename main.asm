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
call parse_int       
; проверяем находиться ли x в [-9;9] 
cmp rax, -9000       ; -9 * 1000
jl .error_handling
cmp rax, 9000       ; 9 * 1000
jg .error_handling
mov rdi, rax

; Загружаем x в регистр FPU
fld dword [x]        ; загрузить x в стек FPU
fild dword [x]      ; преобразовать в FPU (целое->действительное)

fld dword [x]        ; загрузить x 
fldz                 
fld dword [num_neg_6000] 
fcomip st1, st0      ; Сравнить x с -6000, и удалить st0
fstsw ax             
sahf                  
jb .less_than_neg_6000    ; Если x < -6000

.less_than_neg_6000:
    ; Вычисляем x^2
    fld dword [x]           
    fmul st(0), st(0)   
    fstp dword [y]      ; сохраняем x^2 в памяти

    ; Вычисляем 9 - x^2
    fld dword [y]       ; загружаем x^2
    fld qword 9.0       ; загружаем 9 в FPU
    fsub st(1), st(0)   ; 9 - x^2
    fstp dword [y] ; сохраняем 9 - x^2

    ; Проверяем, не отрицательное ли значение
    fcomip st(0), st(1)
    fstsw ax
    sahf
    jae .calculate_sqrt
    ; Если значение под корнем отрицательное, выводим сообщение об ошибке
    jmp .error_handling

.calculate_sqrt:
    ; Вычисляем корень из y_value
    fld dword [y]  ; загружаем (9 - x^2)
    fsqrt                 ; вычисляем sqrt
    fchs  ; Изменяем знак
    fstp y                ; сохраняем в y

.print_num:
    fld dword [y]         
    fld dword [num1000]       
    ; Делим верхний регистр на следующий
    fdiv                       
    fstp dword [y]   

    mov edi, dword[y]
    call print_int  
    jmp .exit
    add esp, 8 ; очищаем стек

.error_handling:
    mov rdi, err_msg
    call print_err
