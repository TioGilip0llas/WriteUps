## Registros
El x64 assembly usa 16 registros de 64 bits, hay algunos a los que se puede acceder a sus bytes inferiores de forma independiente, ya sean de 32, 16 u 8 bits.

| Registro de 8 bytes | Bytes 0-3 | Bytes 0-1 | Byte 0 |
| ------------------- | --------- | --------- | ------ |
| %rax                | %eax      | %ax       | %al    |
| %rcx                | %ecx      | %cx       | %cl    |
| %rdx                | %edx      | %dx       | %dl    |
| %rbx                | %ebx      | %bx       | %bl    |
| %rsi                | %esi      | %si       | %sil   |
| %rdi                | %edi      | %di       | %dil   |
| %rsp                | %esp      | %sp       | %spl   |
| %rbp                | %ebp      | %bp       | %bpl   |
| %r8                 | %r8d      | %r8w      | %r8b   |
| %r9                 | %r9d      | %r9w      | %r9b   |
| %r10                | %r10d     | %r10w     | %r10b  |
| %r11                | %r11d     | %r11w     | %r11b  |
| %r12                | %r12d     | %r12w     | %r12b  |
| %r13                | %r13d     | %r13w     | %r13b  |
| %r14                | %r14d     | %r14w     | %r14b  |
| %r15                | %r15d     | %r15w     | %r15b  |

## Operand Specifiers
Un _Operand Specifier_ es una parte de una instrucción que indica los datos a utilizar y como se deben manipular durante la ejecución de una instrucción. Pueden ser registros, direcciones de memoria o valores inmediatos. 
Definen la ubicación y el tipo de dato que la instrucción necesita para ejecutar su operación.

Tipos básicos de _especificadores de operando_ están en la tabla.

> _lmm_ se refiere a valores inmediatos o constantes incluidas directamente en cada instrucción, por ejemplo `0x8048d8e or 48`.

> E<sub>x</sub> se refiere a un registro, es decir, ubicaciones de almacenamiento rápidas dentro del CPU como el %rax.

> R\[E<sub>x</sub>] son valores almacenados en el registro E<sub>x</sub> .

> M\[x] son valores almacenados en la dirección de memoria (ubicación de la memoria donde se almacenan los datos) x.

| Tipo      | From                                 | Valor del operando                                       | Nombre         |
| --------- | ------------------------------------ | -------------------------------------------------------- | -------------- |
| Immediate | _$lmm_                               | _lmm_                                                    | Immediate      |
| Register  | E<sub>a</sub>                        | R\[E<sub>a</sub>]                                        | Register       |
| Memory    | _lmm_                                | M\[_lmm_]                                                | Absolute       |
| Memory    | (E<sub>a</sub>)                      | M\[R\[E<sub>b</sub>]]                                    | Absolute       |
| Memory    | _lmm_(E<sub>b</sub> E<sub>i</sub> s) | M\[_lmm_ + R\[E<sub>a</sub>] + (R\[E<sub>i</sub> ] x s)] | Scaled indexed |

Ejemplos con sintaxis AT&T:

- `mov %rax, %rbx` - Mueve el contenido del registro `%rbx` al registro `%rax`.
- `add $5, %rax` - Suma el valor inmediato `5` al contenido del registro `%rax`.
- `mov 0x100(%rbx), %rax` - Mueve el valor almacenado en la dirección de memoria calculada como `0x100` más el contenido del registro `%rbx` al registro `%rax`

## Instrucciones x64
Consideraciones:
>_byte_ se refiere a un entero de un byte (sufijo b)

>_word_ se refiere a un entero de 2 bytes (sufijo w)

>_doubleword_ se refiere a un entero de 4 bytes (sufijo l)

>_quadword_ se refiere a un entreo de 8 bytes (sufijo q)

La mayoría de las instrucciones como `mov`, utilizan un sufijo para mostrar el tamaño de los operandos; mover una _quadword_ de `%rax` a `%rbx` da:
`movq %rax, %rbx`.
Instrucciones como ret, no necesitan utilizar sufijos, no es necesario.
Otras instrucciones como `movs` y `movz`, utiliza dos sufijos porque convierten operandos del tipo del primer sufijo en el segundo. Por ejemplo, convertir el byte en `%al` en una _doubleword_ en `%ebx` con extensión cero, sería:
`movzbl %al, %ebx`

#### Movimiento de datos

Instrucciones con un sufijo:

| Instrucción | Descripción                                |
| ----------- | ------------------------------------------ |
| `mov S,D`   | Mueve del _Source_ a _Destination_         |
| `push S`    | Agrega sobre la pila                       |
| `pop D`     | Coloque la parte superior en _Destination_ |

Instrucciones con dos sufijos:

| Instrucción | Descripción                         |
| ----------- | ----------------------------------- |
| `mov S,D`   | Mover byte a word (signo extendido) |
| `push S`    | Mover byte a word (zero extendido)  |

Instrucciones sin sufijos

| Instrucción | Descripción                                                            |
| ----------- | ---------------------------------------------------------------------- |
| `cwtl`      | Convertir palabra en `%ax` a palabra doble en `%eax` (signo extendido) |
| `cltq`      | Agrega sobre la pila                                                   |
| `cqto`      | Coloque la parte superior en _Destination_                             |
## Resumen 

1. **Registros**:
   - **Registros de propósito general**: `%rax`, `%rbx`, `%rcx`, `%rdx`, `%rsi`, `%rdi`, `%rbp`, `%rsp`
   - **Registros extendidos**: `%r8` a `%r15`.
   - **Registros de segmento**: `%cs`, `%ds`, `%es`, `%fs`, `%gs`, `%ss`.
   - **Registros de control**: `%cr0`, `%cr2`, `%cr3`, `%cr4`.

2. **Instrucciones de movimiento de datos**:
   - `mov`: Mueve datos entre registros, memoria y valores inmediatos.
   - `push` y `pop`: Manipulan la pila.

1. **Instrucciones aritméticas**:
   - `add`, `sub`: Suma y resta.
   - `mul`, `div`: Multiplicación y división.
   - `inc`, `dec`: Incremento y decremento.

1. **Instrucciones lógicas**:
   - `and`, `or`, `xor`: Operaciones lógicas.
   - `not`, `neg`: Negación y complemento.

5. **Instrucciones de control de flujo**:
   - `jmp`: Salto incondicional.
   - `cmp`: Comparación de valores.
   - `je`, `jne`, `jg`, `jl`, etc.: Saltos condicionales basados en el resultado de `cmp`.

6. **Llamadas a funciones**:
   - `call`: Llama a una función.
   - `ret`: Retorna de una función.

7. **Modo de direccionamiento**:
   - Direccionamiento inmediato, directo, indirecto, basado en registro y basado en desplazamiento.


https://cs.brown.edu/courses/cs033/docs/guides/x64_cheatsheet.pdf

