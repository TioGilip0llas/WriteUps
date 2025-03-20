#!/bin/bash

# Buscar todos los archivos .md en el repositorio
find . -name "*.md" -print0 | while IFS= read -r -d '' file; do
    echo "Procesando: $file"
    md_dir=$(dirname "$file")  # Directorio del archivo .md

    # Buscar TODAS las imágenes en formato Markdown estándar
    grep -oP '!\[\]\([^\)]+\)' "$file" | sed -e 's/!\[\](//' -e 's/)$//' | while IFS= read -r img_ref; do
        # Decodificar %20 a espacios para manejo de rutas
        img_decoded=$(echo "$img_ref" | sed 's/%20/ /g')
        
        # Construir ruta absoluta de la imagen
        if [[ "$img_decoded" == /* ]]; then
            # Si la ruta es absoluta (desde raíz)
            img_abs_path=".$img_decoded"
        else
            # Si la ruta es relativa (desde el .md)
            img_abs_path="$md_dir/$img_decoded"
        fi

        # Verificar si la imagen existe en la ruta actual
        if [[ ! -f "$img_abs_path" ]]; then
            echo " [-] Ruta incorrecta: $img_ref"
            
            # Buscar la imagen recursivamente desde el directorio del .md
            found_img=$(find "$md_dir" -type f -name "$(basename "$img_decoded")" | head -n 1)
            
            if [[ -n "$found_img" ]]; then
                # Calcular nueva ruta relativa
                new_relative=$(realpath --relative-to="$md_dir" "$found_img" | sed 's/ /%20/g')
                
                # Reemplazar en el archivo .md
                sed -i "s|!\[\]($img_ref)|![]($new_relative)|g" "$file"
                echo " [+] Corregido: $img_ref ? $new_relative"
            else
                echo " [!] Imagen no encontrada: $img_decoded"
            fi
        else
            echo " [?] Ruta válida: $img_ref"
        fi
    done
done

echo "[*] Proceso finalizado."
