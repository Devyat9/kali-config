#!/bin/bash

# Ejecucion
# -> Pasar a un archivo varios comandos por ej nmap -p- etc etc
# ejecutar
# sudo bash tmux_command_execute.sh commands.txt
# abrira el tmux como root y sera shortcut B y ejecutandose todo en paralelo


# Verificación de argumento
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 archivo_con_comandos.txt"
    exit 1
fi

FILE="$1"

# Verifica que el archivo existe
if [ ! -f "$FILE" ]; then
    echo "El archivo '$FILE' no existe."
    exit 1
fi

# Nombre de la sesión tmux
SESSION="nmap_scan"

# Crear nueva sesión de tmux en segundo plano
tmux new-session -d -s $SESSION

# Variable para controlar el primer comando
FIRST=1

# Leer línea por línea del archivo
while IFS= read -r cmd || [ -n "$cmd" ]; do
    # Saltar líneas vacías o comentarios
    [[ -z "$cmd" || "$cmd" =~ ^# ]] && continue

    if [ $FIRST -eq 1 ]; then
        tmux send-keys -t $SESSION "$cmd" C-m
        FIRST=0
    else
        tmux split-window -t $SESSION
        tmux select-layout -t $SESSION tiled
        tmux send-keys -t $SESSION "$cmd" C-m
    fi
done < "$FILE"

# Seleccionar el primer panel y adjuntarse
tmux select-pane -t $SESSION:0.0
tmux attach -t $SESSION
