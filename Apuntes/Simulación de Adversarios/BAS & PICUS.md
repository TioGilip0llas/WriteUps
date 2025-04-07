Introducción a BAS y PICUS
- ¿Qué es emulación?
	  Replicar el comportamiento de un adversario utilizando sus TTP's (técnicas, tácticas y procedimientos) en entornos seguros.
- ¿Qué es simulación?
	  Recreación de ataque, con herramientas automatizadas o entornos aislados, causando que no se repliquen completamente las TTP's, a través de eventos de ataques artificiales sin código malicioso real.
- ¿Cuál es la diferencia entre emulación y simulación?
	  La diferencia la resumo aquí:

| **Aspecto**      | **Pentest Real**               | **Simulación (PICUS)**         |
| ---------------- | ------------------------------ | ------------------------------ |
| **Riesgo**       | Alto (si fallan los controles) | Cero o mínimo                  |
| **Autenticidad** | Ataques reales                 | Comportamientos imitados       |
| **Entorno**      | Sistemas en producción         | Entornos aislados o copias     |
| **Resultados**   | Vulnerabilidades explotables   | Brechas en detección/respuesta |
| **Frecuencia**   | Esporádica (por coste/riesgo)  | Continua (automática y segura) |
- ¿Queremos **explotar vulnerabilidades** (pentest real) o **evaluar capacidades de detección** (simulación)?  
- ¿Necesitamos un informe para parchear sistemas (pentest) o para ajustar herramientas de seguridad (simulación)?  

- ¿Qué es un BAS?
	  Breach and Attack Simulation: herramienta que automatiza los ataques, para mejorar controles de seguridad y perfilar posibles atacantes.
	  - metodologías avanzadas para evaluar continuamente su postura de seguridad
	  - la **Simulación de Adversarios**, que permite replicar ataques en entornos controlados para medir la efectividad de los controles de seguridad y la capacidad de detección y respuesta.
	  - 
- Algunas soluciones BAS conocidas
	  https://www.attackiq.com/
- Que es Picus Security?
	  Es una empresa fundada en el 2013, ofrece una BAS completa, que apela alñ contexto actual, en el que una empresa debe conocer su exposición actual a través de: Simular (amenazas y sus acciones), validar (proteccion efectiva de controles de seguridad) y mitigar (brechas de seguridad donde los controles no funcionan bien)
**Objetivo de Picus**

- Validar controles de seguridad de forma continua y automática.
- Simula ataques reales para evaluar eficacia de soluciones como firewalls, antivirus, EDR, etc.

**Casos de uso principales**

- Validación de herramientas de seguridad.
- Evaluación del nivel de protección contra MITRE ATT&CK.
- Reportes para auditorías, CISO, y equipos técnicos.
- Recomendaciones automáticas de mejora.

 **Tipos de validación**

- **Red team automatizado**: simula tácticas y técnicas de atacantes.
- **Validación de endpoints**: comprueba eficacia de antivirus/EDR.
- **Validación de red**: analiza tráfico permitido o bloqueado por firewalls/IPS.

**Componentes clave**

- **Vector de ataque (attacker)**: inicia las simulaciones desde una ubicación simulada (interna o externa).
- **Vector de defensa (defender)**: máquina con herramientas de seguridad activas (EDR, AV, etc.).

**Resultados**

- Clasifica controles como: exitosos, fallidos o bloqueados.
- Detalla qué técnicas se detectaron, previnieron o fueron ignoradas.
- Se puede mapear contra MITRE ATT&CK Framework.

**Acciones y reportes**

- Exportación de reportes PDF para áreas técnicas y de auditoría.
- Integración con otras herramientas (SIEM, SOAR, EDR).
- Recomendaciones basadas en fallas para mejorar controles.

**Beneficios clave**

- Visibilidad continua del estado de seguridad.
- Ahorro de tiempo en pruebas manuales de red team.
- Pruebas realistas, controladas y sin impacto en la operación.

**Ejemplo Práctico**  
Imagina que PICUS simula un ataque de **phishing**:  
1. **Simulación**: Envía correos falsos a empleados (pero en un entorno controlado).  
2. **Objetivo**: Ver cuántos hacen clic, si el correo llega a la bandeja de entrada (filtros anti-spam) o si el SOC detecta la actividad maliciosa.  
3. **Resultado**: Informes para mejorar defensas, sin que nadie sea realmente engañado.  

![[Pasted image 20250403162923.png]]

Módulos:
1. ASV - Gestión de la exposición: Evaluar y validar exposiciones para minimizar el riesgo en toda la superficie de ataque.
2. CSV - Gestión de postura de seguridad en la nube: Identificar errores comunes de configuración en la nube. Comprender su impacto con simulaciones de ataques automatizados.
3. SCV - Validación de control de seguridad BAS: Descubrir, validar y mitigar brechas de seguridad mediante simulación de ataques reales.
4. Pentesting automatizado y mapeo de rutas de ataque: Identificar y eliminar rutas que un adversario puede tomar para poner en peligro a los usuarios activos.
5. Optimización del SOC: Optimizar detección y respuesta a las amenazas identificando cobertura de detección y evaluando rendimiento e higiene de reglas de detección para maximizar la eficacia del SIEM (Corrector de Logs)

Modulo SCV
Tomando en cuenta su librería de amenazas: Ataques de red, ataques de endpoint, ataques web, ataques vía e-mail, ataques de exfiltración de datos
- Evalúa la eficacia de controles de seguridad
- Valida la capacidad de protección y detección de amenazas
- Simula ataques en tiempo real
- Conoce amenazas emergentes
- Cuantifica nivel de detección y protección
- Realiza análisis de resultados obtenidos
- Proporciona ayuda para mitigar y priorizar brechas de seguridad
- Ayuda a la validación de detección de amenazas
- Ofrece evaluación y mejora continua de los controles de seguridad

Validación Automática de Seguridad con Picus - https://www.youtube.com/watch?v=UFLhoAhLP9Y

