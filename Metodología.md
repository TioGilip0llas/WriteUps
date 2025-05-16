Pega este código a tu reporte:
``` markdown
# Name (platform - dificultad) WriteUp Español
[🦔](#PreRequerimientos) #PreRequerimientos
- 

[🦔](#Reconocimiento) #Reconocimiento
- Escaneo usual (IP, TTL, Puertos, Versiones y Servicios, Launchpad)

[🦔](#VulnGathering) #VulnGathering
- 

[🦔](#Engaño) #Engaño
- 

[🦔](#Explotación) #Explotación
- 

[🦔](#GanarControl) #GanarControl
- 

[🦔](#Resultados-PoC) #Resultados-PoC

_Presiona al erizo para dirigirte al contenido._

## PreRequerimientos
Este documento son resultados y hallazgos obtenidos en una emulación de escenario de *prueba de penetración* en una modalidad de caja Gris.

La intención de la metodología usada es para presentar el reporte por *escenarios de riesgo*, mientras se obtiene el objetivo de la máquina objetivo. véase [[Metodología]]
#### Sobre la máquina
'''http
Nombre: 
Autor: 
Objetivo: 
Dificultad: 
Descargado de: 
'''

Desde una conexión de red interna, el escenario de pruebas se compone de:
> IP Atacante: 192.168.0.21

> IP Víctima:   x.x.x.x

#### Consideraciones adicionales
Para esta máquina se realizaron...

<small>Durante el reporte se utiliza '[...]' para omitir partes que no serán de interés en el proceso de penetración.</small>

## Reconocimiento
Se identificó la dirección IP de la máquina objetivo mediante `ARP-scan`:

El equipo fue identificado como una máquina virtual de VMware.

Se verificó la conectividad con un `ping`

Recibiendo respuestas con un TTL de **, lo cual indica un sistema **.

Posteriormente se realizó un escaneo de puertos completo con Nmap:

Un escaneo más detallado se ejecutó, para identificar versiones y servicios:

## VulnGathering
## Engaño
## Explotación
## GanarControl
## Resultados-PoC
```

---
## Explicación de Metodología

#### PreRequerimientos
Evaluar antes de actuar: clima, terreno, fuerzas, moral, etc. Equivale a definir alcance, reglas y objetivos.

#### Reconocimiento
Recolectar datos del adversario, sus puntos débiles y capacidades, es el eje de la información táctica.
Descubrimiento de infraestructura, tecnologías y posibles vectores de ataque.

#### VulnGathering
Uso de herramientas automáticas y análisis manual.
Encontrar vacíos en la defensa del enemigo: donde no esperan, atacar.

#### Engaño
"El arte del engaño": preparar ataques donde el enemigo es débil.
Priorización de vulnerabilidades según impacto, disponibilidad de exploits y severidad.

#### Explotación
El ataque debe ser inesperado, veloz y preciso. Como un exploit bien dirigido.
Intento de comprometer los sistemas utilizando exploits y técnicas manuales.

#### GanarControl
Aprovechar el caos tras la victoria: obtener control, asegurar posición y si es posible, avanzar en el terreno enemigo.
Escalada de privilegios, extracción de credenciales y persistencia en el sistema.

#### Resultados-PoC
Clasificación de hallazgos y creación del informe técnico con recomendaciones.
Finalizar con informe, evaluación del impacto y lecciones aprendidas.El supremo arte de la guerra es someter al enemigo sin luchar.



- **Planeación:**  En esta fase se realizó el kickoff donde el consultor proporciono los detalles de la ejecución del servicio y generó el documento SOW, el cual deberá fue firmado por **CLIENTE ACRÓNIMO** y **Scitum**.
- **Reconocimiento.** Durante esta fase se identificó información acerca de los elementos a evaluar, los componentes de red involucrados en la infraestructura, controles de seguridad, puertos, servicios, versiones, etc.
- **Identificación de vulnerabilidades.** Como parte de esta fase se realizó la identificación de vulnerabilidades conocidas a nivel de la infraestructura de forma automatizada y manual.
- **Preparación del ataque.** En esta fase se priorizaron las vulnerabilidades tomando en cuenta lo siguiente:

a.      Severidad.

b.      Impacto.

c.      Que la vulnerabilidad contara con un _exploit_ disponible públicamente en Internet.

d.      Que la vulnerabilidad pudiera ser aprovechada en el tiempo de las pruebas.

Se diseñaron vectores de ataque para intentar aprovechar los huecos de seguridad identificados.

- **Explotación.** En esta fase se ejecutaron los vectores de ataque diseñados en la fase anterior con el objetivo de comprobar si la vulnerabilidad era explotable en el contexto de configuración y seguridad.
- **Post-Explotación.** En esta fase se dejaron rastros de la explotación como archivos de texto, creación de cuentas de usuario, entre otros y de acuerdo con el alcance establecido y al tiempo de pruebas se intentó realizar una expansión del ataque mediante la explotación de vulnerabilidades en los dispositivos tecnológicos en los que se tuvo acceso a nivel del sistema operativo.

·        **Generación de resultados:** En esta fase, se clasificó la severidad de los hallazgos de acuerdo con el CVSS (Common Vulnerability Score System) y se priorizó su remediación, generando los entregables del servicio con las recomendaciones para la mitigación de los hallazgos identificados durante el servicio.