# CSRF (PortSwigger) WriteUp Español

[Construyendo un Ataque CSRF](#Laboratorio1)

La **Falsificación de Solicitud entre Sitios (CSRF)** es una vuln que permite a un atacante:

- Inducir a los usuarios a que hagan acciones que no desean.
- Eludir políticas que evitan que diferentes sitios interfieran entre sí.

En un ataque CSRF, el atacante podría cambiar la dirección de correo, contraseña, hacer una transferencia, obtener control total de la cuenta y posible privilegio en una aplicación.

Para que sea efectivo, se ocupan tres condiciones:
1. **Acción relevante**: Existe una acción privilegiada en la aplicación (cambio de contraseña o modificación de privilegios).
2. **La sesión se basa en cookies**: No hay otro mecanismo para seguir las sesiones ni validar las solicitudes de usuario más que las cookies de sesión  en las solicitudes HTTP.
3. **No hay parámetros impredecibles**: Las solicitudes tienen parámetros conocidos, por ejemplo, si en la solicitud se pide la contraseña (que el atacante no sabe), la aplicación no es vulnerable.

En el ejemplo donde una aplicación tiene una función que deja al usuario cambiar el correo vinculado a su cuenta, el usuario manda una solicitud HTTP como esta:
```http
POST /email/change HTTP/1.1
Host: vulnerable-website.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 30
Cookie: session=yvthwsztyeQkAPzeQ5gHgTvlyxHfsAfE 

email=wiener@normal-user.com
```

Esta solicitud cumple con las condiciones requeridas para el CSRF:
1. Cambiar el correo es de interés para el atacante.
2. La aplicación necesita una cookie, no hay otro mecanismo.
3. Los valores de los parámetros se pueden determinar fácilmente.

Así, podemos construir la siguiente página:
```html 
<html> 
	<body> 
		<form action="https://vulnerable-website.com/email/change" method="POST"> 
			<input type="hidden" name="email" value="pwned@evil-user.net" /> 
		</form>
			<script> document.forms[0].submit(); </script>
	</body>
</html>
```

Cuando una víctima visite la página web del atacante, pasarán 3 cosas:
1. La página activará una solicitud HTTP al sitio vulnerable.
2. Si el usuario ya inicio sesión en el sitio vulnerable, el navegador incluirá su cookie de sesión, si es que no se usan las [cookies del mismo sitio.](#Defensas%20Comunes)
3. El sitio o aplicación vulnerable hará la request de forma normal, como si la víctima la hubiera hecho y cambiará su correo.

>Nota:
>>CSRF normalmente se describe en relación con el manejo de cookies, pero también está en otros contextos, como cuando la aplicación agrega automáticamente credenciales de usuario a las solicitudes (HTTP basic authentication, certificate-based authentication)

## Construyendo un Ataque CSRF
### Laboratorio1


## Defensas Comunes


## Referencias
https://portswigger.net/web-security/csrf