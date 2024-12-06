%include "lib.inc"

global _start

section .data
    init_msg db "Введите x из [-9;9] в формате x*1000: ", 10, 0
    err_msg db "x не принадлежит [-9;9]", 10, 0
    answer_msg db "y = ", 10, 0

    num1000 dq 1000.0
    num9 dq 9.0
    k_interval_0_3 dq -1.0
    b_interval_0_3 dq 3.0
    result dq 40.0
    num_neg_6000 dq -6000.0  ; Объявление переменной для -6000

section .bss
    x resd 1                   ; храним x
    y resq 1                   ; храним y (в формате с плавающей точкой)

section .text
_start:
    mov rdi, init_msg
    call print_string

    sub rsp, 24                ; резервируем место
    mov rdi, rsp
    mov rsi, 24
    call read_word             ; ввод x*1000 

    mov rdi, rax
    call parse_int             ; парсим введенное значение
    ; Проверяем находится ли x в [-9000;9000]
    cmp rax, -9000             ; -9000
    jl .error_handling
    cmp rax, 9000              ; 9000
    jg .error_handling
    ; Храним x
    mov [x], rax               ; Сохраняем x*1000 в памяти

    ; Загружаем x в регистр FPU как вещественное число
    fild dword [x]             ; преобразуем в FPU (целое->действительное)

    cmp rax, -6000           
    ; Если x < -6000, продолжаем выполнение. Иначе
    jb .less_than_neg_6000

.less_than_neg_6000:
    call int_to_float
    mov dword[y], 9
	fild dword[y]
	fadd
	fmul st0, st0 ; Вычисляем x^2
	fchs ; Изменяем знак
	fild dword[y]
	fadd ; загружаем (9 - x^2)
	fabs
	fsqrt
	jmp .print_num    

.print_num:
    mov rdi, answer_msg
    call print_string
    fstp dword[x]
    mov edi, dword[x]
    call print_int	
    call exit

.error_handling:
    mov rdi, err_msg
    call print_err             ; Выводим ошибку
    call exit

int_to_float:
    mov dword[x], eax
	fild dword[x]
    fld dword[num1000]	
    fdiv                       ; y / 1000
	ret

