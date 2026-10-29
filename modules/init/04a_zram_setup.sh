#!/usr/bin/env bash

# Módulo universal de configuración y persistencia de ZRAM para Systemd y OpenRC
# Compatible y consciente de la presencia de ZFS (ajuste de tamaño inteligente)

configure_zram() {
    echo "==> Configurando ZRAM universal e inteligente..."

    # 1. Cargar el módulo del kernel zram
    if ! modprobe zram; then
        echo "Error: No se pudo cargar el módulo del kernel 'zram'." >&2
        return 1
    fi

    local target_root="/mnt"
    [ ! -d "/mnt" ] && target_root=""

    # 2. Detectar si estamos usando ZFS para ajustar la proporción de ZRAM inteligentemente
    local use_zfs=false
    if [ -d "${target_root}/etc/zfs" ] || [ -f "${target_root}/etc/zfs/zpool.cache" ]; then
        use_zfs=true
    fi

    # 3. Calcular el tamaño de ZRAM
    local mem_total_kb
    mem_total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    local zram_size_mb=0

    if [ "$use_zfs" = true ]; then
        echo "-> Entorno ZFS detectado: Ajustando ZRAM al 25% de la RAM para evitar colisiones con el ARC..."
        zram_size_mb=$(( (mem_total_kb / 4) / 1024 ))
    else
        echo "-> Sistema de archivos estándar detectado: Asignando el 50% de la RAM a ZRAM..."
        zram_size_mb=$(( (mem_total_kb / 2) / 1024 ))
    fi
    
    # Mínimo de 512MB por seguridad
    if [ "$zram_size_mb" -lt 512 ]; then
        zram_size_mb=512
    fi

    echo "-> Asignando ${zram_size_mb}M a zram0 con compresión zstd..."

    # 4. Configurar el dispositivo zram0 en caliente (sesión actual)
    zramctl --find --disksize "${zram_size_mb}M" --algorithm zstd
    mkswap /dev/zram0
    swapon -p 100 /dev/zram0

    # 5. Determinar el sistema de init activo (/tmp/pandamonium_init)
    local init_system="systemd"
    if [ -f /tmp/pandamonium_init ]; then
        init_system=$(cat /tmp/pandamonium_init)
    fi

    # 6. Crear el script ejecutable global que inicializará ZRAM en cada arranque
    cat << 'EOF' > "${target_root}/usr/local/bin/pandamonium-zram.sh"
#!/usr/bin/env bash
modprobe zram

# Recalcular dinámicamente en el arranque si hay ZFS o no
MEM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
if [ -d /etc/zfs ] || [ -f /etc/zfs/zpool.cache ]; then
    SIZE_MB=$(( (MEM_KB / 4) / 1024 ))
else
    SIZE_MB=$(( (MEM_KB / 2) / 1024 ))
fi
[ "$SIZE_MB" -lt 512 ] && SIZE_MB=512

zramctl --find --disksize "${SIZE_MB}M" --algorithm zstd
mkswap /dev/zram0
swapon -p 100 /dev/zram0
EOF
    chmod +x "${target_root}/usr/local/bin/pandamonium-zram.sh"

    # 7. Registrar la persistencia según el Init
    if [ "$init_system" = "openrc" ]; then
        echo "-> Registrando ZRAM como servicio nativo de OpenRC..."
        
        cat << 'EOF' > "${target_root}/etc/init.d/zram"
#!/sbin/openrc-run

description="Activa ZRAM con compresión zstd en el arranque"

depend() {
    after localmount
    before swaps
}

start() {
    ebegin "Iniciando ZRAM"
    /usr/local/bin/pandamonium-zram.sh
    eend $?
}

stop() {
    ebegin "Deteniendo ZRAM"
    swapoff /dev/zram0 2>/dev/null
    modprobe -r zram 2>/dev/null
    eend $?
}
EOF
        chmod +x "${target_root}/etc/init.d/zram"
        
        if [ "$target_root" = "/mnt" ]; then
            arch-chroot /mnt rc-update add zram default
        else
            rc-update add zram default
        fi

    else
        echo "-> Registrando ZRAM como servicio nativo de Systemd..."
        
        cat << 'EOF' > "${target_root}/etc/systemd/system/zram.service"
[Unit]
Description=Activar ZRAM comprimido con zstd
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/pandamonium-zram.sh
RemainAfterExit=yes
ExecStop=/usr/bin/swapoff /dev/zram0

[Install]
WantedBy=multi-user.target
EOF

        if [ "$target_root" = "/mnt" ]; then
            arch-chroot /mnt systemctl enable zram.service
        else
            systemctl enable zram.service
        fi
    fi

    echo "==> ¡ZRAM configurado, equilibrado (ZFS-aware) y persistido con éxito para $init_system!"
}

configure_zram
