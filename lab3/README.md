# Лабораторная 3

1. Коротко опишите, что делают флаги утилиты `ar`: `r`, `c`, `s` . Что произойдёт, если запустить команду второй раз с тем же именем архива?

`ar` - утилита для создания и модификации архивов. 

| Флаг | Описание |
| -------------- | --------------- |
| `r` | Вставлять файлы в архив с заменой. |
| `c` | Создает новый архив, если он не был создан |
| `s` | Записывает объектный файл в архив или заменяет уже существующий. |

```
root@ad4e8e5acd2b:/workspace/lab3# ar rcs libmath_static.a vector_math.o
root@ad4e8e5acd2b:/workspace/lab3# ar rcs libmath_static.a vector_math.o
```

Повторный запуск ничего не выводит, наша конфигурация флагов просто заменит уже существующий оьъектник в архиве.

2. С помощью утилиты `nm` посмотрите, что получилось в `main.o`. Как вы думаете, почему функция `main` не подверглась name mangling (имеет "чистое" имя), хотя файл скомпилирован компилятором C++?

```
root@ad4e8e5acd2b:/workspace/lab3# nm main.o
                 U _GLOBAL_OFFSET_TABLE_
                 U _ZNSolsEPFRSoS_E
                 U _ZNSolsEi
0000000000000027 r _ZNSt8__detail30__integer_to_chars_is_unsignedIjEE
0000000000000028 r _ZNSt8__detail30__integer_to_chars_is_unsignedImEE
0000000000000029 r _ZNSt8__detail30__integer_to_chars_is_unsignedIyEE
                 U _ZSt21ios_base_library_initv
                 U _ZSt4cout
                 U _ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_
                 U _ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
                 U __stack_chk_fail
                 U dot_product
                 U get_lib_version
0000000000000000 T main
```

Имя main не манглируется, так как является стандартным и является точкой входа.

3. Приведите текст полученной на шаге 1 ошибки.

```
/usr/bin/ld: vector_math_nopic.o: relocation R_X86_64_32 against symbol `LIB_VERSION' can not be used when making a shared object; recompile with -fPIC
/usr/bin/ld: failed to set dynamic section sizes: bad value
collect2: error: ld returned 1 exit status
```

4. Сравните размеры сегментов `text` для `app_static` и `app_dynamic` (через `size`). Куда делся код функций библиотеки в динамическом варианте?

```
root@ad4e8e5acd2b:/workspace/lab3# size app_static app_dynamic
   text	   data	    bss	    dec	    hex	filename
   2548	    656	    280	   3484	    d9c	app_static
   2517	    680	    280	   3477	    d95	app_dynamic
```

Поскольку при динамической линковке код остается в отдельном .so файле, то он не будет встроен в бинарник в отличие от случая со статической библиотекой, так как код будет вшит внутрь бинарника.

5. Шаг 1 упадёт с ошибкой `undefined reference`. Объясните, почему это происходит, используя концепцию множеств компоновщика: `U` (неразрешённые ссылки), `D` (определённые символы) и `E` (извлечённые файлы). 

Линкер обрабатывает входные файлы строго слева направо, один раз. Он поддерживает три множества символов:

| Секция | Описание|
| -------------- | --------------- |
| U (undefined) | символы, которые требуются, но ещё не найдены |
| D (defined) | символы, которые уже определены в обработанных файлах |
| E (extracted) | символы, уже извлечённые из библиотек |

При неправильном порядке:
Линкер видит -lmath_dynamic первым. Проверяет множество U, оно пустое, линкер решает что из этой библиотеки ему ничего не нужно, поэтому она пропускается и не добавляется в список зависимостей.
Затем обрабатывается main.o. Его символы добавляются в D. Функции get_lib_version и dot_product, которые использует main, добавляются в U.
Файлы закончились. В U остались неразрешённые символы, но библиотека уже была пропущена и повторно не просматривается, поэтому появляется ошибка undefined reference.

При правильном порядке:
Сначала обрабатывается main.o -> U = {get_lib_version, dot_product}.
Затем -lmath_dynamic -> линкер видит, что нужные символы присутствуют в U, извлекает их из библиотеки -> линковка успешна

6. Линковка упадёт с ошибкой `undefined reference`. Выполните `nm main.o | grep dot` и `nm libmath_dynamic.so | grep dot`. Как теперь выглядят имена функций `dot_product` и `get_lib_version` в объектном файле C++? 

Без `extern "C"`:
```
root@ad4e8e5acd2b:/workspace/lab3# nm main.o | grep dot
                 U _Z11dot_productPKiS0_i
root@ad4e8e5acd2b:/workspace/lab3# nm libmath_dynamic.so | grep dot
000000000000110a T dot_product
```

С `extern "C"`:
```
root@ad4e8e5acd2b:/workspace/lab3# nm main.o | grep dot
                 U dot_product
root@ad4e8e5acd2b:/workspace/lab3# nm libmath_dynamic.so | grep dot
000000000000110a T dot_product
```
