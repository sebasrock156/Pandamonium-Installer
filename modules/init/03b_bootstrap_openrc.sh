#!/usr/bin/env bash

source ui/gum_helpers.sh

run_bootstrap_openrc() {
    show_header
    msg_info "Modo Bootstrap: OpenRC (ArchLinux => Artix Linux)"

    # Detectar si el usuario seleccionó ZFS en el paso de discos anterior
    local use_zfs=false
    if zpool list zroot &>/dev/null || grep -q "zfs" /proc/filesystems || [ -d "/mnt/.zfs" ]; then
        use_zfs=true
    fi

    # 1. Selección de Kernel
    msg_info "Selecciona la variante del Kernel:"
    local kernel_choice
    kernel_choice=$(gum choose "linux (Mainline)" "linux-rt (Tiempo real)" "linux-zen (Para gaming)" "linux-custom (Compilación propia)")

    local kernel_pkg="linux"
    local custom_kernel=false
    
    case "$kernel_choice" in
        "linux-rt (Tiempo real)")
            kernel_pkg="linux-rt"
            ;;
        "linux-zen (Para gaming)")
            kernel_pkg="linux-zen"
            ;;
        "linux-custom (Compilación propia)")
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

    # 3. Inyección del pacman.conf de Artix (Añadiendo ArchZFS si procede)
    gum spin --spinner dot --title "Inyectando repositorios de Artix Linux" -- sleep 2

    local archzfs_repo_block=""
    if [ "$use_zfs" = true ]; then
        archzfs_repo_block="
[archzfs]
Server = https://archzfs.com/\$repo/\$arch
Server = https://mirror.sum7.eu/archlinux/archzfs/\$repo/\$arch
Server = https://zxcv.icu/archzfs/\$repo/\$arch
"
    fi

    cat << EOF > /tmp/pacman-artix.conf
[options]
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
SigLevel    = Optional TrustAll
LocalFileSigLevel = Optional

[system]
Server = https://mirror1.artixlinux.org/repos/\$repo/os/\$arch
[world]
Server = https://mirror1.artixlinux.org/repos/\$repo/os/\$arch
[galaxy]
Server = https://mirror1.artixlinux.org/repos/\$repo/os/\$arch
$archzfs_repo_block
EOF

    # Configuración de paquetes ZFS condicionales para OpenRC
    local zfs_pkgs=""
    if [ "$use_zfs" = true ]; then
        if [ "$custom_kernel" = false ]; then
            zfs_pkgs="zfs-utils zfs-openrc zfs-$kernel_pkg"
        else
            zfs_pkgs="zfs-utils zfs-openrc zfs-dkms dkms"
        fi
    fi

    # Paquetes base para Artix con OpenRC
    local base_kernel_pkg="$kernel_pkg"
    if [ "$custom_kernel" = true ]; then
        base_kernel_pkg="" # Se compilará dentro del entorno o chroot
    fi

    local artix_pkgs="base base-devel artix-keyring artix-archlinux-support openrc openrc-system w3m htop fastfetch $ucode_pkg $base_kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog nano $zfs_pkgs"

    # Configurar claves de ArchZFS en el host temporal si se usa ZFS
    if [ "$use_zfs" = true ]; then
        msg_info "Configurando llaves del repositorio ArchZFS..."
        pacman-key --recv-key F757749674FA9DAC --keyserver keyserver.ubuntu.com || true
        pacman-key --lsign-key F757749674FA9DAC || true
    fi

    # 4. Instalación directa sobre /mnt
    echo ""
    msg_info "Instalando paquetes base con pacman (Artix Repos) en /mnt..."
    
    mkdir -p /mnt/var/lib/pacman
    mkdir -p /mnt/var/cache/pacman/pkg
    
    if pacman -Sy --config /tmp/pacman-artix.conf --root /mnt --dbpath /mnt/var/lib/pacman --cachedir /mnt/var/cache/pacman/pkg $artix_pkgs; then

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
        
        # 5. Generación del FSTAB o servicios ZFS con OpenRC
        if [ "$use_zfs" = true ]; then
            msg_info "Generando zpool.cache y configurando servicios OpenRC para ZFS..."
            mkdir -p /mnt/etc/zfs
            zpool export zroot 2>/dev/null || true
            zpool import -d /dev/disk/by-id -R /mnt zroot
            cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache 2>/dev/null || zpool set cachefile=/etc/zfs/zpool.cache zroot
            
            # Habilitar servicios ZFS nativos en OpenRC
            arch-chroot /mnt rc-update add zfs-import boot
            arch-chroot /mnt rc-update add zfs-mount boot
        else
            msg_info "Generando archivo fstab..."
            genfstab -U /mnt >> /mnt/etc/fstab
        fi

        echo "openrc" > /tmp/pandamonium_init
        
        msg_success "¡Bootstrap de OpenRC y almacenamiento configurados con éxito!"
    else
        msg_error "Error al instalar los paquetes de Artix en /mnt."
    fi

    sleep 2
}
