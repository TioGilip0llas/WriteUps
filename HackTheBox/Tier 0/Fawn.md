[[FTP]] 
[[Anonymous]]

```java
IP atacante: 10.10.16.133
IP victima:  10.129.97.48
```

`$sudo nmap -p- -Pn -n -sV --min-rate 5000 10.129.97.48`
```java
PORT   STATE SERVICE
21/tcp open  ftp
Service Info: OS: Unix
```

`$sudo nmap -p21 -sSCV 10.129.97.48`
```java
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.3
| ftp-syst: 
|   STAT: 
| FTP server status:
|      Connected to ::ffff:10.10.16.133
|      Logged in as ftp
|      TYPE: ASCII
|      No session bandwidth limit
|      Session timeout in seconds is 300
|      Control connection is plain text
|      Data connections will be plain text
|      At session startup, client count was 4
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_-rw-r--r--    1 0        0              32 Jun 04  2021 flag.txt
```

`$ftp 10.129.97.48 -a`
```java
Connected to 10.129.97.48.
220 (vsFTPd 3.0.3)
331 Please specify the password.
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> get flag.txt
local: flag.txt remote: flag.txt
229 Entering Extended Passive Mode (|||31155|)
150 Opening BINARY mode data connection for flag.txt (32 bytes).
100% |**************************************|    32        0.17 KiB/s    00:00 ETA
226 Transfer complete.
32 bytes received in 00:00 (0.05 KiB/s)
ftp> bye
221 Goodbye.
```


1. ¿Qué significa el acrónimo de 3 letras FTP? **File Transfer Protocol**
2. ¿En qué puerto suele escuchar el servicio FTP? **21**
3. FTP envía datos sin cifrar. ¿Qué acrónimo se utiliza para un protocolo posterior diseñado para ofrecer una funcionalidad similar a FTP, pero de forma segura, como una extensión del protocolo SSH? **sftp**
4. ¿Cuál es el comando que podemos usar para enviar una solicitud de eco ICMP y probar nuestra conexión con el servidor FTP? **ping**
5. Según tus análisis, ¿qué versión de FTP se ejecuta en el servidor FTP? **vsftpd 3.0.3**
6. Según tus análisis, ¿qué tipo de sistema operativo se ejecuta en el servidor FTP? **Unix**
7. ¿Cuál es el comando que debemos ejecutar para mostrar el menú de ayuda del cliente FTP? **ftp -?**
8. ¿Cuál es el nombre de usuario que se usa en FTP cuando se inicia sesión sin una cuenta? **Anonymous**
9. ¿Cuál es el código de respuesta que obtenemos cuando el FTP muestra el mensaje "Inicio de sesión exitoso"? **230**
10. Hay un par de comandos que podemos usar para listar los archivos y directorios disponibles en el servidor FTP. Uno es `dir`. ¿Cuál es el otro que es una forma común de listar archivos en un sistema Linux? **ls**
11. ¿Cuál es el comando utilizado para descargar el archivo que encontramos en el servidor FTP? **get**

