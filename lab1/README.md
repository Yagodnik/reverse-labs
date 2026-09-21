# Lab1 solution

## Main task

1. Сколько строк было в исходном файле и сколько стало в `.i`? 
В исходном файле было 24 строки, а в обработанном 756.

2. Найдите в `simple.i` функцию `main`. Что находится **над** ней в файле? Почему там так много строк?
include-ы, в нашем случае cstdio, сам по себе файл большой и содержит сигнатуры и типы для c api для работы с IO

3. Найдите в `simple.i` строку `"Result: %d, Counter: %d, Magic: %d\n"`. Где она оказалась и что с ней сделал препроцессор?
```cpp
int main() {
    int result = sum_of_squares(3, 4);
    bump_counter();
    printf("Result: %d, Counter: %d, Magic: %d\n", result, global_counter, MAGIC);
    return 0;
}
```

Препроцессор ничего с ней не сделал. Это просто аргумент функции, форматирование выполняется позже, в рантайме. vargs размернутся на этапе компиляции.

4. Сравните размеры файлов `-O0` и `-O2`. Во сколько раз оптимизированный код короче?

| -O0 | -O2 |
| -------------- | --------------- |
| 9640 байт | 8216 байт |

5. Откройте файл, полученный после сборки без оптимизации. Найдите метку `square:`. Какие инструкции там используются для умножения?
```asm
"square(int)":
    push    rbp
    mov     rbp, rsp
    mov     DWORD PTR [rbp-4], edi
    mov     eax, DWORD PTR [rbp-4]
    imul    eax, eax
    pop     rbp
    ret
```
Используется инструкция `imul`

6. Найдите метку `main:`. Какие регистры используются для передачи аргументов в вызов `sum_of_squares`? Как это связано с соглашениями о вызовах?
```asm
"main":
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16
    mov     esi, 4
    mov     edi, 3
    call    "sum_of_squares(int, int)"
    mov     DWORD PTR [rbp-4], eax
    call    "bump_counter()"
    mov     edx, DWORD PTR "global_counter"[rip]
    mov     eax, DWORD PTR [rbp-4]
    mov     ecx, 42
    mov     esi, eax
    mov     edi, OFFSET FLAT:.LC0
    mov     eax, 0
    call    "printf"
    mov     eax, 0
    leave
    ret
```

Используются регистры `esi` и `edi`. Конвенкиция вызовов для целочисленных переменных в c такова:
| Аргумент | Регистр |
| -------------- | --------------- |
| 1 | RDI |
| 2 | RSI |
| 3 | RDX |
| 4 | RCX |
| 5 | R8 |
| 6 | R9 |
| 7+ | стек |

Так как мы используем 4 байта под int, то используется регистры `esi` и `edi`, которые представляют из себя младшие 4 байта `RSI` и `RDI` соотвественно.

7. Во втором файле (с `-O2`) функция `square` скорее всего **исчезла**. Почему? 
```asm
"square(int)":
        imul    edi, edi
        mov     eax, edi
        ret
"sum_of_squares(int, int)":
        imul    edi, edi
        imul    esi, esi
        lea     eax, [rdi+rsi]
        ret
"bump_counter()":
        add     DWORD PTR "global_counter"[rip], 1
        ret
.LC0:
        .string "Result: %d, Counter: %d, Magic: %d\n"
"main":
        sub     rsp, 8
        mov     eax, DWORD PTR "global_counter"[rip]
        mov     ecx, 42
        mov     esi, 25
        mov     edi, OFFSET FLAT:.LC0
        lea     edx, [rax+1]
        xor     eax, eax
        mov     DWORD PTR "global_counter"[rip], edx
        call    "printf"
        xor     eax, eax
        add     rsp, 8
        ret
"global_counter":
        .zero   4
```

Функция хоть и не исчезла, однако godbolt вероятно оставил её просто для примера. 
Операция, которую выполняет `sum_of_squares` примитивна, поэтому выполнять два прыжка по коду до `square` будет неэффективно, так как это может инвалидировать текущий кеш. Поэтому компилятору выгоднее её заинлайнить.

8. Почему `MAGIC` имеет тип `R` (read-only data), а не `D` (data)?
```
000000000000003c T _Z12bump_counterv
000000000000000f T _Z14sum_of_squaresii
0000000000000000 T _Z6squarei
0000000000000000 r _ZL5MAGIC
0000000000000000 B global_counter
0000000000000052 T main
                 U printf
```

Поскольку `MAGIC` помечена как константа, поэтому попадает в read-only.

9. Что показывает команда `size`? Какие секции занимают больше всего места и почему?

| Имя секции | Размер (в байтах) |
| --- | --- |
| **`.text`** | 151 |
| **`.rodata`** | 44 |
| **`.bss`** | 4 |
| **`.data`** | 0 |

Самый большой размер у секции `.text`, так как она содержит код программы.

11. Какой результат вывела программа? 
```
Program returned: 0
Program stdout
Result: 25, Counter: 1, Magic: 42
```

## Bonus task

Исходный код лежит в файле `legacy_experiments.c` в отформатированном и откомментированном виде.
Суть программы: пользователь вбивает ключ, который кастится к массиву интов, шифруется и на основе полученных чисел строятся "последовательности" из вложенных структур, после чего сравниваются их длины.
Если все длины совпали то программа вернет 0, иначе 1.

flag: flag{i_considered_giving_only_the_binary_24412707}
