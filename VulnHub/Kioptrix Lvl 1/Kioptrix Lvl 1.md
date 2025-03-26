[Link](https://www.vulnhub.com/entry/kioptrix-level-1-1,22/)!

### Planeación

Se realizó un análisis inicial para identificar sistemas activos en la red, centrándose en la dirección 192.168.0.46. Se planificó un enfoque que integró técnicas de enumeración activa y pasiva, además del uso de herramientas específicas como Metasploit para explorar servicios potencialmente vulnerables.

![[Pasted image 20250119112420.png]]

![[Pasted image 20250119112553.png]]

![[Pasted image 20250119112855.png]]

### Reconocimiento

Mediante la ejecución de `arp-scan`, se identificó que la IP 192.168.0.46 estaba activa en la red. Posteriormente, se utilizó una herramienta de escaneo de puertos que reveló varios servicios abiertos, incluidos el puerto 80 (HTTP) y un servicio relacionado con Samba.

![[Pasted image 20250119112744.png]]

![[Pasted image 20250119113807.png]]

![[Pasted image 20250119113839.png]]

![[Pasted image 20250119113911.png]]

![[Pasted image 20250119195856.png]]

![[Pasted image 20250119114012.png]]

![[Pasted image 20250119114056.png]]

![[Pasted image 20250119123322.png]]

En el puerto 80, el uso de una herramienta de fuzzing de directorios permitió descubrir un recurso web accesible en la URL `http://192.168.0.46/mrtg`. Esta URL reveló información adicional, incluyendo un dominio que se agregó al archivo de resolución local (hosts) para facilitar posteriores exploraciones. Paralelamente, se inició una enumeración del servicio Samba, en busca de vulnerabilidades conocidas.

![[Pasted image 20250119123343.png]]

![[Pasted image 20250119123407.png]]

MRTG (Multi Router Traffic Grapher) es una herramienta, escrita en C y Perl por Tobias Oetiker y Dave Rand, que se utiliza para supervisar la carga de tráfico de interfaces de red. MRTG genera un informe en formato HTML con gráficas que proveen una representación visual de la evolución del tráfico a lo largo del tiempo.

Para recolectar la información del tráfico del dispositivo (habitualmente routers) la herramienta utiliza el protocolo SNMP (Simple Network Management Protocol).

MRTG ejecuta como un demonio o invocado desde las tareas programadas del cron. Por defecto, cada cinco minutos recolecta la información de los dispositivos y ejecuta los scripts que se le indican en la configuración.

directorio http://192.168.0.46/manual
![[Pasted image 20250119125104.png]]
directorio http://192.168.0.46/manual/mod
![[Pasted image 20250119125219.png]]

directorio http://192.168.0.46/usage 
![[Pasted image 20250119125457.png]]

http://192.168.0.46/usage/usage_200909.html
![[Pasted image 20250119131001.png]]!
![[Pasted image 20250119131046.png]]

![[Pasted image 20250119132014.png]]

### Identificación de Vulnerabilidades

El análisis del servicio Samba se realizó utilizando el módulo de Metasploit `scanner/smb/smb_version`. Este módulo permitió identificar que el servidor SMB en 192.168.0.46 estaba configurado para soportar SMB versión 1, un protocolo obsoleto y altamente vulnerable. Además, se obtuvieron datos técnicos, incluyendo:

- Información sobre las versiones de protocolo admitidas.
- Identificación del sistema operativo remoto.
- Tiempo de actividad del servidor.
- Requisitos de firma para la comunicación SMB.

La versión detectada, Samba <2.2.8, es conocida por contener una vulnerabilidad crítica que permite la ejecución remota de código (RCE). Este hallazgo fue prioritizado para proceder con pruebas adicionales.
![[Pasted image 20250119195637.png]]

![[Pasted image 20250119202825.png]]

![[Pasted image 20250119203338.png]]

El módulo scanner/smb/smb_version de Metasploit se utiliza para determinar información sobre un servidor SMB remoto. Identifica la versión del protocolo y la información de capacidad. Si el servidor de destino admite la versión 1 de SMB, el módulo también intentará identificar el sistema operativo del host.


### Explotación

El exploit para Samba <2.2.8 fue ejecutado exitosamente desde Metasploit. Este exploit permitió una ejecución remota de código en el sistema objetivo, lo que resultó en la obtención de acceso mediante una sesión de Meterpreter. Dicha sesión permitió elevar privilegios automáticamente al nivel de superusuario (root), lo que confirmó la explotación completa de la vulnerabilidad.
A continuación, se muestran las funciones y opciones clave del módulo scanner/smb/smb_version:

Versiones de protocolo: enumera las versiones del protocolo SMB que admite el servidor.
Dialecto preferido: indica el dialecto preferido para la versión más reciente del protocolo que admite el servidor.
Requisitos de firma: especifica si el servidor requiere firmas de seguridad.
Tiempo de actividad: proporciona el tiempo de actividad del servidor, si el servidor proporciona tanto la hora actual como la hora del sistema.
GUID del servidor: ofrece un identificador único para el servidor, que se puede utilizar para identificar sistemas con múltiples interfaces de red.

![[Pasted image 20250119203845.png]]

https://www.exploit-db.com/exploits/10

![[Pasted image 20250119203947.png]]

![[Pasted image 20250119212751.png]]

![[Pasted image 20250119212806.png]]

### Post Explotación

En la sesión de Meterpreter obtenida, se realizaron las siguientes acciones:

1. **Enumeración del Sistema**:
    
    - Verificación de usuarios activos en el sistema.
    - Revisión de configuraciones y servicios relevantes.
2. **Recolección de Información Sensible**:
    
    - Identificación de archivos y directorios clave en el sistema.
    - Obtención de registros y posibles credenciales para otras máquinas.
3. **Aseguramiento de Acceso Persistente**:
    
    - Instalación de un payload persistente para mantener el control del sistema en caso de reinicio.
### Generación de Resultados

Se documentaron los hallazgos, comenzando con el análisis detallado de cada servicio detectado y las vulnerabilidades explotadas. Las conclusiones incluyeron recomendaciones técnicas, destacando la necesidad urgente de actualizar la versión de Samba a una compatible con SMB 2 o superior. También se subrayó la importancia de eliminar servicios obsoletos y aplicar políticas de refuerzo para asegurar los directorios accesibles mediante HTTP.

Claro, aquí tienes una tabla organizada con las vulnerabilidades encontradas en el sistema 192.168.0.46:

|**Escenario de Riesgo**|**Descripción**|**Vulnerabilidad Asociada**|**Severidad**|
|---|---|---|---|
|**Exposición de Directorio Web**|Se descubrió un directorio accesible en el puerto 80 con el recurso `http://192.168.0.46/mrtg`, que puede permitir la visualización de información sensible del servidor.|Acceso no autenticado al recurso web|Alta|
|**Vulnerabilidad de SMB**|El servidor SMB soporta la versión 1 del protocolo SMB, lo que lo hace susceptible a ataques de ejecución remota de código y otras técnicas de explotación conocidas.|SMB < 2.2.8 (RCE y abuso de SMBv1)|Crítica|
|**Acceso Remoto No Autorizado por SMB**|A través de la vulnerabilidad en SMB, se logró una explotación remota, obteniendo acceso a una shell de Meterpreter con privilegios elevados (root) al aprovechar una configuración débil de SMB.|RCE a través de SMB|Crítica|
|**Enumeración de Sistema No Controlada**|Se utilizó un escaneo de SMB con Metasploit para descubrir información sobre la versión del sistema operativo y configuraciones del servidor, lo que podría ser utilizado por un atacante para adaptar sus estrategias.|Fuga de información sensible en SMB|Moderada|

Esta tabla resume los escenarios de riesgo identificados, las vulnerabilidades asociadas a cada uno, y la severidad asociada con cada falla.