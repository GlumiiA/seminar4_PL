%include "lib.inc"

global _start

section .data
    init_msg db "Введите x из [-9;9] в формате x*1000: ", 0
    err_msg db "x не принадлежит [-9;9]", 10, 0

    num1000 dq 1000.0
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

    ; Определяем, меньше ли x -6000
    fld dword [num_neg_6000]
    fcomip st1, st0            ; Сравнить x с -6000

    ; Если x < -6000, продолжаем выполнение. Иначе
    jb .less_than_neg_6000

.less_than_neg_6000:
    ; Вычисляем x^2
    fld st0                    ; Повторно загружаем x
    fmul st(0), st(0)         ; x^2
    fstp qword [y]            ; сохраняем x^2 в памяти

    ; Вычисляем 9 - x^2
    fld qword [y]             ; загружаем x^2
    fld qword 9.0             ; загружаем 9 в FPU
    fsub st1, st0             ; 9 - x^2
    fstp qword [y]            ; сохраняем 9 - x^2

    ; Проверяем, не отрицательное ли значение
    fld qword [y]             ; загружаем (9 - x^2)
    fcomip st0, st1           ; Сравниваем с 0
    jbe .error_handling        ; Если y <= 0, выходим с ошибкой

.calculate_sqrt:
    ; Вычисляем корень из y
    fld qword [y]             ; загружаем (9 - x^2)
    fsqrt                      ; вычисляем корень
    fchs                       ; Изменяем знак
    fstp qword [y]            ; сохраняем в y

.print_num:
    fld qword [y]             ; загружаем результат
    fld qword [num1000]       ; загружаем 1000
    fdiv                       ; y / 1000
    fstp qword [y]            ; сохраняем результат

    mov rdi, [y]              ; Загружаем результат для вывода
    call print_int             ; Выводим результат
    jmp .exit

.error_handling:
    mov rdi, err_msg
    call print_err             ; Выводим ошибку
    jmp .exit
