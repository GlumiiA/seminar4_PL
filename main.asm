%include "lib.inc"

section .data
    init_msg db "Введите x из [-9;9] в формате x*1000: ", 10, 0
    err_msg db "x не принадлежит [-9;9]", 10, 0
    answer_msg db "y = ", 10, 0
    fmt db "Значение: %f", 10, 0   ; Формат для вывод

    num1000 dq 1000.0
    num9 dq 9.0
    result dq 40.0
    num_neg_6000 dq -6000.0

section .bss
    x resq 1                  ; храним x как вещественное число
    y resq 1                  ; храним y как вещественное число

section .text
extern printf  
global _start
_start:
    mov rdi, init_msg
    call print_string

    sub rsp, 24               ; резервируем место
    mov rdi, rsp
    mov rsi, 24
    call read_word            ; ввод x*1000 

    mov rdi, rax
    call parse_int            ; парсим введенное значение

    ; Проверяем, находится ли x в [-9000;9000]
    cmp rax, -9000            ; -9000
    jl .error_handling
    cmp rax, 9000             ; 9000
    jg .error_handling

    ; Храним x
    mov [x], rax              ; Сохраняем x*1000 в памяти

    ; Загружаем x в регистр FPU как вещественное число
    fild qword [x]            ; преобразуем в FPU (целое->действительное)
    fdiv qword [num1000]      ; y = x / 1000

    ; Проверяем, если x < -6000
    cmp rax, -6000
    jb .less_than_neg_6000

    ; Здесь можно добавить ветку, которая обрабатывает случай, когда x >= -6000

.less_than_neg_6000:
    fld st0                   ; Загружаем x в верхний регистр
    fmul st0, st0             ; x^2
    fchs                       ; Меняем знак
    fld qword [num9]          ; Загружаем 9
    fadd                       ; 9 - x^2
    fabs                       ; Берём абсолютное значение
    fsqrt                      ; Извлекаем квадратный корень

    ; Теперь сохраняем результат в y
    fstp qword [y]            ; Сохраняем y из st0 в y

.print_num:
    mov rdi, answer_msg
    call print_string
    movsd xmm0, qword [y]           
    ; Вывод значения с плавающей точкой
    mov rdi, fmt                    ; Указываем адрес строки формата в rdi
    mov rsi, xmm0                   ; Передаем xmm0 как второй аргумент для printf
    call printf                     ; Вызываем функцию printf

.error_handling:
    mov rdi, err_msg
    call print_err             ; Выводим ошибку
    call exit
