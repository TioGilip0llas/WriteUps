#!/bin/bash

# Buscar todos los archivos .md en el repositorio
find . -name "*.md" | while read file; do
    echo "Procesando: $file"

    # Extraer la ruta relativa desde el archivo
    while read -r line; do
        if [[ "$line" =~ !\[\]\(\./(.*) ]]; then
            # Extraer la ruta de la imagen después de './'
            image_path="${BASH_REMATCH[1]}"
            
            # Reemplazar espacios por %20 en la ruta extraída (si es necesario)
            image_path_encoded=$(echo "$image_path" | sed 's/ /%20/g')

            # Determinar la ruta relativa de la imagen en base a la carpeta del archivo .md
            folder_path=$(dirname "$file")
            target_path="${folder_path}/$image_path_encoded"

            # Verificar que el archivo de imagen existe
            if [[ -f "$target_path" ]]; then
                # Cortar la ruta para que sea relativa desde la carpeta de imágenes (sin duplicar carpetas)
                relative_path=$(echo "$image_path" | sed 's|^.*images/|images|')

                # Reemplazar la ruta en el archivo .md con la ruta correcta
                sed -i "s|![](./$image_path)|![]($relative_path)|g" "$file"

                echo " ? Ruta corregida en: $file"
            else
                echo "Imagen no encontrada en: $target_path"
            fi
        fi
    done < "$file"
done

echo "? Proceso de corrección finalizado."


