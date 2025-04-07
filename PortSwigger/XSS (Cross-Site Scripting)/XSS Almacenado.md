## XSS Almacenado

El Stored Cross-Site Scripting, también llamado *segundo orden* o *XSS persistente*, se presenta cuando una aplicación recibe datos de una fuente no confiable y los incluye en sus respuestas HTTP posteriores.

Por ejemplo si un sitio web deja a los usuarios enviar comentarios en publicaciones de blog y estos se muestran a otros usuarios. Los usuarios enviarán una solicitud HTTP como esta:
```http
POST /post/comment HTTP/1.1 
Host: vulnerable-website.com
Content-Length: 100

postId=3&comment=Este+post+esta+chido.&name=Carlos+Montoya&email=carlos%40normal-user.net
```

Cualquier otro usuario verá:
```html
<p>Este post esta chido.</p>
```

Pero si la aplicación no hace otro procesamiento de datos, puede existir algún comentario, que en esta ocasión solo describiremos:
```html
<script>/* Doy pitisa */</script>
```

Es decir, la solicitud maliciosa se vería así:
```http
comment=%3Cscript%3E%2F%2A%20Doy%20pitisa%20%2A%2F%3C%2Fscript%3E
```

Y al final, cualquier usuario que visite la publicación recibirá la pitisa. Porque el script suministrado se ejecutará en el navegador de la víctima, en el contexto de su sesión con la aplicación.

### Laboratorio2
Este laboratorio contiene una vuln xss almacenada en la caja de comentarios. Para resolverlo llamaremos a un `alert`.
Con el siguiente payload es suficiente:
```java
 <script>alert('hola')</script>
```

Siguiendo el contenido de PortSwigger, en el [cheat sheet](https://portswigger.net/web-security/cross-site-scripting/cheat-sheet) encontramos este payload que también funciona.
```java
<xss onfocus=alert('holi') autofocus tabindex=1>
```

Como vemos, este laboratorio es casi idéntico al [laboratorio pasado](XSS%20Reflejado#Laboratorio1), las diferencias entre ambos payloads son las mismas detalladas allí. Pero el impacto con la explotación es distinto.

Aquí el payload se guarda en la base de datos o almacenamiento del servidor y  se ejecuta cada vez que se carga la pagina. No solo se incluye en la solicitud y se ejecuta en la respuesta, puede afectar a múltiples usuarios.

### Impacto XSS Almacenado
Si un atacante concreta un ataque así, compromete a la víctima, haciendo cualquier acción que el usuario pueda hacer, ver, modificar e interactuar (impacto de XSS reflejado) de manear autónoma dentro de la aplicación y sin tanta preocupación por el inicio sesión. Porque el exploit está en la propia aplicación esperando a ser encontrada.

### Contextos de XSS almacenado
La locación de la data almacenada en la respuesta de la aplicación determina que tipo de payload  se ocupa.
También afecta al payload el procesamiento de los datos que utiliza la aplicación, sea antes o en el momento en el que se almacenan.
