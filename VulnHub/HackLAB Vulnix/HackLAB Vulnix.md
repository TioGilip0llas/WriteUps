[link](https://www.vulnhub.com/entry/hacklab-vulnix,48/)

#### Planeación

Se realizó la planificación del análisis con el objetivo de identificar y evaluar los servicios activos y vulnerabilidades del sistema objetivo. La máquina a auditar se localizó dentro de una red interna, y el alcance del estudio incluyó la identificación de servicios expuestos y la validación de posibles vulnerabilidades asociadas.

#### Reconocimiento

Mediante un escaneo inicial con la herramienta `arp-scan`, se detectó la interfaz de red del sistema 192.168.0.54, confirmando su presencia dentro de la red. 

![[Pasted image 20250122093236.png]]

Posteriormente, un análisis detallado permitió identificar que el sistema opera bajo Linux con un kernel en el rango de versiones 2.6.32 a 3.9.

![[Pasted image 20250122093429.png]]

Puertos abiertos identificados.
![[Pasted image 20250122094107.png]]

![[Pasted image 20250122094142.png]]


#### Identificación de vulnerabilidades

Se procedió a realizar un escaneo de puertos con herramientas especializadas, lo que permitió identificar servicios expuestos y puertos abiertos. Entre los servicios identificados, destacan:

- **SSH (Puerto 22):** Versión OpenSSH 5.9p1, vulnerable a CVE-2016-10009 y CVE-2016-0777, relacionadas con fallos en autenticación y exposición de claves privadas.
- **SMTP (Puerto 25):** Implementado mediante Postfix, susceptible a CVE-2015-5301, permitiendo ataques de spam.
- **Finger (Puerto 79):** Servicio obsoleto que expone información sobre usuarios y facilita enumeración.
- **POP3 (Puerto 110) y IMAP (Puerto 143):** Operados por Dovecot, asociados a múltiples vulnerabilidades como CVE-2013-2143 y CVE-2017-9248, junto con fallos de cifrado SSL/TLS.
- **RPCBind (Puerto 111):** Expuesto a riesgos de ejecución remota mediante CVE-2013-0347.
- **Servicios adicionales:** NFS y puertos relacionados (2049, 40222, 47527), expuestos a configuraciones incorrectas que permiten acceso no autorizado a archivos.
### Puerto 22/tcp (SSH - OpenSSH 5.9p1)

- **Servicio:** SSH (Secure Shell)
- **Versión:** OpenSSH 5.9p1 Debian 5ubuntu1 (Ubuntu Linux; protocolo 2.0)
![[Pasted image 20250122123330.png]]
- **Vulnerabilidades:**
    - **CVE-2016-10009**: Vulnerabilidad de autenticación de usuario SSH en OpenSSH 7.0 y versiones anteriores.
    - **CVE-2016-0777**: Exposición de las claves privadas SSH en ciertas condiciones.
- **Recomendaciones:** Actualizar a una versión más reciente de OpenSSH, habilitar la autenticación por clave pública, y asegurarse de que las configuraciones de seguridad como `PermitRootLogin no` estén activadas.

### Puerto 25/tcp (SMTP - Postfix)

- **Servicio:** SMTP (Simple Mail Transfer Protocol)
- **Versión:** Postfix smtpd
- **Vulnerabilidades:**
    - **CVE-2015-5301**: Permite que un atacante remoto pueda enviar correos con una dirección de remitente falsa a través de un servidor Postfix vulnerable.
    - **Posibles abusos:** Exposición de comandos SMTP como VRFY (verificación de usuarios) y PIPELINING, que pueden facilitar ataques de spam o revelación de información.
- **Recomendaciones:** Habilitar STARTTLS para cifrado, deshabilitar comandos como VRFY y PIPELINING, y asegurarse de que el servidor esté correctamente configurado para evitar el envío de spam.

### Puerto 79/tcp (Finger)

- **Servicio:** Finger
- **Versión:** Linux fingerd
- **Vulnerabilidades:**
    - **Finger** es un protocolo antiguo y generalmente inseguro que revela información sobre los usuarios del sistema. El servicio es considerado obsoleto y puede ser explotado para realizar ataques de enumeración de usuarios.
- **Recomendaciones:** Deshabilitar el servicio `finger`, ya que generalmente no tiene justificación en sistemas modernos.

### Puerto 110/tcp (POP3 - Dovecot)

- **Servicio:** POP3 (Post Office Protocol v3)
- **Versión:** Dovecot pop3d
- **Vulnerabilidades:**
    - **CVE-2013-2143**: Vulnerabilidad en Dovecot POP3 que podría permitir la ejecución remota de código.
    - ssl-heartbleed (CVE-2024-0160): El error Heartbleed es una vulnerabilidad grave en la popular biblioteca de softw-are criptográfico OpenSSL. Permite robar información que se pretende proteger mediante cifrado SSL/TLS. 
		Las versiones 1.0.1 y 1.0.2-beta de OpenSSL (incluidas 1.0.1f y 1.0.2-beta1) se ven afectadas por el error Heartbleed. El error permite leer la memoria de los sistemas protegidos por las versiones vulnerables de OpenSSL y podría permitir la divulgación de información confidencial que de otro modo estaría cifrada, así como de las propias claves de cifrado.
		http://cvedetails.com/cve/2014-0160/
		https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-0160
		http://www.openssl.org/news/secadv_20140407.txt 

	    
    - 
    - SSL/TLS MITM vulnerability (CCS Injection): OpenSSL anterior a 0.9.8za, 1.0.0 anterior a 1.0.0m y 1.0.1 anterior a 1.0.1h no restringe adecuadamente el procesamiento de mensajes ChangeCipherSpec, lo que permite a los atacantes intermediarios activar el uso de una clave maestra de longitud cero en ciertas comunicaciones OpenSSL a OpenSSL y en consecuencia secuestrar sesiones u obtener información confidencial, a través de un protocolo de enlace TLS diseñado, también conocida como la vulnerabilidad de "inyección CCS"
    -Referencias:
	https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-0224
    http://www.openssl.org/news/secadv_20140605.txt
    http://www.cvedetails.com/cve/2014-0224
    

- **Recomendaciones:** Asegurarse de que Dovecot esté actualizado y habilitar cifrado mediante SSL/TLS. Utilizar mecanismos de autenticación seguros.

### Puerto 111/tcp (RPCBind)

- **Servicio:** RPCBind (Bind de llamadas a procedimiento remoto)
- **Versión:** 2-4 (RPC #100000)
- **Vulnerabilidades:**
    - **CVE-2013-0347**: Una vulnerabilidad en RPCBind que permite la ejecución remota de código.
    - **Posibles riesgos:** Los servicios asociados como NFS pueden estar expuestos si no se configuran correctamente.
- **Recomendaciones:** Limitar el acceso a RPCBind solo a redes confiables y deshabilitar los servicios innecesarios que dependen de él (como NFS, si no se utilizan).

### Puerto 143/tcp (IMAP - Dovecot)

- **Servicio:** IMAP (Internet Message Access Protocol)
- **Versión:** Dovecot imapd
- **Vulnerabilidades:**
    - **CVE-2017-9248**: Vulnerabilidad en Dovecot que podría permitir a un atacante acceder a correos electrónicos de manera no autorizada.
- **Recomendaciones:** Asegurar que el servidor IMAP esté actualizado y habilitar STARTTLS para cifrado de comunicaciones.

### Puerto 512/tcp (REXEC - Netkit)

- **Servicio:** Rexec (Remote Execution)
- **Versión:** Netkit-rsh rexecd
- **Vulnerabilidades:**
    - **Rexec** es un servicio obsoleto e inseguro porque transmite datos sin cifrado. Esto puede exponer credenciales y datos sensibles.
- **Recomendaciones:** Deshabilitar el servicio Rexec y utilizar alternativas más seguras como SSH.

### Puerto 513/tcp (Login)

- **Servicio:** Login
- **Versión:** No detectada
- **Vulnerabilidades:**
    - **Vulnerabilidad por diseño**: Este puerto está asociado a servicios de login sin cifrado, lo que puede exponer credenciales.
- **Recomendaciones:** Deshabilitar este servicio y utilizar métodos de autenticación más seguros.

### Puerto 514/tcp (Syslog - TCPWrapped)

- **Servicio:** Syslog (puerto envuelto)
- **Versión:** No identificada (envuelto)
- **Vulnerabilidades:**
    - El servicio está encapsulado o protegido por algún sistema, lo que hace difícil determinar vulnerabilidades exactas.
- **Recomendaciones:** Asegurarse de que el sistema de log esté bien configurado y protegido, y que no se filtren datos sensibles.

### Puerto 993/tcp (IMAPS - Dovecot)

- **Servicio:** IMAPS (IMAP sobre SSL)
- **Vulnerabilidades:**
    - La configuración del certificado SSL es antigua (fecha de validez hasta 2022), lo que indica que el servicio podría estar usando un certificado expirado, lo que genera riesgos de seguridad.
- **Recomendaciones:** Actualizar el certificado SSL y asegurarse de que la configuración de IMAPS esté correcta.

### Puerto 995/tcp (POP3S - Dovecot)

- **Servicio:** POP3S (POP3 sobre SSL)
- **Vulnerabilidades:**
    - Al igual que con IMAPS, el certificado SSL es antiguo y podría ser vulnerable.
- **Recomendaciones:** Actualizar el certificado SSL y configurar adecuadamente POP3S.

### Puerto 2049/tcp (NFS - NFS_ACL)

- **Servicio:** NFS (Network File System) con ACL
- **Vulnerabilidades:**
    - **CVE-2015-3186**: Explotación de NFS para obtener acceso no autorizado a archivos.
- **Recomendaciones:** Configurar adecuadamente las ACLs de NFS, y limitar el acceso solo a direcciones IP de confianza.

### Puertos 40222, 47527, 48074, 50968, 52796/tcp (Montaje NFS y Nlockmgr)

- **Servicios:** Mountd (Montaje NFS) y Nlockmgr (Bloqueo NFS)
- **Vulnerabilidades:**
    - El servicio NFS es sensible a configuraciones incorrectas y puede exponer archivos si no se limita adecuadamente.
- **Recomendaciones:** Deshabilitar o restringir el acceso a estos puertos si no se usan. Asegurarse de que los montajes NFS estén correctamente configurados y protegidos.

El comando "finger" es una utilidad de Linux que se utiliza para mostrar información sobre los usuarios que han iniciado sesión en el sistema. Los administradores de sistemas suelen utilizar este comando para recuperar información detallada del usuario, como el nombre de inicio de sesión, el nombre completo, el tiempo de inactividad, el tiempo de inicio de sesión y, a veces, la dirección de correo electrónico del usuario. 

#### Preparación de ataque

La información recopilada se analizó para establecer un plan de ataque. Se identificaron contraseñas débiles y configuraciones deficientes, aprovechando la vulnerabilidad asociada al protocolo SSH y la enumeración de usuarios expuestos mediante `finger`.


![[Pasted image 20250123120443.png]]

Se obtuvieron estos datos

![[Pasted image 20250123120604.png]]

El usuario USER según esto tiene como Shell predeterminada **BASH** y como Directorio propio **/home/user**

![[Pasted image 20250123163818.png]]

#### Explotación

Utilizando las credenciales del usuario "USER" con la clave **LETMEIN**, capturadas mediante técnicas previas, se logró establecer una conexión al sistema mediante SSH. Esto permitió explorar el sistema objetivo, navegar por directorios y probar los permisos del usuario comprometido. Aunque no se logró acceso directo a privilegios administrativos, se recopilaron indicios que podrían ser utilizados en futuras fases del ataque.

#### Post explotación

Durante la fase de post explotación, se identificó un directorio compartido perteneciente al usuario "VULNIX". Si bien no se logró acceso directo a este directorio, su existencia sugiere posibles rutas adicionales para explotación. Asimismo, se recopilaron metadatos que podrían facilitar el análisis y la búsqueda de otras vulnerabilidades.

#### Generación de resultados

En conclusión, se realizó un análisis exhaustivo del sistema 192.168.0.54. Se detectaron múltiples vulnerabilidades en servicios activos que requieren actualización o eliminación para mitigar riesgos. Entre las principales recomendaciones se incluyen: la actualización de OpenSSH, la desactivación de servicios obsoletos como `finger` y `rexec`, y la configuración adecuada de protocolos NFS, IMAP y POP3 con SSL/TLS habilitado. Estos resultados serán entregados al equipo responsable para la implementación de medidas correctivas.

![[Pasted image 20250123164319.png]]




- La mayoría de estos puertos están asociados con servicios de red antiguos y potencialmente inseguros.
- **Recomendaciones generales:** Deshabilitar los servicios innecesarios, actualizar cualquier software con vulnerabilidades conocidas, y utilizar cifrado SSL/TLS donde sea posible (por ejemplo, para POP3/IMAP). Limitar el acceso a los puertos que gestionan servicios como NFS o RPC a redes de confianza.

### Tabla de Vulnerabilidades Identificadas

|**Escenario de Riesgo**|**Descripción**|**Vulnerabilidad Asociada**|**Severidad**|
|---|---|---|---|
|Acceso no autorizado a través de SSH|Configuración insegura de autenticación permite ataques por fuerza bruta y acceso no autorizado.|CVE-2016-10009, CVE-2016-0777|Alta|
|Ataques de spam mediante SMTP|Configuración insegura en el servidor Postfix posibilita ataques de spam y envío de correos maliciosos.|CVE-2015-5301|Alta|
|Enumeración de usuarios|Servicio `finger` expone información detallada sobre usuarios del sistema, facilitando su enumeración.|Exposición inherente del servicio|Media|
|Exposición de credenciales en POP3/IMAP|Implementación deficiente de cifrado SSL/TLS compromete la seguridad de comunicaciones de correos.|CVE-2013-2143, CVE-2017-9248|Alta|
|Ejecución remota mediante RPCBind|Configuración insegura en RPC permite ejecutar comandos de forma remota en el sistema objetivo.|CVE-2013-0347|Alta|
|Exposición de archivos mediante NFS|Acceso no autorizado a sistemas de archivos compartidos a través de NFS.|Configuración incorrecta del servicio|Alta|

#### Notas Adicionales

1. Las vulnerabilidades de alta severidad requieren atención prioritaria, ya que exponen directamente al sistema a riesgos de acceso no autorizado, compromisos de datos, y escalación de privilegios.
2. Las de severidad media, aunque menos críticas, aumentan la superficie de ataque y deberían ser mitigadas para evitar futuros problemas.
3. La implementación de buenas prácticas, como la desactivación de servicios no esenciales y la aplicación de parches actualizados, puede mitigar estas vulnerabilidades.