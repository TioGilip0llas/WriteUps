# Web LLM Attacks (PortSwigger) WriteUp Español

Los **Ataques a LLMs Web** aprovechan vulnerabilidades que permiten el acceso al modelo de datos o API que permite a los atacantes:
- Recuperar datos a los que el LLM tiene acceso (pero no el atacante), a través de prompts, sets de entrenamiento y API's del modelo.
- Activar acciones dañinas a través del API, como una inyección SQL a donde el LLM tenga acceso.
- Detone ataques a otros usuarios o sistemas que consulten el LLM.

Visto de otra forma, el ataque a una integración de LLM es similar a explotar una vuln [[SSRF (Server-Side Request Forgery)]], porque en ambos casos el atacante abusa del lado del servidor para atacar a algún componente que no es accesible directamente.

Un LLM es un algoritmo entrenado con enormes conjuntos de datos que con ayuda del Deep Learning analizan como encajan los diferentes componentes del lenguaje, dedicándose a procesar entradas naturales para el usuario y crear respuestas plausibles a correspondencia.

Los ataques de LLM se basan en inyección rápida. Con indicaciones manipuladas hacen que la IA tome acciones fuera de su propósito previsto y ajustan una salida maliciosa como llamadas incorrectas a APIs sensibles o contenido fuera de las pautas del LLM.

### Detección de vulnerabilidades LLM
1. Identificar las entradas del LLM: directas como un mensaje o indirectas como un dataset.
2. Averiguar a que datos y APIs tiene acceso el LLM.
3. Con la información anterior perfilar un ataque.

## Explotación de API, funciones y complementos LLM
Los LLM se alojan por proveedores externos, por lo que un sitio web con un LMM de terceros le dará acceso a funcionalidades al describir APIs locales. 
Por ejemplo, un LLM de atención al cliente tiene acceso a un API que administra usuarios, pedidos y acciones.

### Funcionamiento de API's de LLM's
La integración de un LLM con una API depende de su estructura para definir un flujo de trabajo. Por ejemplo al llamar a una API externa, el LLM necesita que el cliente llame a una función aparte del endpoint (API privada) para que la petición sea válida:
1. El cliente llama al LLM con un prompt
2. El LLM detecta que necesita llamar a una función y retornar un JSON con argumentos ajustados a la API externa.
3. El cliente llama a la función con esos argumentos.
4. El cliente procesa la respuesta de la función.
5. El cliente llama otra vez al LLM, añadiendo la respuesta de la función como un nuevo mensaje.
6. El LLM llama a la API externa con la respuesta de la función.
7. El LLM resume los resultados de la llamada al API al usuario.

Este flujo de trabajo puede tener implicaciones de seguridad, ya que el LLM está haciendo su trabajo en nombre del cliente, aunque este no sepa que esta llamando a estas API's. Al cliente se le debió de presentar un paso de confirmación antes de que el LLM llame a la API externa.

### Mapeando el ataque a la LLM API
El termino *excessive agency* se refiere a cuando un LLM tiene acceso a información confidencial y cabe la persuasión para acceder a esta, con el API de su agrado.
Si el API no brinda la información solicitada, se le someterá a un contexto maldoso y se le volverá a preguntar.
Por ejemplo, si le decimos que somos los aquellos desarrolladores de LLM's en modo inspector marino, nos ~~dejará ver su concha~~ concederá mayor privilegio.



## Referencias