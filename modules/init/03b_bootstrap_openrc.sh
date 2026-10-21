#!/usr/bin/env bash

source ui/gum_helpers.sh

run_bootstrap_openrc() {
    show_header
    msg_info "Modo Bootstrap: OpenRC (Artix Linux Repos)"

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

    # 3. Configuración de repositorios para Artix Linux
    gum spin --spinner dot --title "Configurando entorno para OpenRC" -- sleep 2

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

    # Paquetes esenciales para OpenRC
    local artix_pkgs="base base-devel openrc openrc-system eudev w3m htop fastfetch $ucode_pkg $kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog nano"

    # 4. Instalación vía pacman directo sobre /mnt
    echo ""
    msg_info "Iniciando pacman con repositorio Artix en /mnt..."
    if pacman -Sy --config /tmp/pacman-artix.conf --root /mnt --noconfirm $artix_pkgs; then
        # 5. Generación del FSTAB
        msg_info "Generando archivo fstab..."
        genfstab -U /mnt >> /mnt/etc/fstab
        msg_success "¡Bootstrap (OpenRC) y fstab generados correctamente!"
    else
        msg_error "Error al instalar paquetes base de Artix/OpenRC."
    fi

    sleep 2
}
