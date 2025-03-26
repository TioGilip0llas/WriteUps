[Link](https://www.vulnhub.com/entry/kioptrix-level-12-3,24/)

### Planeación

Como parte del análisis de seguridad, se planificó evaluar un sistema en la red interna para identificar posibles vulnerabilidades y determinar su resistencia a ataques específicos. El objetivo era ejecutar un reconocimiento inicial seguido de un análisis detallado para confirmar debilidades explotables y documentar los hallazgos.

### Reconocimiento

Mediante el uso de la herramienta **arp-scan**, se identificó que la dirección IP objetivo era **192.168.0.51**. 
![[Pasted image 20250120135012.png]]
Un análisis adicional, a través de ping, determinó que el sistema operativo era Linux, basado en un **TTL** de 64 en las respuestas ICMP.

![[Pasted image 20250120135044.png]]

Posteriormente, con un escaneo utilizando **Nmap**, se detectaron los puertos **22** (SSH) y **80** (HTTP) en estado abierto. A través de la información de las versiones y firmwares disponibles en los servicios, se dedujo que el sistema operativo era **Ubuntu 8.04.4 LTS (Hardy Heron)**, utilizando una versión específica de **OpenSSH 1:4.7p1-8ubuntu1**, confirmada mediante la plataforma **Launchpad**.
![[Pasted image 20250120135205.png]]

![[Pasted image 20250120140342.png]]
https://launchpad.net/ubuntu/+source/openssh/1:4.7p1-8ubuntu1
Ubuntu 8.04.4 LTS (Hardy Heron)
![[Pasted image 20250120140511.png]]
### Identificación de vulnerabilidades

Durante el reconocimiento del puerto HTTP, se observó la existencia del directorio **/phpmyadmin**, sugiriendo una potencial configuración vulnerable o acceso a bases de datos. 
![[Pasted image 20250120144948.png]]
![[Pasted image 20250120145135.png]]
Además, se determinó que el sistema era vulnerable a un exploit asociado con **Lotus CMS**, una herramienta conocida por presentar problemas de seguridad en versiones desactualizadas. 
![[Pasted image 20250120145413.png]]

![[Pasted image 20250120150118.png]]
Sin embargo, la ejecución inicial del exploit estándar no produjo resultados exitosos, por lo que fue necesario implementar modificaciones manuales al payload y ejecutarlo mediante Bash.
![[Pasted image 20250120162417.png]]

### Preparación de ataque

Se decidió ajustar el exploit de Lotus CMS para adaptarlo al entorno identificado y ejecutarlo en un shell de Bash, asegurando que el payload mantuviera la funcionalidad necesaria para obtener acceso inicial. Esto incluyó la configuración de una conexión para recibir una shell reversa, permitiendo interacción directa con el sistema comprometido.

![[Pasted image 20250120164414.png]]

### Explotación

Tras la ejecución exitosa del exploit modificado, se obtuvo una **reverse shell**, permitiendo acceso remoto al sistema con los privilegios del usuario que ejecutaba el servidor web. Este acceso brindó la capacidad de listar usuarios del sistema operativo y explorar archivos almacenados en el servidor.

![[Pasted image 20250120164651.png]]

![[Pasted image 20250120165043.png]]

![[Pasted image 20250120165141.png]]

### Post-explotación

Durante la exploración, se identificaron múltiples archivos de interés en el sitio comprometido que podrían contener información adicional. Estos hallazgos incluyen configuraciones sensibles que requieren análisis posterior, como credenciales almacenadas, configuraciones del servidor y datos potencialmente valiosos para extender el compromiso o explorar otros objetivos.

![[Pasted image 20250120184708.png]]

### Generación de resultados

Se logró comprometer el sistema identificado como **Ubuntu 8.04.4 LTS (Hardy Heron)** explotando una vulnerabilidad en Lotus CMS mediante un payload modificado. Los resultados incluyen acceso no autorizado al sistema, identificación de usuarios y recopilación de archivos potencialmente confidenciales. Este informe detalla los pasos seguidos, las técnicas utilizadas y los hallazgos encontrados para proponer remediaciones específicas que mitiguen las vulnerabilidades detectadas.


### Tabla de Vulnerabilidades

|**Escenario de Riesgo**|**Descripción**|**Vulnerabilidad Asociada**|**Severidad**|
|---|---|---|---|
|Exposición del directorio `/phpmyadmin`.|La existencia del directorio `/phpmyadmin` podría permitir acceso no autorizado a bases de datos y configuraciones sensibles del sistema.|Configuración insegura de phpMyAdmin.|Alta|
|Sistema operativo obsoleto (Ubuntu 8.04.4 LTS).|Uso de un sistema operativo sin soporte oficial, lo que lo hace vulnerable a múltiples exploits conocidos y sin parches.|Obsolescencia del software.|Alta|
|Vulnerabilidad en Lotus CMS.|Lotus CMS presentaba una vulnerabilidad explotable que permitió la ejecución remota de código mediante un payload ajustado para obtener acceso al sistema.|RCE en Lotus CMS.|Crítica|
|Configuración débil del servidor web.|El servidor web ejecuta código como un usuario con acceso a recursos internos, facilitando el compromiso inicial del sistema a través de una reverse shell.|Mala segregación de privilegios.|Alta|
|Exposición de archivos sensibles en el servidor.|Durante el análisis se identificaron archivos almacenados en el sistema web con información potencialmente sensible para el atacante.|Información expuesta en archivos.|Media|

### Notas

- La severidad de cada vulnerabilidad está basada en la facilidad de explotación, el impacto potencial en la infraestructura, y el alcance del compromiso del sistema.
- Las vulnerabilidades críticas requieren atención inmediata para evitar un compromiso completo del entorno.