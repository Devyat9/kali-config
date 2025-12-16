#!/bin/bash

#=============================================================================
# tmux_nmap - Escáner automático nmap en 2 fases
#=============================================================================
# Fase 1: nmap -p- (descubrir puertos)
# Fase 2: nmap -sCV -p$PORTS (detectar servicios)
# Modo specific: Escanear puertos comunes
# Modo custom: Comando nmap personalizado
#=============================================================================

VERSION="5.0"
SESSION="nmap_scan"
MAX_THREADS=5
RESUME_MODE=false
SCAN_MODE="normal"  # normal, specific, custom
CUSTOM_CMD=""
TARGETS=()
EXCLUDE_HOSTS=()

#=============================================================================
# UTILIDADES
#=============================================================================

log() {
    echo "[*] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

show_help() {
    cat << 'EOF'
tmux_nmap - Escáner automático nmap en 2 fases

USO:
  tmux_nmap [OPCIONES] <TARGET>

TARGETS:
  IP                    10.10.86.99
  CIDR                  192.168.1.0/24
  -iL <archivo>         Leer targets desde archivo

MODOS DE ESCANEO:
  -s                    Escanear solo puertos comunes
  -c "cmd"              Ejecutar comando nmap personalizado

OPCIONES:
  -t NUM                Threads simultáneos (default: 5)
  -iL <archivo>         Leer targets desde archivo
  --exclude <archivo>   Excluir hosts
  --resume              Continuar escaneos previos
  -h, --help            Ayuda

EJEMPLOS:
  # Modo normal (2 fases)
  tmux_nmap 10.10.86.99
  tmux_nmap -t 10 192.168.1.0/24
  tmux_nmap -t 20 -iL scope.txt
  
  # Modo specific (puertos comunes)
  tmux_nmap -s 192.168.1.0/24
  tmux_nmap -s -iL scope.txt
  
  # Modo custom (comando personalizado)
  tmux_nmap -c "-sU -p53,161" 192.168.1.0/24
  tmux_nmap -c "-p80,443 -sV --script=http-title" -iL scope.txt

WORKFLOW NORMAL:
  1. Fase 1: nmap -p- (descubrir puertos)
  2. Fase 2: nmap -sCV -p$PORTS (detectar servicios)

ARCHIVOS:
  ports_<IP>.{nmap,gnmap,xml}       (fase 1)
  service_<IP>.{nmap,gnmap,xml}     (fase 2)
  specific_<IP>.{nmap,gnmap,xml}    (modo specific)

EOF
    exit 0
}

show_usage() {
    cat << 'EOF'
tmux_nmap - Escáner automático nmap en 2 fases

USO:
  tmux_nmap [OPCIONES] <TARGET>

TARGETS:
  IP                    10.10.86.99
  CIDR                  192.168.1.0/24
  -iL <archivo>         Leer targets desde archivo

MODOS DE ESCANEO:
  -s                    Escanear solo puertos comunes
  -c "cmd"              Ejecutar comando nmap personalizado

OPCIONES:
  -t NUM                Threads simultáneos (default: 5)
  -iL <archivo>         Leer targets desde archivo
  --exclude <archivo>   Excluir hosts
  --resume              Continuar escaneos previos
  -h, --help            Ayuda completa

EOF
    exit 0
}

escape_slash() {
    echo "$1" | sed 's/\//_/g'
}

is_valid_ip() {
    [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

is_valid_cidr() {
    [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]
}

is_valid_target() {
    is_valid_ip "$1" || is_valid_cidr "$1"
}

check_dependencies() {
    local missing=()
    command -v tmux &>/dev/null || missing+=("tmux")
    command -v nmap &>/dev/null || missing+=("nmap")
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Dependencias faltantes: ${missing[*]}"
        log_error "Instala: sudo apt install ${missing[*]}"
        exit 1
    fi
}

#=============================================================================
# GESTIÓN DE TMUX
#=============================================================================

trap 'handle_interrupt' INT TERM

handle_interrupt() {
    echo ""
    log "Interrupción detectada (Ctrl+C)"
    log "Deteniendo escaneos..."
    tmux kill-session -t "$SESSION" 2>/dev/null
    log "Usa --resume para continuar"
    exit 130
}

create_tmux_session() {
    # Matar sesión previa si existe
    tmux kill-session -t "$SESSION" 2>/dev/null
    
    # Esperar a que se mate
    sleep 1
    
    # Crear nueva sesión
    if ! tmux new-session -d -s "$SESSION" 2>/dev/null; then
        log_error "No se pudo crear sesión tmux"
        exit 1
    fi
}

count_panes() {
    # Si no existe la sesión todavía, consideramos 0 paneles
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo 0
        return
    fi

    # Contar TODOS los paneles en la sesión (no solo los que ejecutan nmap)
    local total_panes
    total_panes=$(tmux list-panes -t "$SESSION" 2>/dev/null | wc -l || echo 0)

    # Restar 1 porque siempre debe quedar el panel base
    local active=$((total_panes - 1))

    # Si es negativo, forzar a 0
    [ "$active" -lt 0 ] && active=0

    echo "$active"
}

wait_for_slot() {
    while true; do
        local active
        active=$(count_panes)

        # active = número de panes de escaneo (no cuenta el base)
        [ "$active" -lt "$MAX_THREADS" ] && break

        # Pausa corta para no saturar CPU ni a tmux
        sleep 0.2
    done
}

run_in_tmux() {
    local cmd=$1
    local is_first=$2
    local label=$3
    
    wait_for_slot
    
    log "Ejecutando: $label"
    
    if [ "$is_first" = true ]; then
        # Primer comando: agregar "; exit" para cerrar el panel al terminar
        tmux send-keys -t "$SESSION:0" "$cmd; exit" C-m
    else
        # Resto de comandos: intentar crear panel con retry si no hay espacio
        local max_retries=100
        local retry=0
        
        while [ $retry -lt $max_retries ]; do
            # Verificar número total de paneles (límite físico = 6)
            local total_panes=$(tmux list-panes -t "$SESSION" 2>/dev/null | wc -l || echo 0)
            
            if [ $total_panes -ge 6 ]; then
                # Esperar a que se libere espacio
                sleep 0.2
                retry=$((retry + 1))
                continue
            fi
            
            # Intentar crear el panel
            if tmux split-window -t "$SESSION:0" "$cmd; exit" 2>/dev/null; then
                tmux select-layout -t "$SESSION:0" tiled 2>/dev/null
                break
            else
                # Falló, reintentar
                sleep 0.2
                retry=$((retry + 1))
            fi
        done
        
        if [ $retry -eq $max_retries ]; then
            log_error "No se pudo crear panel después de $max_retries intentos: $label"
        fi
    fi
    
    sleep 0.1
}

wait_completion() {
    # Esperar a que la sesión se cierre sola
    # Los paneles tienen "; exit" entonces se cierran automáticamente
    # Cuando el último panel se cierra, tmux mata la sesión automáticamente
    while tmux has-session -t "$SESSION" 2>/dev/null; do
        sleep 1
    done
    
    log "Todos los escaneos completados"
}

auto_attach_tmux() {
    # Auto-attach para el usuario (si existe SUDO_USER)
    if [ -n "$SUDO_USER" ]; then
        su - $SUDO_USER -c "tmux split-window -c \"#{pane_current_path}\" \"sudo tmux attach -t $SESSION\"" 2>/dev/null &
    fi
}

#=============================================================================
# EXTRACCIÓN DE PUERTOS
#=============================================================================

extract_ports() {
    local gnmap=$1
    local ip=$2
    
    grep "Host: $ip" "$gnmap" 2>/dev/null | \
        grep '/open/' | \
        grep -oP '\d+(?=/open)' | \
        sort -u | \
        tr '\n' ',' | \
        sed 's/,$//'
}

extract_ips() {
    grep -oP 'Host: \K\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' "$1" 2>/dev/null | \
        sort -u
}

#=============================================================================
# SISTEMA DE RESUME
#=============================================================================

check_previous() {
    local prev=0
    local prefix="ports"
    
    # Cambiar prefijo según el modo
    case "$SCAN_MODE" in
        specific) prefix="specific" ;;
        custom) prefix="custom" ;;
    esac
    
    for target in "${TARGETS[@]}"; do
        local esc=$(escape_slash "$target")
        [ -f "${prefix}_${esc}.gnmap" ] && prev=$((prev + 1))
    done
    
    if [ $prev -gt 0 ]; then
        log "Se encontraron $prev escaneos previos"
        
        if [ "$RESUME_MODE" = false ]; then
            echo "¿Qué hacer?"
            echo "  [r] Resumir (saltar completados)"
            echo "  [o] Sobrescribir"
            echo "  [c] Cancelar"
            read -p "Selección: " choice
            
            case "$choice" in
                r|R) RESUME_MODE=true ;;
                o|O) ;; 
                *) exit 0 ;;
            esac
        fi
    fi
}

filter_completed() {
    [ "$RESUME_MODE" = false ] && return
    
    local filtered=()
    local prefix="ports"
    
    # Cambiar prefijo según el modo
    case "$SCAN_MODE" in
        specific) prefix="specific" ;;
        custom) prefix="custom" ;;
    esac
    
    for target in "${TARGETS[@]}"; do
        local esc=$(escape_slash "$target")
        [ -f "${prefix}_${esc}.gnmap" ] || filtered+=("$target")
    done
    
    TARGETS=("${filtered[@]}")
}

#=============================================================================
# PARSING
#=============================================================================

parse_args() {
    [ $# -eq 0 ] && show_usage
    
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) show_help ;;
            -t)
                [ -z "$2" ] && log_error "-t requiere número" && exit 1
                [[ "$2" =~ ^[0-9]+$ ]] || { log_error "-t debe ser número"; exit 1; }
                [ "$2" -lt 1 ] && log_error "-t debe ser >= 1" && exit 1
                MAX_THREADS=$2
                shift 2
                ;;
            -s)
                SCAN_MODE="specific"
                shift
                ;;
            -c)
                [ -z "$2" ] && log_error "-c requiere comando" && exit 1
                SCAN_MODE="custom"
                CUSTOM_CMD="$2"
                shift 2
                ;;
            -iL)
                [ -z "$2" ] && log_error "-iL requiere archivo" && exit 1
                [ ! -f "$2" ] && log_error "Archivo no encontrado: $2" && exit 1
                while IFS= read -r line; do
                    [[ -z "$line" || "$line" =~ ^# ]] && continue
                    TARGETS+=("$line")
                done < "$2"
                shift 2
                ;;
            --exclude)
                [ -z "$2" ] && log_error "--exclude requiere archivo" && exit 1
                [ ! -f "$2" ] && log_error "Archivo no encontrado: $2" && exit 1
                while IFS= read -r line; do
                    [[ -z "$line" || "$line" =~ ^# ]] && continue
                    EXCLUDE_HOSTS+=("$line")
                done < "$2"
                shift 2
                ;;
            --resume)
                RESUME_MODE=true
                shift
                ;;
            -*)
                log_error "Opción desconocida: $1"
                exit 1
                ;;
            *)
                TARGETS+=("$1")
                shift
                ;;
        esac
    done
    
    [ ${#TARGETS[@]} -eq 0 ] && log_error "Especifica al menos un target" && exit 1
    
    validate_targets
}

validate_targets() {
    local valid=()
    
    for target in "${TARGETS[@]}"; do
        is_valid_target "$target" || { log_error "Target inválido: $target"; exit 1; }
        
        local excluded=false
        for exclude in "${EXCLUDE_HOSTS[@]}"; do
            [ "$target" = "$exclude" ] && excluded=true && break
        done
        
        [ "$excluded" = false ] && valid+=("$target")
    done
    
    TARGETS=("${valid[@]}")
    [ ${#TARGETS[@]} -eq 0 ] && log_error "No hay targets válidos" && exit 1
}

#=============================================================================
# MODOS DE ESCANEO
#=============================================================================

run_specific_mode() {
    log "=== MODO SPECIFIC: Puertos comunes ==="
    
    local vflag="-vvv"
    [ "$MAX_THREADS" -gt 5 ] && vflag=""
    
    # Puertos comunes (agregado 8000 que faltaba)
    local specific_ports="21,22,23,53,80,88,111,135,139,161,389,443,445,1433,1521,3306,3389,5432,5984,5985,8000,8080,8081,8443,8888,27017"
    
    create_tmux_session
    auto_attach_tmux
    
    local first=true
    
    for target in "${TARGETS[@]}"; do
        local esc=$(escape_slash "$target")
        local cmd="nmap -T5 --open -n -Pn -sV $vflag -p$specific_ports -oA specific_${esc} $target"
        
        run_in_tmux "$cmd" "$first" "$target"
        first=false
    done
    
    wait_completion
}

run_custom_mode() {
    log "=== MODO CUSTOM: Comando personalizado ==="
    
    create_tmux_session
    auto_attach_tmux
    
    local first=true
    
    for target in "${TARGETS[@]}"; do
        local esc=$(escape_slash "$target")
        local cmd="$CUSTOM_CMD"
        
        # Detectar si el comando ya tiene IP/CIDR embebida
        local has_embedded_ip=false
        if echo "$cmd" | grep -qP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(/\d{1,2})?'; then
            has_embedded_ip=true
        fi
        
        # Si tiene $IP como variable, reemplazar
        if echo "$cmd" | grep -q '\$IP'; then
            cmd="${cmd//\$IP/$target}"
        # Si NO tiene $IP pero tampoco tiene IP embebida, agregar al final
        elif [ "$has_embedded_ip" = false ]; then
            cmd="$cmd $target"
        fi
        
        # Si el comando no empieza con "nmap", agregarlo
        if ! echo "$cmd" | grep -q '^nmap'; then
            cmd="nmap $cmd"
        fi
        
        # Agregar output si no existe
        if ! echo "$cmd" | grep -q '\-oA'; then
            cmd="$cmd -oA custom_${esc}"
        fi
        
        run_in_tmux "$cmd" "$first" "$target"
        first=false
    done
    
    wait_completion
}

run_phase1() {
    log "=== FASE 1: Descubrimiento de puertos ==="
    
    local vflag="-vvv"
    [ "$MAX_THREADS" -gt 5 ] && vflag=""
    
    create_tmux_session
    auto_attach_tmux
    
    local first=true
    
    for target in "${TARGETS[@]}"; do
        local esc=$(escape_slash "$target")
        local cmd="nmap $vflag -p- -T5 --open -n -Pn -oA ports_${esc} $target"
        run_in_tmux "$cmd" "$first" "$target"
        first=false
    done
    
    wait_completion
}

run_phase2() {
    log "=== FASE 2: Detección de servicios ==="
    
    local vflag="-vvv"
    [ "$MAX_THREADS" -gt 5 ] && vflag=""
    
    create_tmux_session
    auto_attach_tmux
    
    local first=true
    local count=0
    
    # Usar lista completa de targets (no filtrada)
    for target in "${ORIGINAL_TARGETS[@]}"; do
        local esc=$(escape_slash "$target")
        local gnmap="ports_${esc}.gnmap"
        
        if [ ! -f "$gnmap" ]; then
            log "Archivo no encontrado: $gnmap"
            continue
        fi
        
        log "Procesando: $gnmap"
        
        # Extraer IPs del gnmap
        local ips=$(extract_ips "$gnmap")
        if [ -z "$ips" ]; then
            log "No se encontraron IPs en $gnmap"
            continue
        fi
        
        for ip in $ips; do
            local ports=$(extract_ports "$gnmap" "$ip")
            
            if [ -z "$ports" ]; then
                log "No se encontraron puertos abiertos para $ip"
                continue
            fi
            
            log "Puertos encontrados para $ip: $ports"
            
            local esc_ip=$(escape_slash "$ip")
            local cmd="nmap $vflag -sCV -p$ports -n -Pn --open --min-rate 5000 -oA service_${esc_ip} $ip"
            
            run_in_tmux "$cmd" "$first" "$ip"
            first=false
            count=$((count + 1))
        done
    done
    
    if [ $count -eq 0 ]; then
        log "No se encontraron hosts con puertos abiertos"
        tmux kill-session -t "$SESSION" 2>/dev/null
        return
    fi
    
    wait_completion
}

#=============================================================================
# MAIN
#=============================================================================

main() {
    parse_args "$@"
    check_dependencies
    
    # Verificar root
    if [ "$EUID" -ne 0 ]; then
        log "Requiere privilegios root"
        exec sudo "$0" "$@"
    fi
    
    # Guardar targets originales
    ORIGINAL_TARGETS=("${TARGETS[@]}")
    
    # Configuración
    log "Configuración:"
    log "  - Modo: $SCAN_MODE"
    log "  - Sesión tmux: $SESSION"
    log "  - Attach: tmux attach -t $SESSION"
    log "  - Máximo threads simultáneos: $MAX_THREADS"
    log "  - Targets: ${#TARGETS[@]}"
    echo ""
    
    # Resume
    check_previous
    filter_completed
    
    # Ejecutar según el modo
    case "$SCAN_MODE" in
        specific)
            [ ${#TARGETS[@]} -gt 0 ] && run_specific_mode
            ;;
        custom)
            [ ${#TARGETS[@]} -gt 0 ] && run_custom_mode
            ;;
        normal)
            # FASE 1
            [ ${#TARGETS[@]} -gt 0 ] && run_phase1
            
            # FASE 2
            run_phase2
            ;;
    esac
    
    log "=== Escaneo completo ==="
}

main "$@"
