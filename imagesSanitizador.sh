#!/bin/bash

# Función para calcular rutas relativas (compatible con macOS y Linux)
calculate_relative_path() {
    local source_dir="$1"
    local target_path="$2"
    
    if command -v realpath &> /dev/null; then
        realpath --relative-to="$source_dir" "$target_path" | sed 's/ /%20/g'
    else
        echo "$target_path" | sed "s|^$source_dir/||; s/ /%20/g"
    fi
}

# Buscar todos los archivos .md
find . -name "*.md" -print0 | while IFS= read -r -d '' md_file; do
    echo "Procesando: $md_file"
    md_dir=$(dirname "$md_file")

    # Extraer todas las rutas de imágenes del archivo .md
    grep -oP '!\[\]\([^\)]+\)' "$md_file" | sed -e 's/!\[\](//' -e 's/)$//' | while IFS= read -r img_ref; do

        # Decodificar URL (ej. %20 -> espacio)
        img_decoded=$(echo "$img_ref" | sed 's/%20/ /g')
        
        # Determinar ruta absoluta según el tipo de referencia
        if [[ "$img_decoded" == /* ]]; then          # Ruta absoluta desde raíz
            img_abs_path=".$img_decoded"
        elif [[ "$img_decoded" == */* ]]; then       # Ruta relativa con directorios
            img_abs_path="$md_dir/$img_decoded"
        else                                        # Solo nombre de archivo
            img_abs_path="$md_dir/$img_decoded"
        fi

        # Verificar si la imagen existe en la ruta actual
        if [[ -f "$img_abs_path" ]]; then
            echo " [+] Ruta válida: $img_ref"
        else
            echo " [-] Ruta inválida: $img_ref"
            
            # Buscar la imagen recursivamente desde el directorio del .md
            img_filename=$(basename "$img_decoded")
            found_path=$(find "$md_dir" -type f -name "$img_filename" | head -n 1)

            if [[ -n "$found_path" ]]; then
                # Calcular nueva ruta relativa (con codificación URL)
                new_relative=$(calculate_relative_path "$md_dir" "$found_path")
                
                # Reemplazar en el archivo .md (escapando caracteres para sed)
                old_ref_escaped=$(echo "$img_ref" | sed 's/[\/&]/\\&/g')
                new_ref_escaped=$(echo "$new_relative" | sed 's/[\/&]/\\&/g')
                
                sed -i "s|!\[\]($old_ref_escaped)|![]($new_ref_escaped)|g" "$md_file"
                echo " [+] Corregido: $img_ref ? $new_relative"
            else
                echo " [!] Imagen no encontrada: $img_filename"
            fi
        fi
    done
done

echo "[*] Proceso finalizado."
