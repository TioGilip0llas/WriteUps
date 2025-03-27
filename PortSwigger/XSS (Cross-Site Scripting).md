# XSS (PortSwigger) WriteUp Español

[XSS reflejado en contexto HTML sin encodear](#Laboratorio1)


La **Inyección de Entidades Externas XML (XXE)** es una vulnerabilidad que permite:
-  Comprometer las interacciones de los usuarios con una aplicación vulnerable.
-  Eludir la política de mismo origen, diseñada para separar diferentes sitios web.
- Hacerse pasar por un usuario víctima, realizar cualquier acción que este pueda realizar y acceder a sus datos.
- Obtener control total sobre funciones y datos de una aplicación si el usuario víctima tiene acceso privilegiado.
# Explicación + POC
La explotación de esta vulnerabilidad funciona manipulando la aplicación para que devuelva JavaScript malicioso a los usuarios. El compromiso de la aplicación se cumple cuando el código malicioso se ejecuta en el navegador de la víctima.

La mayoría de las vulnerabilidades XSS se confirman con un payload que ejecute JavaScript arbitrario por ejemplo `alert()`.

El caso de la versión 92 de Chrome, los **cross-origin iframes** (iframes multidominio) de una página web, no pueden llamar a `alert()`. Como payload alternativo se puede usar `print`para las construcciones, [dada su simpleza y visibilidad incluso en algun iframe invisible](https://portswigger.net/research/alert-is-dead-long-live-print).
 
> iframe: Documento HTML incrustado dentro de otro sitio web del mismo dominio o uno difrente. **Cross-Origin iframe** se le conoce a cuando el elemento incrustado es de otro dominio.

Existen 3 variantes de de ataques XSS:
- Reflejado: El script viene de la solicitud HTTP actual.
- Almacenado: El script proviene de la base de datos del sitio web.
- Basado en DOM: La vulnerabilidad explotada está en el código del lado del cliente y no del servidor.
# XSS Reflejado
Es la variante más simple de explotar XSS. Se produce cuando una aplicación recibe datos en una solicitud HTTP y los incluye en la respuesta inmediata de forma insegura.
Este es un ejemplo simple de una vulneravilidad XSS reflejada:
```python
https://insecure-website.com/status?message=All+is+well. <p>Status: All is well.</p>
```

Gracias a este reconocimiento de la aplicación no realiza otro procesamiento de los datos, se puede construir este ataque:
```python
https://insecure-website.com/status?message=<script>/*+Bad+stuff+here...+*/</script> <p>Status: <script>/* Bad stuff here... */</script></p>
```
si el usuario visita la URL creada, el script se ejecutará en su navegador, en el contexto de su sesión con la aplicación.

En otro ejemplo, suponemos que un sitio web tiene una función de búsqueda que recibe un término dado por el usuario para realizar una búsqueda:
```python
https://insecure-website.com/search?term=gift
```

La aplicación repite el término proporcionado por la URL anterior:
```python
<p>You searched for: gift</p>
```

La construcción del ataque en este caso, suponiendo que la aplicación no realiza otro proceso, sería de esta manera.
```python
https://insecure-website.com/search?term=<script>/*+Bad+stuff+here...+*/</script>
```

Dando la URL anterior como resultado, lo siguiente:
```python
<p>You searched for: <script>/* Bad stuff here... */</script></p>
```

Si otro usuario de la aplicación solicita la URL del atacante, entonces el script proporcionado por el atacante se ejecutará en el navegador del usuario víctima, en el contexto de su sesión con la aplicación.

#### Laboratorio1


## Referencias
https://portswigger.net/web-security/cross-site-scripting