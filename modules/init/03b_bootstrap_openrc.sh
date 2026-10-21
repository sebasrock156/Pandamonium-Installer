#!/usr/bin/env bash

source ui/gum_helpers.sh

run_bootstrap_openrc() {
    show_header
    msg_info "Modo Bootstrap: OpenRC (Artix Linux vía Inyección)"

    # 1. Selección de Kernel
    msg_info "Selecciona la variante del Kernel:"
    local kernel_choice
    kernel_choice=$(gum choose "linux (Mainline)" "linux-lts (Soporte extendido)" "linux-zen (Optimizado para Escritorio/Gaming)")

    local kernel_pkg="linux"
    case "$kernel_choice" in
        "linux-lts (Soporte extendido)")
            kernel_pkg="linux-lts"
            ;;
        "linux-zen (Optimizado para Escritorio/Gaming)")
            kernel_pkg="linux-zen"
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

    # 3. Inyección del pacman.conf de Artix
    gum spin --spinner dot --title "Inyectando repositorios de Artix Linux" -- sleep 2

    cat << 'EOF' > /tmp/pacman-artix.conf
[options]
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[system]
Server = https://mirror1.artixlinux.org/repos/$repo/os/$arch
[world]
Server = https://mirror1.artixlinux.org/repos/$repo/os/$arch
[galaxy]
Server = https://mirror1.artixlinux.org/repos/$repo/os/$arch
EOF

    # Paquetes base esenciales para Artix con OpenRC
    local artix_pkgs="base base-devel openrc openrc-system w3m htop fastfetch $ucode_pkg $kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog nano"

    # 4. Instalación directa sobre /mnt con el pacman.conf inyectado
    echo ""
    msg_info "Instalando paquetes base con pacman (Artix Repos) en /mnt..."
    
    mkdir -p /mnt/var/lib/pacman
    
    if pacman -Sy --config /tmp/pacman-artix.conf --root /mnt --dbpath /mnt/var/lib/pacman --cachedir /mnt/var/cache/pacman/pkg $artix_pkgs; then
        # 5. Generación del FSTAB
        msg_info "Generando archivo fstab..."
        genfstab -U /mnt >> /mnt/etc/fstab
        msg_success "¡Bootstrap de OpenRC e inyección de Artix completados con éxito!"
    else
        msg_error "Error al instalar los paquetes de Artix en /mnt."
    fi

    sleep 2
}
