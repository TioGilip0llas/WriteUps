# Shell Injection (PortSwigger) WriteUp Español

[Inyección de Comandos (caso simple)](#Laboratorio1)
[Inyección Ciega con Delay](#Laboratorio2)

La **Inyección de Comandos al Sistema Operativo** es una vuln que permite:

- Ejecutar comandos del SO del servidor que ejecuta la aplicación.
- Comprometer a partir de ahí a otras infraestructuras de alojamiento (pivotar).
- Hacer un reconocimiento del servidor con comandos útiles. Se pueden encontrar en [[Principales Comandos Equivalencias]].

## Inyectando Comandos

En el [video](https://youtu.be/8PDDjCW5XWw) de PortSwigger hay un ejemplo donde una aplicación valida si hay stock en una tienda, a través de esta URL:
```http
https://insecure-website.com/stockStatus?productID=381&storeID=29
```

El proceso de consulta obliga a la aplicación consultar varios sistemas heredados, en este caso la funcionalidad se implementa llamando a un comando Shell.
```java
stockreport.pl 381 29
```
Este comando emite el estado de stock.

Si no hay implementadas defensas contra la inyección de comandos, puede que estemos de suerte. Por ejemplo:
```java
& echo aiwefwlguh &
```

Si enviamos lo anterior al parámetro `productID`, el comando ejecutado en la aplicación es:
```java
stockreport.pl & echo aiwefwlguh & 29
```
El comando `echo` hace que la string mandada se imprima en la salida.

Esto es visto como una forma útil para probar diferentes comandos.
```http
Error - productID was not provided
aiwefwlguh
29: command not found
```

Esto quiere decir 4 cosas:
- `stockreport.pl` se ejecutó sin sus argumentos esperados y devolvió un mensaje de error.
- El comando `echo` inyectado fue ejecutado e impreso en la salida.
- El argumento `29` se ejecutó como un comando, causando un error.
- El separador de comandos `&` después del `echo` fue de utilidad para separar el comando inyectado de lo que sigue al punto de inyección, reduciendo la posibilidad de que lo que siga impida que se ejecute el comando inyectado.

### Laboratorio1

## Inyectando Comandos a Ciegas
### Laboratorio2

## Referencias
https://portswigger.net/web-security/os-command-injection