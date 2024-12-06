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

; Сохраняем число в переменной y
    fld dword [y]
    fstp dword [y]         ; Сохраняем число обратно в память

    ; Подготовка для разбора числа IEEE 754
    mov eax, [y]           ; Загружаем число в eax
    ; Извлекаем знак, экспоненту и мантиссу
    shl eax, 1             ; Извлекаем знак
    shr eax, 31            ; Знак в al

    ; Извлечение экспоненты
    shl eax, 1
    shr eax, 23            ; Экспонента в al

    ; Считаем фактическую экспоненту
    sub eax, 127           ; Вычитаем смещение 127

    ; Извлечение мантиссы
    mov ebx, [y]           ; Загружаем оригинальное число еще раз
    and ebx, 0x7FFFFF      ; Извлекаем мантиссу
    or ebx, 0x800000      ; Добавляем 1 к мантиссе (нормализация)

    ; Преобразование мантиссы в десятичное значение
    ; Здесь мантисса еще требует нормализации и деления
    ; Для этого мы можем использовать FPU для удобства
    fld ebx                ; Загружаем мантиссу
    fcomp dword [two_pow_23] ; делим на 2^23
    fstp dword[y]
    mov edi, dword[y]
    call print_int
         

.error_handling:
    mov rdi, err_msg
    call print_err             ; Выводим ошибку
    call exit
