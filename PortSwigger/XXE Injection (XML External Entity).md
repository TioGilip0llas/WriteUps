# XXE Injection (PortSwigger) WriteUp Español

La **Inyección de Entidades Externas XML (XXE)** es una vulnerabilidad que permite:
- Interferir con el procesamiento de datos XML de una aplicación.
- Ver archivos en el sistema de archivos del servidor
- Interactuar con cualquier sistema backend al que la aplicación pueda acceder.
- Escalar un ataque a un servidor subyacente para realizar ataques de [[SSRF (Server-Side Request Forgery)]].

Algunas aplicaciones usan XML para transmitir datos entre el navegador y el servidor, estas casi siempre utilizan una biblioteca estándar o API para procesar datos XML en el servidor. 
Las vulnerabilidades surgen porque la especificación XML tiene características inseguras que se admiten en el procesador de XML.

Las entidades XML son una identidad personalizada con sus valores definidos desde fuera del DTD (documento que define la estructura del XML) donde se declara.


## Referencias
https://portswigger.net/web-security/xxe