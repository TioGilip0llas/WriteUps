**Cross Site Scripting (XSS)** o **Scripteo Acojonante entre Sitios Web** en español de España, es una vulnerabilidad que permite:
-  Comprometer las interacciones de los usuarios con una aplicación vulnerable.
-  Baipasear políticas del mismo origen (SOP, Same-Origin Policy), que impide que diferentes sitios web accedan entre sí.
-  Suplantar la identidad de un usuario víctima, realizar cualquier acción en su nombre y acceder a sus datos.
-  Si la víctima tiene privilegios elevados, el atacante puede obtener control total sobre la aplicación y sus datos.
## Explicación + POC XSS
La vulnerabilidad se explota manipulando la aplicación para que inserte JavaScript malicioso en las respuestas enviadas a los usuarios. El compromiso de la aplicación se cumple cuando el código malicioso se ejecuta en el navegador de la víctima.

La mayoría de las vulnerabilidades XSS se confirman con un payload que ejecute JavaScript arbitrario por ejemplo `alert()`.

Desde Chrome 92, los iframes de origen cruzado (`cross-origin iframes`) ya no pueden ejecutar `alert()`. Como alternativa, se puede usar `print()` [debido a su simpleza y visibilidad, incluso dentro de iframes ocultos](https://portswigger.net/research/alert-is-dead-long-live-print).
 
> iframe: Documento HTML incrustado dentro de otro sitio web del mismo dominio o uno difrente. 
> Se denomina "Cross-Origin iframe" cuando un `iframe` carga contenido desde un dominio diferente al de la página principal.

Existen 3 variantes de ataques XSS:
- Reflejado: El script viene de la solicitud HTTP actual.
- Almacenado: El script proviene de la base de datos del sitio web.
- Basado en DOM: La vulnerabilidad explotada está en el código del lado del cliente y no del servidor.

## Testing XSS

Las vulnerabilidades XSS pueden encontrarse rápidamente con herramientas como Burp Suite.

#### Pruebas manuales para XSS reflejado y almacenado

1. Insertar un input único en cada punto de entrada.
    
2. Identificar dónde aparece el input en las respuestas HTTP.
    
3. Probar si se puede ejecutar JavaScript con un payload adecuado.

#### Pruebas para XSS basado en DOM

1. Insertar un valor único en un parámetro de la URL.
    
2. Usar las herramientas de desarrollo del navegador para buscar el valor en el DOM.
    
3. Revisar si se puede explotar. Para casos más complejos (cookies, `setTimeout`), es necesario analizar el código JavaScript manualmente.

#### Otros conceptos relacionados

- **Política de Seguridad de Contenidos (CSP)**: Puede mitigar XSS, pero a veces es evadible.
    
- **Inyección de marcado colgante (Dangling Markup Injection)**: Permite capturar datos sensibles cuando no es posible un ataque XSS completo.
    

### Cómo prevenir ataques XSS

1. **Filtrar la entrada**: Rechazar caracteres no esperados.
    
2. **Codificar la salida**: Evitar que los datos sean interpretados como contenido activo.
    
3. **Usar encabezados HTTP adecuados**: `Content-Type` y `X-Content-Type-Options` para evitar interpretaciones incorrectas.
    
4. **Implementar CSP**: Como última línea de defensa para reducir el impacto de XSS.

### **Preguntas frecuentes**

- **¿Qué tan comunes son las vulnerabilidades XSS?** Muy comunes, una de las fallas de seguridad web más frecuentes.
    
- **¿Qué diferencia hay entre XSS y CSRF?** XSS inyecta JavaScript malicioso, CSRF induce a un usuario a realizar acciones no deseadas.
    
- **¿Qué diferencia hay entre XSS y SQL Injection?** XSS afecta al cliente, SQL Injection compromete la base de datos.
    
- **¿Cómo prevenir XSS en PHP y Java?** Filtrar entradas con listas blancas y codificar las salidas según el contexto (HTML, JavaScript).
