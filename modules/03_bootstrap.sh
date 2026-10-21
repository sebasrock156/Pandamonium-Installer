#!/usr/bin/env bash

source ui/gum_helpers.sh

run_bootstrap() {
    show_header
    msg_info "Configuración de Bootstrap e Inicialización del Sistema"

    # Selección de Init
    msg_info "Selecciona el Sistema de Inicio (Init) deseado:"
    local init_choice
    init_choice=$(gum choose "Systemd (ArchLinux Repos)" "OpenRC (Artix Repos)")

    # 2. Selección de Kernel
    msg_info "Selecciona la variante del Kernel:"
    local kernel_choice
    kernel_choice=$(gum choose "linux (Mainline)" "linux-lts (Soporte extendido)" "linux-zen (Optimizado para Escritorio/Gaming)")

    # Mapeo del nombre del paquete del kernel
    local kernel_pkg="linux"

    case "$kernel_choice" in
        "linux-lts (Soporte extendido)") 
            kernel_pkg="linux-lts" 
            ;;
        "linux-zen (Optimizado para Escritorio/Gaming)") 
            kernel_pkg="linux-zen" 
            ;;
    esac

    # --- AUTODETECCIÓN SEGURA DE MICROCÓDIGO ---
    gum spin --spinner dot --title "Detectando el microcódigo/AGESA del procesador" -- sleep 3
    local ucode_pkg=""
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        ucode_pkg="intel-ucode"
        msg_success "-> Procesador de Intel detectado: Se instalará intel-ucode."
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        ucode_pkg="amd-ucode"
        msg_success "-> Procesador de AMD detectado: Se instalará amd-ucode."
    fi

    # Paquetes esenciales
    local essential_pkgs="base base-devel nano htop fastfetch w3m $ucode_pkg $kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog"

    # 3. Ejecución según el Init elegido
    if [[ "$init_choice" == *"SystemD"* ]]; then
        msg_info "Iniciando instalación mediante pacstrap (Systemd)..."
        echo ""
        pacstrap /mnt $essential_pkgs systemd systemd-sysvcompat
    else
        gum spin --spinner dot --title "Configurando entorno para OpenRC" -- sleep 3
        
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

        local artix_pkgs="base openrc openrc-system eudev w3m htop fastfetch $ucode_pkg $kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog nano"
        
        echo ""
        pacman -Sy --config /tmp/pacman-artix.conf --root /mnt --noconfirm $artix_pkgs
    fi

    # 4. Generación del FSTAB
    msg_info "Generando archivo fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab

    msg_success "¡Bootstrap y fstab generados correctamente!"
    sleep 2
}
