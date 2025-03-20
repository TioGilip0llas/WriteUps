```python
Máquina desplegada, su dirección IP es --> 172.17.0.2
```

`sudo nmap -p- -sS -Pn -n 172.17.0.2 -oG puertos`

```python
PORT   STATE SERVICE
21/tcp open  ftp
22/tcp open  ssh
80/tcp open  http
```

`sudo nmap -p21,22,80 -sSCV 172.17.0.2 -oN objetivos`

```python
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.5
| ftp-syst: 
|   STAT: 
| FTP server status:
|      Connected to 172.17.0.1
|      Logged in as ftp
|      TYPE: ASCII
|      No session bandwidth limit
|      Session timeout in seconds is 300
|      Control connection is plain text
|      Data connections will be plain text
|      At session startup, client count was 2
|      vsFTPd 3.0.5 - secure, fast, stable
|_End of status
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_-rwxrw-rw-    1 ftp      ftp         75372 Apr 27  2024 hello_peter.jpg [NSE: writeable]
22/tcp open  ssh     OpenSSH 9.6p1 Ubuntu 3ubuntu13 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   256 61:8f:91:89:a7:0b:8e:17:b7:dd:38:e0:00:04:59:47 (ECDSA)
|_  256 8a:15:29:13:ec:aa:f6:20:ca:c8:80:14:56:05:ec:3b (ED25519)
80/tcp open  http    Apache httpd 2.4.58 ((Ubuntu))
|_http-server-header: Apache/2.4.58 (Ubuntu)
|_http-title: Apache2 Debian Default Page: It works
MAC Address: 02:42:AC:11:00:02 (Unknown)
Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
```

cosas de interés:
```python
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_-rwxrw-rw-    1 ftp      ftp         75372 Apr 27  2024 hello_peter.jpg [NSE: writeable]
```

Acceso a FTP
``` python
$ftp 172.17.0.2 -a
Connected to 172.17.0.2.
220 (vsFTPd 3.0.5)
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> get hello_peter.jpg
local: hello_peter.jpg remote: hello_peter.jpg
229 Entering Extended Passive Mode (|||22931|)
150 Opening BINARY mode data connection for hello_peter.jpg (75372 bytes).
100% |**************************************| 75372       28.18 MiB/s    00:00 ETA
226 Transfer complete.
75372 bytes received in 00:00 (26.15 MiB/s)
ftp> bye
221 Goodbye.

```

Código de la pagina web:
``` python
<!-- 
¡Hola, Peter!

¿Te acuerdas los libros que te presté de esteganografía? ¿A que estaban buenísimos?

Aquí te dejo una clave que usaras sabiamente en el momento justo. Por favor, no seas tan obvio, la vida no se trata de fuerza bruta.

@UX=h?T9oMA7]7hA7]:YE+*g/GAhM4

Solo te comento, recuerdo que usé este método porque casi nadie lo usa... o si. Lamentablemente, a mi también se me olvido. Solo recuerdo que era base
-->
```

[Identificador de Cifrado](https://www.dcode.fr/identificador-cifrado)
![](images/images-fileception/Pasted%20image%2020250319115319.png)



[CyberChef](https://gchq.github.io/CyberChef/#recipe=From_Base85('!-u',true,'z')&input=QFVYPWg/VDlvTUE3XTdoQTddOllFKypnL0dBaE00)
![](images/images-fileception/Pasted%20image%2020250319115734.png)

`steghide --extract -sf hello_peter.jpg -p base_85_decoded_password `
```python
anot� los datos extra�dos e/"you_find_me.txt"
```

![](images/images-fileception/Pasted%20image%2020250319120245.png)

[decode Ook!](https://www.dcode.fr/ook-language) Da el siguiente código:
`9h889h23hhss2`

``` python
$ssh -L 8000:localhost:8000 peter@172.17.0.2
peter@172.17.0.2's password: 
Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.12.12-amd64 x86_64)
[...]

Last login: Wed Mar 19 19:14:09 2025 from 172.17.0.1
peter@f423900c3ddd:~$ 

```
Ya en el sistema
```python
peter@f423900c3ddd:~$ cat nota_importante.txt 
NO REINICIES EL SISTEMA!!

HAY UN ARCHIVO IMPORTANTE EN TMP

peter@f423900c3ddd:/home$ cd /tmp
peter@f423900c3ddd:/tmp$ ls
importante_octopus.odt	recuerdos_del_sysadmin.txt
peter@f423900c3ddd:/tmp$ cat recuerdos_del_sysadmin.txt 
Cuando era niño recuerdo que, a los videos, para pasarlos de flv a mp4, solo cambiaba la extensión. Que iluso.

```

![](images/images-fileception/Pasted%20image%2020250319122804.png)

![](images/images-fileception/Pasted%20image%2020250319123054.png)

`$unzip importante_octopus.zip `
``` python
Archive:  importante_octopus.zip
   creating: Configurations2/accelerator/
   creating: Configurations2/floater/
   creating: Configurations2/images/Bitmaps/
   creating: Configurations2/menubar/
   creating: Configurations2/popupmenu/
   creating: Configurations2/progressbar/
   creating: Configurations2/statusbar/
   creating: Configurations2/toolbar/
   creating: Configurations2/toolpanel/
  inflating: META-INF/manifest.xml   
 extracting: Thumbnails/thumbnail.png  
  inflating: content.xml             
  inflating: leerme.xml              
  inflating: manifest.rdf            
  inflating: meta.xml                
 extracting: mimetype                
  inflating: settings.xml            
  inflating: styles.xml   
```

`cat leerme.xml `
```python
Decirle a Peter que me pase el odt de mis anécdotas, en caso de que se me olviden mis credenciales de administrador... Él no sabe de Esteganografía, nunca sé lo imaginaria esto.

usuario: octopus
password: ODBoMjM4MGgzNHVvdW8zaDQ=

```

```bash
echo -n 'ODBoMjM4MGgzNHVvdW8zaDQ=' | base64 -d
80h2380h34uouo3h4
```

```python
octopus@f423900c3ddd:/tmp$ sudo -l
...
User octopus may run the following commands on f423900c3ddd:
    (ALL) NOPASSWD: ALL
    (ALL : ALL) ALL
octopus@f423900c3ddd:/tmp$ sudo su
[sudo] password for octopus: 
root@f423900c3ddd:/tmp# 

```
