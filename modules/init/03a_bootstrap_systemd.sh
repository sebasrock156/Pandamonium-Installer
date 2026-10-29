#!/usr/bin/env bash

source ui/gum_helpers.sh

run_bootstrap_systemd() {
    show_header
    msg_info "Modo Bootstrap: Systemd (Arch Linux)"

    # Detectar si el usuario seleccionó ZFS en el paso de discos anterior
    local use_zfs=false
    if zpool list zroot &>/dev/null || grep -q "zfs" /proc/filesystems || [ -d "/mnt/.zfs" ]; then
        use_zfs=true
    fi

    # 1. Selección de Kernel
    msg_info "Selecciona la variante del Kernel:"
    local kernel_choice
    kernel_choice=$(gum choose "linux (Mainline)" "linux-lts (Soporte extendido)" "linux-rt (Tiempo real)" "linux-hardened (Seguridad robusta)" "linux-zen (Optimizado para Escritorio/Gaming)" "linux-custom (Compilación en base a tu PC)")

    local kernel_pkg="linux"
    local custom_kernel=false
    
    case "$kernel_choice" in
        "linux-lts (Soporte extendido)")
            kernel_pkg="linux-lts"
            ;;
        "linux-rt (Tiempo Real)")
            kernel_pkg="linux-rt"
            ;;
        "linux-hardened (Seguridad robusta)"
            kernel_pkg="linux-hardened"
            ;;
        "linux-zen (Optimizado para Escritorio/Gaming)")
            kernel_pkg="linux-zen"
            ;;
        "linux-custom (Compilación en base a tu PC)")
            custom_kernel=true
            ;;
    esac

    # 2. Autodetección de Microcódigo
    gum spin --spinner dot --title "Detectando el microcódigo/AGESA del procesador" -- sleep 2
    local ucode_pkg=""
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        ucode_pkg="intel-ucode"
        msg_success "-> Procesador Intel detectado: Se instalará intel-ucode."
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        ucode_pkg="amd-ucode"
        msg_success "-> Procesador AMD detectado: Se instalará amd-ucode."
    fi

    # Manejo del paquete base si se selecciona compilación personalizada
    local base_kernel_pkg="$kernel_pkg"
    if [ "$custom_kernel" = true ]; then
        base_kernel_pkg=""
    fi

    # 3. Paquetes esenciales para Systemd (ZFS solo si se requiere)
    local zfs_pkgs=""
    if [ "$use_zfs" = true ]; then
        if [ "$custom_kernel" = false ]; then
            zfs_pkgs="zfs-utils zfs-$kernel_pkg"
        else
            zfs_pkgs="zfs-utils zfs-dkms dkms"
        fi
    fi

    local essential_pkgs="base base-devel nano htop fastfetch w3m $ucode_pkg $base_kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog systemd systemd-sysvcompat $zfs_pkgs"

    # 4. Configurar repositorio ArchZFS ÚNICAMENTE si se usa ZFS
    if [ "$use_zfs" = true ]; then
        msg_info "Configurando repositorio ArchZFS para la instalación..."
        pacman-key --recv-key F757749674FA9DAC --keyserver keyserver.ubuntu.com || true
        pacman-key --lsign-key F757749674FA9DAC || true
        
        local pacman_conf="/etc/pacman.conf"
        if ! grep -q "\[archzfs\]" "$pacman_conf"; then
            cat << 'EOF' >> "$pacman_conf"

[archzfs]
Server = https://archzfs.com/$repo/$arch
Server = https://mirror.sum7.eu/archlinux/archzfs/$repo/$arch
Server = https://zxcv.icu/archzfs/$repo/$arch
EOF
            pacman -Sy
        fi
    fi

    # 5. Instalación vía pacstrap
    msg_info "Iniciando instalación mediante pacstrap (Systemd)..."
    echo ""
    if pacstrap /mnt $essential_pkgs; then

        # Si se seleccionó kernel personalizado, preparar entorno de compilación
        if [ "$custom_kernel" = true ]; then
            msg_info "Preparando entorno para la compilación del Kernel personalizado..."
            
            cat << 'EOF' > /mnt/tmp/build_kernel.sh
#!/usr/bin/env bash
echo "Iniciando configuración y compilación del kernel personalizado a medida..."

# Dependencias de compilación
pacman -S --noconfirm git bc cpio perl libelf pahole kmod make gcc bison flex
# Clonar o configurar fuentes del kernel para compilar con make menuconfig
EOF
            chmod +x /mnt/tmp/build_kernel.sh
            arch-chroot /mnt /tmp/build_kernel.sh
        fi

        # 6. Generación del FSTAB o Caché/Servicios ZFS
        if [ "$use_zfs" = true ]; then
            msg_info "Generando zpool.cache y configurando servicios ZFS..."
            mkdir -p /mnt/etc/zfs
            zpool export zroot 2>/dev/null || true
            zpool import -d /dev/disk/by-id -R /mnt zroot
            cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache 2>/dev/null || zpool set cachefile=/etc/zfs/zpool.cache zroot
            
            arch-chroot /mnt systemctl enable zfs.target zfs-import-scan.service zfs-mount.service zfs-share.service
        else
            msg_info "Generando archivo fstab..."
            genfstab -U /mnt >> /mnt/etc/fstab
        fi

        echo "systemd" > /tmp/pandamonium_init
        msg_success "¡Bootstrap (Systemd) y almacenamiento configurados correctamente!"
    else
        msg_error "Error al ejecutar pacstrap."
    fi

    sleep 2
}
