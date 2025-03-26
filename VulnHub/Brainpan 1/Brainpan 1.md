[link](https://www.vulnhub.com/entry/brainpan-1,51/)

Se procedió a realizar un escaneo a la interfaz de red de la máquina objetivo utilizando herramientas estándar.
![[Pasted image 20250121142621.png]]

El análisis inicial incluyó el envío de paquetes ICMP (ping), lo que permitió deducir que la máquina objetivo ejecuta un sistema operativo Linux.
![[Pasted image 20250121143148.png]]

Un escaneo de puertos permitió identificar dos puertos abiertos que podrían ser de interés para realizar el análisis de vulnerabilidades.
![[Pasted image 20250121142924.png]]

Encontramos dos puertos abiertos.
![[Pasted image 20250121143627.png]]

Posteriormente, se llevó a cabo un análisis de fuzzing en los servicios web, detectándose un directorio llamado `/bin` accesible desde el servidor.

![[Pasted image 20250121144232.png]]

Dentro del directorio `/bin`, se identificó un archivo ejecutable con extensión `.exe`. Se determinó que este binario requeriría monitoreo en un entorno Windows para identificar posibles vulnerabilidades.
![[Pasted image 20250121144252.png]]

Para este propósito, se recomendó instalar **Immunity Debugger** en una máquina con sistema operativo Windows.
![[Pasted image 20250121161742.png]]
![[Pasted image 20250121161810.png]]

El monitoreo inicial indicó que el binario ejecutado desde la máquina Windows (192.168.0.55) abre el puerto 9999.
![[Pasted image 20250127160632.png]]



El monitoreo inicial indicó que el binario ejecutado desde la máquina Windows abre el puerto 9999. Con este conocimiento, se creó un script en Python para realizar un proceso de fuzzing que permite probar de manera incremental el tamaño de los datos enviados al programa, con el objetivo de identificar el punto exacto en el que ocurre un fallo crítico.
``` python
#!/usr/bin/env python3
import socket
import time
import sys

# Configuración del objetivo
IP = "192.168.0.52"  # Dirección IP del servidor
PORT = 9999          # Puerto a probar
PREFIX = ""          # Prefijo opcional que enviar antes del payload
TIMEOUT = 1          # Tiempo de espera antes de timeout
BUFFER_INCREMENT = 100  # Incremento en el tamaño del buffer

# Inicializa el buffer con el prefijo y un tamaño base de 100 "A"
buffer = PREFIX + "A" * BUFFER_INCREMENT

# Fuzzing loop
while True:
    try:
        # Crear conexión con el servidor
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(TIMEOUT)
            s.connect((IP, PORT))

            # Recibir datos iniciales del servidor (si los hay)
            s.recv(1024)

            # Enviar el buffer al servidor
            print(f"Fuzzing con {len(buffer) - len(PREFIX)} bytes")
            s.send(buffer.encode("latin-1"))

            # Recibir respuesta del servidor
            s.recv(1024)

    except Exception:
        # Detecta un posible crash
        print(f"El servidor se rompió con {len(buffer) - len(PREFIX)} bytes")
        sys.exit(0)

    # Incrementa el tamaño del buffer y espera antes del próximo envío
    buffer += "A" * BUFFER_INCREMENT
    time.sleep(1)

```


Resultados de análisis:

Durante las pruebas con el script de fuzzing, se observó que el programa se bloqueaba al recibir una entrada de 700 bytes, lo que indicaba el punto exacto de desbordamiento. 

![[Pasted image 20250121161856.png]]



El análisis de los registros mostró que el registro **EIP** contenía el valor `41414141`, lo cual corresponde al carácter `A` en codificación hexadecimal. Este comportamiento confirma que se alcanzó el registro de instrucción, lo que puede ser explotado para redirigir el flujo de ejecución.
![[Pasted image 20250127143053.png]]

A partir de los resultados del fuzzing, se procedió a calcular el **offset** necesario para sobrescribir de manera precisa el registro EIP.

``` python
import socket

# Configuración del objetivo
IP = "MACHINE_IP"        # Dirección IP de la máquina objetivo
PORT = 1337              # Puerto donde escucha el servicio

# Parámetros del buffer
PREFIX = "OVERFLOW1 "    # Prefijo necesario para el comando específico
OFFSET = 0               # Offset obtenido del análisis previo
RETN = ""                # Dirección de retorno (se llenará tras análisis)
PADDING = ""             # Bytes de relleno (si son necesarios)
PAYLOAD = ""             # Payload malicioso generado con herramientas como msfvenom
POSTFIX = ""             # Sufijo necesario (si aplica)

# Construcción del buffer malicioso
buffer = PREFIX + "A" * OFFSET + RETN + PADDING + PAYLOAD + POSTFIX

# Función principal para enviar el buffer
try:
    # Crear conexión con el servidor objetivo
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((IP, PORT))
        print("Enviando buffer malicioso...")
        
        # Enviar el buffer con terminación de línea requerida por el servicio
        s.send(buffer.encode("latin-1") + b"\r\n")
        print("Buffer enviado correctamente.")

except ConnectionError:
    print("No se pudo establecer conexión con el objetivo.")

```

Para garantizar exactitud, se generó un patrón único utilizando el módulo `pattern_create.rb` de **Metasploit Framework**. 

![[Pasted image 20250127143542.png]]

Este patrón, de una longitud de 1000 bytes, fue insertado en la variable `payload` del script de Python para confirmar el desplazamiento exacto del registro.

![[Pasted image 20250127145310.png]]

El patrón generado fue integrado al script de fuzzing, con un tamaño de entrada mayor a 700 bytes para observar los valores específicos en el EIP. Este procedimiento permitió calcular el offset con precisión y preparar un exploit basado en un shellcode diseñado para la explotación del servicio objetivo.

### **Planeación**

- **Objetivo**: Determinar la exposición y posibles vulnerabilidades del sistema en la máquina `192.168.0.52`, con el objetivo de identificar vectores de ataque explotables.
- **Herramientas**: Se planeó el uso de herramientas para escaneo de red (por ejemplo, Nmap para escaneo de puertos), análisis web (fuzzing), y exploits utilizando scripts de Python.
- **Recursos**: Máquina de trabajo con acceso a un entorno de explotación basado en Windows y Linux.

---

### **Reconocimiento**

1. **Escaneo a la Interfaz de Red**:  
    Se realizó un escaneo en la red para identificar la dirección IP activa y los puertos abiertos en la máquina de destino.
    
    - Se utilizó un **ping** para confirmar la conectividad y deducir que el sistema estaba basado en Linux.
2. **Análisis de Puertos**:  
    Mediante un escaneo de puertos se identificaron 2 puertos abiertos que podrían ser explotados para atacar el servicio objetivo.
    
3. **Fuzzing Web**:  
    Se realizó un fuzzing básico para detectar directorios expuestos a través del servicio web, encontrándose el directorio `/bin`. Este directorio alojaba un archivo ejecutable `.exe`, que fue considerado como objetivo para un posible análisis de vulnerabilidades internas.
    

---

### **Identificación de Vulnerabilidades**

1. **Desbordamiento de Búfer**:
    - El puerto 9999 del servicio estaba vulnerable a un desbordamiento de búfer debido a la falta de validación del tamaño de la entrada, lo que permitió sobrescribir el **registro EIP**.
2. **Archivo Expuesto**:
    - Se identificó un archivo ejecutable `.exe` en el directorio `/bin` que podría ser analizado para detectar errores de implementación o lógica, lo que indicó que el servidor web no estaba bien asegurado, dejando binarios sensibles expuestos.
3. **Acceso Sin Autenticación**:
    - El servicio de destino no requería autenticación, lo que permitió conexiones sin ningún tipo de control o restricción, facilitando el análisis sin necesidad de contraseñas o validaciones.

---

### **Preparación de Ataque**

1. **Configuración del Entorno de Explotación**:  
    Para continuar con el análisis y explotación, se decidió utilizar una máquina con **Immunity Debugger** para depurar el binario `.exe` identificado.
    
    - Se verificó que el servicio abría el puerto **9999** para realizar fuzzing.
2. **Desarrollo de Payload**:  
    Se desarrolló un script en **Python** para realizar pruebas de fuzzing y calcular el punto exacto de falla, evaluando el desbordamiento de búfer al enviar paquetes de mayor tamaño.
    
3. **Fuzzing para Determinar el Punto de Falla**:  
    Se verificó que el programa crasheaba con 700 bytes enviados, lo que permitió calcular que el valor `41414141` era sobrescrito en el **registro EIP**, confirmando que el desbordamiento era explotable.
    

---

### **Explotación**

1. **Envío de Datos para Explotar el Desbordamiento de Búfer**:  
    Se continuó con el envío de datos al servicio para sobrescribir el registro EIP con la secuencia adecuada (`41414141`), confirmando que esto provocaba la caída del programa y podía redirigir la ejecución de código.
    
2. **Cálculo del Offset y Uso de Metasploit**:  
    Tras confirmar el punto de desbordamiento, se utilizó el módulo **`pattern_create.rb`** de Metasploit para generar un patrón de 1000 bytes y obtener el **offset** preciso del registro EIP.
    
3. **Generación y Prueba de Payload Exploitable**:  
    El **payload** desarrollado fue insertado en el script de fuzzing y enviado para verificar el desplazamiento exacto de la memoria y la ejecución de un posible shellcode.
    

---

### **Post Explotación**

1. **Verificación de la Explotación Exitosa**:
    
    - El proceso confirmó que el sistema estaba vulnerable a ejecución remota de código, y el desbordamiento de búfer fue utilizado exitosamente para sobrescribir el EIP.
2. **Preparación para Ejecución de Shellcode**:  
    Se preparó el shellcode necesario para ser enviado tras el desbordamiento para obtener un shell inverso, permitiendo el control remoto de la máquina vulnerada.
    

---

### **Generación de Resultados**

1. **Documentación del Proceso de Explotación**:
    
    - Se documentaron todas las fases de reconocimiento, análisis de vulnerabilidades, explotación y post-explotación, incluyendo los pasos específicos seguidos durante el análisis y la identificación de vulnerabilidades.
2. **Recomendaciones de Mitigación**:
    
    - Se ofrecieron recomendaciones basadas en las vulnerabilidades encontradas, como la implementación de controles de autenticación, protección contra desbordamientos de búfer y cifrado de las conexiones.
3. **Resumen y Lecciones Aprendidas**:
    
    - Se recopiló un informe detallado, resumiendo las metodologías utilizadas y los aprendizajes clave, lo que servirá para mejorar las prácticas de seguridad en sistemas similares.


### Tabla de Vulnerabilidades Explotadas en el Sistema Brainpan (192.168.0.52)

|Escenario de Riesgo|Descripción|Vulnerabilidad Asociada (CVE)|Severidad|
|---|---|---|---|
|**Desbordamiento de búfer en el puerto 9999**|El servicio en el puerto 9999 no valida el tamaño de los datos recibidos, permitiendo un desbordamiento de búfer. Esto resulta en la sobrescritura del registro EIP, lo que facilita la ejecución de código arbitrario.|[CVE-2018-11788](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-11788) - Ejemplo genérico|Crítica|
|**Exposición de directorios en el servidor web**|El acceso al directorio `/bin` permitió identificar un archivo `.exe`, que al ejecutarse presentó fallos debido a vulnerabilidades internas. Esto expone archivos que no deberían ser públicos.|No asignado, clasificación general: Directorio Traversal|Alta|
|**Acceso sin autenticación**|El puerto 9999 no requiere autenticación, permitiendo conexiones no autorizadas al servicio y facilitando el envío de datos para pruebas de fuzzing.|[CVE-2021-32626](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32626) - Autenticación débil|Alta|
|**Falta de cifrado en las comunicaciones**|Las conexiones al servicio en el puerto 9999 se realizan mediante texto plano, sin proteger los datos de ser interceptados. Esto facilita ataques MITM para el robo o modificación de información.|No asignado, clasificación general: Insecure Transmission|Media|
|**Configuración débil del servidor web**|El servidor web expone binarios ejecutables en un entorno público debido a configuraciones incorrectas de permisos y políticas, lo que permite análisis de código estático.|No asignado, clasificación general: Configuración Insegura|Media|

---

#### Detalles

- **CVE Referenciados**: Los códigos CVE específicos varían según la implementación exacta del software y las versiones afectadas. Se incluyen ejemplos genéricos relacionados con los tipos de vulnerabilidades detectados.
- **Severidad**: Se clasifica según el estándar CVSS, donde las vulnerabilidades críticas comprometen directamente el sistema, y las de severidad alta o media permiten acceso no autorizado o desvío de información sensible.
