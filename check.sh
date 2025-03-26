#!/bin/bash

# Función para listar imágenes de un archivo .md
listar_imagenes() {
    file="$1"  
    grep -oP '!\[\[(.*?)\]\]|\!\[\](.*?(\.png|\.jpg|\.jpeg|\.gif))' "$file" | while read line; do
        if [[ "$line" =~ !\[\[(.*)\]\] ]]; then
            image_name="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ !\[\](.*\.(png|jpg|jpeg|gif)) ]]; then
            image_name="${line#![]}"
        fi
        cleaned_image_name=$(limpiar_imagenes "$image_name")
        echo "$cleaned_image_name" >> req_img.tmp
    done
}

# Función para limpiar el nombre de la imagen
limpiar_imagenes() {
    image_name="$1"
    image_name=$(echo "$image_name" | sed 's/^(\(.*\))/\1/')
    image_name=$(echo "$image_name" | sed 's/%20/ /g')
    image_name=$(echo "$image_name" | sed 's/.*\/\([^\/]*\)$/\1/')
    echo "$image_name"
}

# Función para encontrar imágenes en el sistema de archivos
encontrar_imagenes() {
    find . -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" \) | sed 's|^\./||' | while read file; do
        cleaned_image_name=$(limpiar_imagenes "$file")
        echo "$cleaned_image_name"
    done > curr_img.tmp
}

# Función para encontrar imágenes faltantes
encontrar_imagenes_faltantes() {
    echo "[!] Las siguientes imágenes mencionadas en los apuntes no se encontraron en el sistema:" > missing_img.log
    while read image; do
        if ! grep -qx "$image" curr_img.tmp; then
            echo "$image" >> missing_img.log
        fi
    done < req_img.tmp
    cat missing_img.log
}

# Función para eliminar imágenes no usadas
imagenes_no_usadas() {
    if [[ ! -f "req_img.tmp" || ! -f "curr_img.tmp" ]]; then
        echo "[!] No se encontraron los archivos temporales."
        return 1
    fi

    total_curr=$(wc -l < curr_img.tmp)
    total_req=$(wc -l < req_img.tmp)

    if (( total_curr > total_req )); then
        # Hay imágenes no usadas, se procede a eliminarlas
        no_usadas_imagenes=$((total_curr - total_req))
        echo "Hay $no_usadas_imagenes imágenes no usadas."
        read -p "¿Quieres eliminar estas imágenes no usadas? (s/n): " respuesta

        if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
            echo "[*] Eliminando imágenes no usadas..."
            while read image; do
                if ! grep -qx "$image" req_img.tmp; then
                    image_path=$(find . -type f -iname "$image" 2>/dev/null)
                    if [[ -n "$image_path" ]]; then
                        echo "Eliminando $image_path"
                        rm -f "$image_path"
                    else
                        echo "$image no encontrada en el sistema."
                    fi
                fi
            done < curr_img.tmp
            echo "[*] Las imágenes no usadas han sido eliminadas."
        else
            echo "[*] No se eliminaron imágenes."
        fi

    elif (( total_curr == total_req )); then
        echo "[*] Todas las imágenes en el sistema están en los apuntes. No se eliminó ninguna imagen."
    else
        echo "[!] Revisa la disponibilidad de imágenes en tus apuntes."
        encontrar_imagenes_faltantes
    fi

    # Eliminar archivos temporales
    rm -f curr_img.tmp req_img.tmp
}

# Buscar todos los archivos .md en el repositorio y procesarlos
echo "[*] Procesando tus apuntes de Obsidian."
find . -name "*.md" | while read file; do
    listar_imagenes "$file"
done

total_req=$(wc -l < req_img.tmp)
echo "[*] Halladas $total_req imágenes en los apuntes."

# Ejecutar la búsqueda de imágenes en el sistema
encontrar_imagenes

total_curr=$(wc -l < curr_img.tmp)
echo "[*] Halladas $total_curr imágenes en el sistema."

# Comparar y decidir acción
imagenes_no_usadas

