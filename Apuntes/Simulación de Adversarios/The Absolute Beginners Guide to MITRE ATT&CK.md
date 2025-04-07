### Indicadores de Compromiso (IOCs)

Los **IOCs** (Indicators of Compromise) son huellas digitales que dejan los atacantes después de comprometer un sistema. Sirven para:

- **Entender lo que ya ocurrió** en un incidente de seguridad.
    
- **Prepararse para futuros ataques**, anticipando tácticas similares.
    
- **Detectar y responder** rápidamente a amenazas que reutilizan los mismos métodos.
    

### Clasificación de IOCs

No todos los IOCs tienen el mismo valor. Algunos son muy específicos y fáciles de cambiar para el atacante, mientras que otros revelan comportamientos más profundos y difíciles de modificar. Por eso es clave clasificarlos y priorizar los más útiles para defensa.

### Pirámide del Dolor (Pyramid of Pain)

La **Pirámide del Dolor** es un modelo que representa cuán difícil es para un atacante cambiar un indicador, y cuánto valor aporta ese indicador al defensor. De arriba (más difícil y más útil) a abajo (más fácil y menos útil):

- **TTPs (Tactics, Techniques and Procedures)** – _Muy difícil de cambiar_. Reflejan el **comportamiento** del atacante.
    
- **Tools (Herramientas)** – _Desafiante_. Cambiar herramientas requiere tiempo y habilidades.
    
- **Artefactos de Red o de Host** – _Molesto_. Son detalles técnicos específicos del ataque.
    
- **Dominios** – _Fácil_. Registrar un nuevo dominio toma segundos.
    
- **Direcciones IP** – _Muy fácil_. Cambiar de IP es trivial hoy en día.
    
- **Hashes (como SHA256)** – _Trivial_. Basta recompilar o cifrar diferente el archivo.


### **MITRE ATT&CK: Relación de Componentes**

MITRE ATT&CK es un marco que relaciona diferentes elementos clave en la actividad de los adversarios:
![[Pasted image 20250404110402.png]]

- **Campaign** (Campaña): Conjunto de actividades maliciosas con un objetivo específico.
    
- **Software**: Herramientas utilizadas en los ataques, ya sea malware o herramientas legítimas mal utilizadas.
    
- **Group** (Grupo): Conjunto de actores de amenaza (como APTs) con técnicas y tácticas documentadas.
    
- **Técnica y Subtécnica**: Métodos específicos usados por los atacantes. Cada técnica pertenece a una táctica.
    
- **Táctica**: Objetivo general del atacante (Ej. Persistence, Privilege Escalation, Exfiltration, etc.). Hay **14 tácticas** en MITRE ATT&CK.
    
- **Mitigación**: Medidas para reducir el impacto de una técnica específica.
    
- **Data Component**: Información relacionada con la actividad del ataque.
    
- **Data Source**: Fuentes de datos utilizadas para detectar ataques (Ej. logs, tráfico de red, eventos de sistema).
    

Además de mitigar las técnicas, ATT&CK también ayuda en la **detección** de actividades maliciosas con ejemplos de procedimientos y grupos de ataque, muchos de ellos con nombres que comienzan con **APT (Advanced Persistent Threats).**



### **Red Teaming y Simulación de Adversarios**

La simulación en Red Teaming puede incluir enfoques de **pruebas automatizadas y planes de micro-emulación.** Existen tres niveles de pruebas según su alcance:
![[Pasted image 20250404115532.png]]

1. **Atomic Testing**
    
    - Evalúa una técnica específica de forma aislada.
        
    - Se ejecutan pruebas simples y controladas.
        
    - Ejemplo: Ejecutar un `Mimikatz` solo para validar detección.
        
2. **Micro Emulation (Plans Guide)**
    
    - Planes de emulación que combinan varias técnicas relacionadas.
        
    - Busca imitar una parte específica de un ataque real.
        
    - Ejemplo: Un plan de emulación que prueba el robo de credenciales y la escalación de privilegios.
        
3. **Full Emulation (Scenario-Based Testing)**
    
    - Reproduce ataques completos basados en escenarios reales.
        
    - Involucra múltiples tácticas y técnicas a lo largo del ciclo de ataque.
        
    - Ejemplo: Simular toda la cadena de ataque de un grupo APT.
        

Cada enfoque tiene su utilidad dependiendo de los objetivos del equipo de Red Team y la madurez de la organización en términos de seguridad ofensiva.

![[Pasted image 20250404115237.png]]

![[Pasted image 20250404115456.png]]

