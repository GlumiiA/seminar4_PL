section .rodata
%define SYS_EXIT 60
%define SYS_READ 0
%define SYS_WRITE 1
%define STDIN 0
%define STDOUT 1
%define STDERR 2

section .text
global exit
global string_length
global print_string
global print_string_error
global print_char
global print_newline
global print_uint
global print_int
global print_err
global string_equals
global read_char
global read_word
global read_string
global parse_uint
global parse_int
global string_copy
global print_float

 
; Принимает код возврата и завершает текущий процесс
exit:
    mov     rax, SYS_EXIT                        ; номер системного вызова 'exit' 
    syscall 

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    xor rax, rax
    .loop:
        cmp byte [rdi + rax], 0
        je .retLength
        inc rax
        jmp .loop
    .retLength:
        ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
    push rdi 
    call string_length 
    pop rdi;
    mov rsi, rdi
    mov rdi, STDOUT ; stdout
    mov rdx, rax ; длина строки
    mov rax, SYS_WRITE ; write
    syscall

    ret

print_err:
    sub rsp, 8 
    call string_length              ; вычисление длины сообщения об ошибке
    add rsp, 8 
    mov rdx, rax
    mov rsi, rdi
    mov rdi, STDERR
    mov rax, SYS_WRITE

; Принимает код символа и выводит его в stdout
print_char:
    push rdi     
    mov rsi, rsp        
    mov rdx, 1
    mov rax, SYS_WRITE ; write
    mov rdi, STDOUT ; stdout 
    syscall
    pop rdi

    ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
    mov rdi, '\n'
    jmp print_char 

; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint: 
    push rbx  ; 16      
    mov rax, rdi 
    mov rbx, 10 ; делитель
    mov rsi, rsp ; сохраняем указатель на строку
    sub rsp, 40   ; выделим место в стеке
    dec rsi
    mov byte [rsi], 0 ; указатель на нуль-терминированную строку
    .loopDiv:
        xor rdx, rdx
        div rbx ; делим на rbx
        add dl, '0' ; Переводим остаток в ASCII
        dec rsi
        mov byte [rsi], dl ; сохраняем остаток о деления
        test rax, rax
        jnz .loopDiv
    .outRes:
        mov rdi, rsi   ; передает указатель на строку
        push rdi 
        call print_string
        pop rdi
        add rsp, 40
        pop rbx
        ret


; Выводит знаковое 8-байтовое число в десятичном формате 
print_int:
    sub rsp, 8 ; выравниваем стек
    mov rax, rdi
    test rax, rax ; проверяем на знак
    jge .positive 
    neg rax   ; если отрицательный
    push rax 
    push rdi  
    mov rdi, '-'
    call print_char
    pop rdi
    pop rax
    .positive:
        mov rdi, rax
        call print_uint
        add rsp, 8 
        ret


; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
; rdi - на 1ую, rsi на 2ую
string_equals:
    .equal_loop:
        mov r11b, byte [rdi] ; Загружаем байт из первой строки     
        cmp r11b, byte [rsi] ; сравниваем байт из 1ой строки и байт из 2ой     
        jne .not_equal 
        cmp r11b, 0 ; проверяем на нуль-терминант
        je .equal            
        inc rdi                 
        inc rsi                 
        jmp .equal_loop
    .equal:            
        mov rax, 1
        ret
    .not_equal:
        xor rax, rax
        ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:  
    push 0  ; выделяем место на стеке
    mov rdx, 1 ; длина
    mov rdi, STDIN  ; stdin (0)  
    mov rsi, rsp  
    mov rax, SYS_READ 
    syscall 
    pop rax                               
    ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор
read_word:
    push r12 ; 16
    push r13 ; 8
    push r14 ; 16
    mov r12, rdi ; адрес начала буфера
    mov r13, rsi ; размер буфера
    xor r14, r14 ; длина слова
    dec r13 ; резервируем место для нуль-терминанта
    .loop_spaces:
        call read_char ; читаем символ 
        test al, al            
        jz .buffer_overflow
        cmp al, 0x20 ; пропускаем, если пробел
        je .loop_spaces 
        cmp al, 0x9  ; пропускаем табуляцию
        je .loop_spaces  
        cmp al, 0xA ; пропускаем перевод строки
        je .loop_spaces    
    .read:
        cmp r14, r13   ; проверяем, не превышен ли размер буфера
        jge .buffer_overflow
        mov byte [r12 + r14], al; перемещаем символ в буффер
        inc r14
        call read_char
        cmp al, 0x20
        je .end
        cmp al, 0x9
        je .end
        cmp al, 0xA 
        je .end
        test al, al    ; проверка на конец
        jz .end
        jmp .read
    .end:
        mov byte [r12 + r14], 0 ; добавляем нуль-терминант
        mov rdx, r14 ; rdx = длина слова
        mov rax, r12
        jmp .finally
    .buffer_overflow:
        xor rdx, rdx
        xor rax, rax 
    .finally
        pop r14
        pop r13
        pop r12
        ret  

; rdi - указатель на буфер rsi - длина буфера
; Возвращает длину считанной строки в rax.
read_string:
	mov rax, SYS_READ
	mov rdx, rsi				
	mov rsi, rdi				
	mov rdi, STDIN
	syscall
	
	mov byte[rsi + rax - 1], 0
	ret

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
    xor rax, rax  
    xor rdx, rdx 
    xor r10, r10 ; для хранения числа
    xor r9, r9 ; Счетчик символов
    cmp byte [rdi+r9], 0
    je .begin_zero
    .loop_digit:
        mov r10b, byte [rdi + r9] ; байт из строки  
        sub r10b, '0' ; преобразование ASCII в число
        cmp r10b, 0                
        jl .end                    
        cmp r10b, 9            
        ja .end ; Если больше 9, выходим
        ; Умножаем текущее значение на 10
        ; rax * 10 = (rax << 1) + (rax << 3)
        push rdx
        mov rdx, rax ; Сохраняем текущее значение rax
        shl rax, 3 ; Умножаем на 8 
        shl rdx, 1 ; Умножаем на 2 
        add rax, rdx ; складываем
        pop rdx

        add rax, r10  ; добавляем текущую цифру               
        inc r9 ; Увеличиваем счетчик
        jmp .loop_digit  
    .begin_zero:  ; возвращаем 0, если число в начале строки равно 0
        xor rax, rax            
        mov rdx, 1     
    .end:
        mov rdx, r9  
        ret
    


; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
parse_int:         
    xor rdx, rdx ;       
    cmp byte [rdi], '-'   
    je .negative 
    cmp byte [rdi], '0'    
    je .endnull     
    .positive:
        sub rsp, 8 ; 16
        call parse_uint
        add rsp, 8
        jmp .end             
    .negative:
        inc rdi ; переходим на следующий символ
        sub rsp, 8 ; 16
        call parse_uint
        add rsp, 8
        cmp rdx, 0              ; Проверим есть ли между знаком и числом были какие-то символы. 
        je .err
        neg rax
        inc rdx ; увеличиваем длину на 1
    .end: 
        ret
    .endnull:
        xor rax, rax
        mov rdx, 1
        ret  
    .err:
        xor rdx, rdx
        ret
       

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
    ; rdi rsi rdx указатели на строку, буфер, длину буфера
    xor rax, rax
    xor rcx, rcx    ; счётчик  
    .loop_string: 
        cmp rcx, rdx 
        je .end_null ; если количество символов больше, чем длина буфера
        mov al, [rdi]   ;
        mov [rsi], al   ; записываем в буфер 
        test al, al    ; проверяем на нуль-термининант
        jz .end 
        inc rdi 
        inc rsi 
        inc rcx 
        jmp .loop_string 
    .end_null: 
        xor rax, rax
        ret 
    .end: 
        mov rax, rcx
        ret

; print_float - вывод числа с плавающей точкой на экран
; xmm0 - число (тип double)
print_float:
    ; Подготовим буфер для хранения строки
    sub rsp, 64             ; отложим место на стеке для строки (64 байта)
    mov rsi, rsp            ; укажем rsi на начало буфера

    ; Преобразуем число в строку
    mov rax, 1              ; Флаг для конвертации 1e-7 вещей
    cvtsd2si rdi, xmm0      ; преобразуем double в 64-битное целое число
    mov r8, rdi             ; Сохраняем целую часть в r8
    
    mov rdi, rsi            ; Указываем буфер в rdi для sprintf
    mov rax, 0              
    mov rdi, fmt            ; Указываем формат
    call sprintf            ; Вызываем sprintf, чтобы записать значение в строку
    call print_string
    add rsp, 64             ; Освобождаем буфер
    ret
