1. В качестве ответа на этот вопрос предоставьте вывод команды `size`.

```
root@0b845580f3cb:/workspace/lab2# size core.o
   text	   data	    bss	    dec	    hex	filename
    266	   4040	  50000	  54306	   d422	core.o
root@0b845580f3cb:/workspace/lab2# size hotfix.o
   text	   data	    bss	    dec	    hex	filename
    127	      0	      0	    127	     7f	hotfix.o
root@0b845580f3cb:/workspace/lab2# size legacy.o
   text	   data	    bss	    dec	    hex	filename
    172	      0	      4	    176	     b0	legacy.o
root@0b845580f3cb:/workspace/lab2# size main.o
   text	   data	    bss	    dec	    hex	filename
    118	      0	      0	    118	     76	main.o
```

2. в одном из файлов столбец `bss` имеет аномально большое значение при малом общем размере файла (`dec`). объясните, почему так могло произойти и где физически хранится содержимое этой секции на диске.

Общий объем файла сильно меньше, так как секция `bss` отвечает за хранение неинициализированных данных, на диске ей хранить нечего, ведь исходные значения будут получены исключительно в рантайме.

3. В файле `core.o` присутствует секция, которой нет в `legacy.o` и `hotfix.o` (интуиция подсказывает вам, что это что-то связанное со строками). Найдите её и укажите точное имя.

Это секция `.rodata`, раз это что-то связанное со строками, то речь идет скорее всего о строковых литералах, которые имеют тип `const char *`

4. Найдите среди полученных строк секретный токен, оставленный разработчиком. Скопируйте его в отчёт.

`FLAG{b1nary_4rch4eology_2026}`

5. Сравните таблицы символов четырёх файлов. Найдите имена, которые встречаются более чем в одном файле. Какие именно имена являются общими для нескольких модулей? *Подсказка:* особое внимание уделите символу `system_mode`. 

Несколько раз встречаются имена: `system_mode`, `apply_hotfix` и `print_status`. 

```
core.o:
0000000000000020 D config_table
0000000000000000 t internal_cleanup
0000000000000000 b large_buffer
0000000000000012 T print_status
                 U printf
0000000000000020 R secret_token
0000000000000000 D system_mode
0000000000000000 D welcome_msg

hotfix.o:
0000000000000000 T apply_hotfix
0000000000000004 C system_mode

legacy.o:
000000000000001a T apply_legacy_patch
0000000000000000 b legacy_counter
0000000000000000 t legacy_helper
0000000000000004 C system_mode

main.o:
                 U apply_hotfix
0000000000000000 T main
                 U print_status
```

| Символ | Описание |
| -------------- | --------------- |
| `system_mode` | В `core.o` этот символ имеет тип D (.data), а в файлах `hotfix.o` и `legacy.o`, он имеет тип C (common). Если слинковать такие объектники, то адрес у этой перемнной будет общий, так что исходные данные будет присвоены в соотвествии с `core.o` |
| `apply_hotfix` | В `hotfix.o` этот символ имеет тип T (.text), то есть это его реализация, а в `main.o` этот же символ имеет тип U (undefined), то есть линкер будет искать его в другом месте, которым скорее всего окажется `hotfix.o` |
| `print_status` | Аналогично `apply_hotfix` |

6. Для каждого общего имени проанализируйте:
    - В каких файлах оно присутствует?
    - Какой тип символа (буква во второй колонке `nm`) в каждом файле?
    - В какой секции (Ndx) оно находится?

| Символ | Тип | Объектник | Секция |
|---|---|---|---|
| `config_table` | `D` | `core.o` | .data |
| `internal_cleanup` | `t` | `core.o` | .text |
| `large_buffer` | `b` | `core.o` | .bss |
| `print_status` | `T` | `core.o` | .text |
| `printf` | `U` | `core.o` | неопределена |
| `secret_token` | `R` | `core.o` | .rodata |
| `system_mode` | `D`, `C` | `core.o`, `hotfix.o`, `legacy.o` | .data в случае `core.o`, остальные в секции common |
| `welcome_msg` | `D` | `core.o` | .data |
| `apply_hotfix` | `T`, `U` | `hotfix.o`, `main.o` | в `hotfix.o` - .text, для `main.o` - неопределено, она просто ожидает где-то увижеть этот символ, например найти его определение в `hotfix.o` при линковке |
| `apply_legacy_patch` | `T` | `legacy.o` | .text |
| `legacy_counter` | `b` | `legacy.o` | .bss |
| `legacy_helper` | `t` | `legacy.o` | .text |
| `main` | `T` | `main.o` | .text |

7. Сопоставьте ваши наблюдения с исходным кодом `hotfix.c`, который вам доступен. В `hotfix.c` объявлена переменная `char system_mode[4];`. Что вы можете сказать о переменной `system_mode` в `core.o` и `legacy.o`, не имея их исходного кода? Какой конфликт это создаёт?

Скорее всего, в `legacy.o` эта переменная объявлена идентично `hotfix.c`, а в `core.o` она скорее всего объявлена как-то так:
```c
int system_mode = 1;
```

Конфликт это не создает, для линкера это будет стандартное поведение, 2 переменны в секции Common, одна в секции data, просто обе будут указывать на одно и то же значение после линковки. Конфликт может произойти при расхождении типов этих переменных.

8. Выдал ли компоновщик ошибку или предупреждение? Если да, процитируйте его дословно. Если нет, то, как вы думаете, почему компоновщик не сообщил о проблеме, несмотря на то, что `system_mode` определён в нескольких модулях с разными типами?

```
root@0b845580f3cb:/workspace/lab2# gcc -fcommon core.o legacy.o hotfix.o main.o -o app
root@0b845580f3cb:/workspace/lab2# ./app
System Initialized v1.0, Mode: 1
System Initialized v1.0, Mode: 4407873
```

Хоть переменные и расходятся в типах, но линкеру неизвестен оригинальный тип, для процессора типов не существует, задача линкера просто подсунуть подходящий адрес, переменную он нашёл, а значит все хорошо, типы существуют только на уровне c кода и могут разве что извенить поведение программы для программиста.

В нашем случае `int` и `chat[4]` вообщем-то не имеют разницы.

9. В какой секции (`.data` или `.bss`) в итоге оказался `system_mode` в финальном исполняемом файле? Как вы думаете, почему компоновщик сделал именно такой выбор?

```
nm app | grep system_mode
0000000000004020 D system_mode
```

По итогу переменная оказалась в секции `.data`, это произошло так как, common секция уже не имеет смысла, символ нашелся, а определен он был как инициализированный и глобальный, причем инициализированный единичкой, соотвественно он попал в секцию `.data`, в `.bss` попадают данные инициализированные нулями.

10. Какое сообщение об ошибке теперь выдает компоновщик? Как, не меняя имена переменных, можно исправить `hotfix.c`, чтобы эта сборка прошла успешно?

```
root@0b845580f3cb:/workspace/lab2# gcc -c hotfix.c -fno-common -o hotfix2.o
root@0b845580f3cb:/workspace/lab2# gcc -fno-common main.o hotfix2.o legacy.o core.o -o app_better
/usr/bin/ld: warning: alignment 1 of normal symbol `system_mode' in hotfix2.o is smaller than 4 used by the common definition in legacy.o
/usr/bin/ld: warning: NOTE: alignment discrepancies can cause real problems.  Investigation is advised.
/usr/bin/ld: core.o:(.data+0x0): multiple definition of `system_mode'; hotfix2.o:(.bss+0x0): first defined here
collect2: error: ld returned 1 exit status
```

Есть несколько способов.

1) Адекватный
```c
// char system_mode[4];
extern int system_mode;

void apply_hotfix(void) {
  char *ptr = (char *)&system_mode;
  ptr[0] = 'A';
  ptr[1] = 'B';
  ptr[2] = 'C';
  ptr[3] = '\0';
}
```

```
root@0b845580f3cb:/workspace/lab2# gcc -c hotfix.c -fno-common -o hotfix2.o
root@0b845580f3cb:/workspace/lab2# gcc -fno-common main.o hotfix2.o legacy.o core.o -o app_better
root@0b845580f3cb:/workspace/lab2# ./app_better
System Initialized v1.0, Mode: 1
System Initialized v1.0, Mode: 4407873
root@0b845580f3cb:/workspace/lab2#
```

2) Хардкорный
```c
extern char system_mode[4] __attribute__((aligned(4)));

void apply_hotfix(void) {
  system_mode[0] = 'A';
  system_mode[1] = 'B';
  system_mode[2] = 'C';
  system_mode[3] = '\0';
}
```

```
root@0b845580f3cb:/workspace/lab2# gcc -c hotfix.c -fno-common -o hotfix2.o
root@0b845580f3cb:/workspace/lab2# gcc -fno-common main.o hotfix2.o legacy.o core.o -o app_better
root@0b845580f3cb:/workspace/lab2# ./app_better
System Initialized v1.0, Mode: 1
System Initialized v1.0, Mode: 4407873
root@0b845580f3cb:/workspace/lab2#
```

В обоих случаях нужен `extern`, поскольку символы по умолчанию без него попадали в `.bss` и линковщик не мог решить кто главнее.
