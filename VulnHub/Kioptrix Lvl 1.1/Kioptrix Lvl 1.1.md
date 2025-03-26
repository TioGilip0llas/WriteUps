[Link](https://www.vulnhub.com/entry/kioptrix-level-11-2,23/)!

### Planeación

En la etapa inicial se definió el objetivo de evaluar la seguridad del sistema con dirección IP **192.168.0.50**, estableciendo un enfoque progresivo desde el descubrimiento inicial de la máquina en la red, pasando por la enumeración de servicios y vulnerabilidades, hasta la escalación de privilegios y extracción de datos sensibles. La planificación consideró el uso de herramientas y técnicas estándar para realizar pruebas de penetración con el debido resguardo de la confidencialidad de la información.

### Reconocimiento

Se llevó a cabo un escaneo de red utilizando la herramienta `arp-scan`, lo cual permitió identificar la dirección IP **192.168.0.50** en el entorno.


![[Pasted image 20250119223054.png]]

Posteriormente, se procedió a ejecutar un escaneo de puertos para determinar los servicios en ejecución. Los resultados indicaron la presencia de varios puertos abiertos en el sistema:

- **Puerto 22**: SSH
- **Puerto 80**: HTTP
- **Puerto 111**: RPCBind
- **Puerto 443**: HTTPS
- **Puerto 601**: Un servicio relacionado con X11
- **Puerto 631**: Servicio de impresión (CUPS)
- **Puerto 3306**: MySQL



![[Pasted image 20250119223208.png]]

Cada uno de estos servicios fue evaluado detalladamente en búsqueda de vulnerabilidades.

![[Pasted image 20250119223606.png]]

![[Pasted image 20250119223646.png]]

![[Pasted image 20250119223709.png]]

![[Pasted image 20250119223742.png]]

### Identificación de Vulnerabilidades

Se detectó una **vulnerabilidad de inyección SQL (SQLi)** en el servicio HTTP asociado al puerto 80.

![[Pasted image 20250119224343.png]]

Adicionalmente, al explorar el contenido de la aplicación web, se identificó una funcionalidad de sistema que permite realizar pings desde la interfaz. Tras varias pruebas, se determinó que esta funcionalidad presenta una **ejecución remota de comandos (RCE)** al aceptar comandos arbitrarios en el sistema subyacente. Este comportamiento permitió interactuar con el sistema como el usuario **apache**, cuyo rol estaba restringido pero susceptible a ser utilizado para obtener una reverse shell.

![[Pasted image 20250119224407.png]]

![[Pasted image 20250119224430.png]]

![[Pasted image 20250119231428.png]]

![[Pasted image 20250119231607.png]]

### Preparación de Ataque

Se diseñó un ataque enfocado en aprovechar las vulnerabilidades identificadas.

1. Se utilizó la vulnerabilidad RCE en la funcionalidad de ping para obtener acceso al sistema mediante una **reverse shell**.
2. Se exploraron directorios y configuraciones del sistema para identificar potenciales oportunidades de escalación de privilegios.

![[Pasted image 20250119231630.png]]

### Explotación

Una vez establecida la reverse shell, el sistema fue comprometido desde el contexto del usuario **apache**. Desde este nivel de acceso se ejecutaron las siguientes acciones:

1. **Enumeración de usuarios:** Se accedió a la lista de usuarios registrados y sus respectivos directorios en el sistema.
![[Pasted image 20250119235146.png]]

2. **Obtención de credenciales de MySQL:** Se localizaron y descifraron archivos de configuración con credenciales almacenadas para la base de datos MySQL.

![[Pasted image 20250120000533.png]]

3. **Identificación de oportunidad de escalación de privilegios:** Se detectó una vulnerabilidad en el kernel del sistema operativo, lo que permitió la ejecución de un exploit público para obtener acceso como usuario privilegiado (**root**).



-s, --kernel-name        print the kernel name
-r, --kernel-release     print the kernel release
-v, --kernel-version     print the kernel version
-o, --operating-system   print the operating system

![[Pasted image 20250119233152.png]]

![[Pasted image 20250119233547.png]]

![[Pasted image 20250120001419.png]]

### Post-Explotación

Con privilegios elevados, las siguientes acciones fueron realizadas:

1. Se consultaron las bases de datos de MySQL, incluyendo las tablas que almacenan usuarios y contraseñas.


![[Pasted image 20250120002348.png]]

![[Pasted image 20250120003058.png]]

![[Pasted image 20250120003811.png]]

2. Se accedió al archivo `/etc/passwd`, lo que permitió enumerar usuarios del sistema y obtener sus hashes. Esta información se puede utilizar para evaluar la solidez de las contraseñas mediante técnicas de cracking.

![[Pasted image 20250120004348.png]]

A continuación, se presenta la tabla con las vulnerabilidades identificadas en el sistema 192.168.0.50:

|**Escenario de Riesgo**|**Descripción**|**Vulnerabilidad Asociada**|**Severidad**|
|---|---|---|---|
|Ejecución arbitraria de comandos|La funcionalidad de ping en el sitio web permite la inserción de comandos del sistema, posibilitando la ejecución remota desde el contexto de apache.|Ejecución Remota de Comandos (RCE)|Crítica|
|Exposición de credenciales de base de datos|Archivos de configuración del sistema contienen credenciales de MySQL en texto plano, lo que facilita el acceso no autorizado a la base de datos.|Gestión insegura de credenciales|Alta|
|Kernel vulnerable a escalación de privilegios|El sistema operativo utiliza un kernel con una vulnerabilidad conocida que puede ser explotada para obtener privilegios de administrador.|Vulnerabilidad de escalación de privilegios|Crítica|
|Tabla de usuarios y contraseñas expuesta en la base de datos|Información sensible de usuarios y contraseñas se encuentra almacenada sin medidas de protección adecuadas contra accesos no autorizados.|Exposición de datos sensibles|Alta|
|Hashes de contraseñas en `/etc/passwd` accesibles tras escalación|Los hashes de contraseñas están accesibles tras comprometer el sistema, permitiendo posibles ataques de fuerza bruta para descubrir contraseñas.|Almacenamiento inseguro de hashes|Alta|

**Nota:** Las calificaciones de severidad siguen la convención de categorizar como **Crítica**, **Alta**, **Media** o **Baja**, basadas en el impacto y la probabilidad de explotación de la vulnerabilidad.