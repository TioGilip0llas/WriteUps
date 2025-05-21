## Archivos tar
```
#Comprimir
tar cvf archivo.tar /archivo/carpeta/*
#Descomprimir
tar -xvf archivo.tar
```
## Archivos .zip (zip)
```
#Comprimir
zip archivo.zip /carpeta/archivos
#Descomprimir
unzip archivo.zip
```
## Archivos .rar (rar)
```
#Comprimir
rar -a archivo.rar /carpeta/archivos
#Descomprimir
rar -x archivo.rar
```
## Archivos .tar.gz .tar.z .tgz
```
#Comprimir
tar czvf archivo.tar.gz /archivo/carpeta/*
#Descomprimir
tar xzvf archivo.tar.gz
#Obtener tar
gunzip archivo.tar.gz 
```
## Archivos .gz (gzip)
```
#Comprimir
gzip -q archivo
#Descomprimir
gzip -d archivo.gz
```
## Archivos .gz (gzip)
```
#Comprimir
gzip -q archivo
#Descomprimir
gzip -d archivo.gz
```
## Archivos .bz2 (bzip2)
```
#Comprimir
bzip2 archivo
#Descomprimir
bzip2 -d archivo.bz2
```