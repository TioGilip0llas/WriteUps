### 2. **Añadir `/bin/kerbrute` al `$PATH`**

Para poder ejecutar `kerbrute` desde cualquier directorio sin tener que escribir la ruta completa cada vez, puedes agregar `/bin/kerbrute` a la variable de entorno `$PATH`. Para hacer esto temporalmente (solo para la sesión actual), usa el siguiente comando:

```bash
export PATH=$PATH:/bin/kerbrute
```

Ahora podrás ejecutar `kerbrute` desde cualquier lugar usando:

```bash
kerbrute
```

Si deseas que este cambio sea permanente, puedes agregar esa línea al archivo de configuración de tu shell, como `~/.bashrc` o `~/.zshrc`, dependiendo del shell que uses.

```bash
echo 'export PATH=$PATH:/bin/kerbrute' >> ~/.bashrc
source ~/.bashrc
```

### 3. **Crear un enlace simbólico**

Si prefieres no modificar el `$PATH` directamente, puedes crear un enlace simbólico en un directorio que ya esté en el `$PATH`, como `/usr/local/bin`, lo que te permitirá ejecutar `kerbrute` desde cualquier ubicación sin escribir la ruta completa.

Para hacerlo, ejecuta:

```bash
sudo ln -s /bin/kerbrute/kerbrute /usr/local/bin/kerbrute
```

Con esto, podrás ejecutar `kerbrute` desde cualquier lugar:

```bash
kerbrute
```


### Pasos para crear un entorno virtual (venv):

1. **Instala el paquete `python3-venv` si no lo tienes instalado:** Este paquete proporciona las herramientas necesarias para crear entornos virtuales. Si no lo tienes instalado, ejecuta:
    
    ```bash
    sudo apt install python3-venv
    ```
    
2. **Crea un entorno virtual dentro de tu carpeta actual:** Navega a la carpeta en la que estás trabajando (ya estás en `~/Documentos/HackTheBox/Cicada`), y luego ejecuta:
    
    ```bash
    python3 -m venv venv
    ```
    
    Esto creará una carpeta llamada `venv` dentro de tu directorio actual, que contendrá un entorno virtual aislado.
    
3. **Activa el entorno virtual:** Para empezar a usar el entorno virtual, debes activarlo. En Linux, puedes hacer esto con el siguiente comando:
    
    ```bash
    source venv/bin/activate
    ```
    
    Al activar el entorno virtual, tu terminal debería cambiar para reflejar que estás dentro del entorno, y verás algo como `(venv)` al principio de la línea de comandos.
    
4. **Desactivar el entorno virtual cuando termines:** Cuando hayas terminado de trabajar, puedes salir del entorno virtual con el comando:
    
    ```bash
    deactivate
    ```
    

### Alternativa usando `pipx`:

Si no quieres crear un entorno virtual manualmente y prefieres que `pipx` gestione automáticamente el entorno virtual por ti, puedes instalar los paquetes con `pipx`:

1. **Instala `pipx`:**
    
    ```bash
    sudo apt install pipx
    ```
    
2. **Usa `pipx` para instalar los paquetes:**
    
    ```bash
    pipx install minidump minikerberos aiowinreg msldap winacl
    ```
    

`pipx` se encarga de crear un entorno virtual de forma automática para cada paquete, y es útil para herramientas que no forman parte del sistema global.

- **Método recomendado**: Crear un entorno virtual usando `python3 -m venv`.
- **Alternativa**: Usar `pipx` para gestionar entornos virtuales automáticamente.

