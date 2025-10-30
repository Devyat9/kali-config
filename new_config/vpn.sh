#!/bin/bash

vpnIP () {
        ip=$(ifconfig tun0 | tr ' ' '\n' | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | grep -vE '255.255.255.0|255.255.255.255|255.255.25|255.255.0.0')
        echo "target=\"$ip\"" > ~/.vpn
}
vpnIP


# Archivo de configuración para guardar la IP objetivo
config_file="$HOME/.vpn"

# Si se pasa un argumento al script, se usa como IP objetivo
if [ -n "$1" ]; then
    target_ip="$1"
    echo "target=\"$target_ip\"" > "$config_file"
elif [ -f "$config_file" ]; then
    # Si no hay argumento, se intenta leer la IP del archivo de configuración
    source "$config_file"
    target_ip="${target:-}"
else
    # Si no existe el archivo de configuración, se inicia vacío
    target_ip=""
fi

# Si no se configuró una IP, preguntar al usuario con un diálogo
if [ -z "$target_ip" ]; then
    target_ip=$(zenity --entry --title="Configurar IP" --text="Introduce la IP objetivo:" 2>/dev/null)
    if [ -n "$target_ip" ]; then
        echo "target=\"$target_ip\"" > "$config_file"
    else
        printf "<txt>Sin IP</txt>\n"
        printf "<tool>No se configuró ninguna IP</tool>\n"
        exit 1
    fi
fi

# Mostrar la IP configurada en verde y copiarla al portapapeles si es posible
if [ -n "$target_ip" ]; then
    printf "<icon>network-vpn-symbolic</icon>\n"
    printf "<txt><span foreground='white'>${target_ip}</span></txt>\n"
    if command -v xclip > /dev/null; then
        printf "<iconclick>sh -c 'printf %s | xclip -selection clipboard'</iconclick>\n" "${target_ip}"
        printf "<txtclick>sh -c 'printf %s | xclip -selection clipboard'</txtclick>\n" "${target_ip}"
        printf "<tool>IP objetivo: ${target_ip} (clic para copiar al portapapeles)</tool>\n"
    else
        printf "<tool>IP objetivo: ${target_ip} (instala xclip para copiar al portapapeles)</tool>\n"
    fi
else
    printf "<txt>Sin IP</txt>\n"
    printf "<tool>No se configuró ninguna IP</tool>\n"
fi
