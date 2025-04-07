## XSS Reflejado
Es la variante más simple de explotar XSS. Se produce cuando una aplicación recibe datos en una solicitud HTTP y los incluye en la respuesta inmediata de forma insegura.
Este es un ejemplo simple de una vulnerabilidad XSS reflejada:
```python
https://insecure-website.com/status?message=All+is+well. <p>Status: All is well.</p>
```

Dado que la aplicación no procesa ni escapa adecuadamente los datos del usuario, el siguiente ataque es posible:
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

### Laboratorio1
Este laboratorio contiene una vuln xss reflejada en el buscador. Para resolverlo llamaremos a un `alert`.
Con el siguiente payload es suficiente:
```java
 <script>alert('hola')</script>
```

Siguiendo el contenido de PortSwigger, en el [cheat sheet](https://portswigger.net/web-security/cross-site-scripting/cheat-sheet) encontramos este payload que también funciona.
```java
<xss onfocus=alert(1) autofocus tabindex=1>
```

#### Diferencias entre ambos payloads:
El primero es el más básico y directo. Si la aplicación permite inyectar contenido sin filtrar, funcionará y lo interpreta como HTML + JS. Muchas aplicaciones bloquean directamente etiquetas como `<script>`.
En el segundo, se hace uso de una etiqueta personalizada `xss` que es más permisible en los navegadores. `onfocus=alert(1)` equivale a `alert(1)`, cuando el elemento recibe foco (que el usuario de atención al elemento web). Aseguramos que reciba foco con `autofocus` y `tabindex=1`. Más ejemplos en [[XSS]]

### Impacto de ataque XSS reflejado
Si el atacante ejecuta el script en el navegador de la víctima, compromete al usuario, realizando cualquier acción (lectura/modificación o interacción) que la victima pueda hacer naturalmente.
Medios para inducir a esta vuln; incluyen colocar enlaces en un sitio web controlado por el atacante; en otro sitio web que permita generar contenido; enviando un enlace en un correo electrónico, tweet u otro mensaje. 
Como la entrega es más externa, el impacto no es tan grave como un ataque autónomo dentro de la aplicación con XSS almacenado.
### XSS Reflejado en Diferentes Contextos

El XSS reflejado varía según la ubicación de los datos reflejados en la respuesta de la aplicación, lo que afecta el tipo de payload necesario y el impacto de la vulnerabilidad. También, cualquier validación o procesamiento previo del input influye en la explotación.

### Testing de XSS reflejado

1. **Probar cada punto de entrada**: Examinar parámetros en la URL, cuerpo del mensaje, ruta del archivo y encabezados HTTP.
    
2. **Enviar valores aleatorios**: Usar cadenas alfanuméricas únicas para detectar su reflejo en la respuesta.
    
3. **Determinar el contexto de reflexión**: Identificar si el input aparece en texto, atributos HTML, dentro de JavaScript, etc.
    
4. **Probar un payload inicial**: Enviar un payload XSS y observar si se ejecuta sin modificaciones.
    
5. **Ajustar el payload si es necesario**: Si el input es modificado o bloqueado, probar técnicas alternativas según el contexto.
    
6. **Validar en un navegador**: Si el ataque funciona en Burp, probarlo en un navegador para confirmar la ejecución del código malicioso.

### FAQs XSS reflejado

- **XSS reflejado vs. almacenado**: El reflejado ocurre en la respuesta inmediata, mientras que el almacenado se guarda en la aplicación para futuras respuestas.
    
- **XSS reflejado vs. Self-XSS**: En el Self-XSS, el ataque solo ocurre si la víctima ingresa el payload manualmente, por lo que se considera de menor impacto.