#!/usr/bin/env bash

source ui/gum_helpers.sh

run_bootstrap_openrc() {
    show_header
    msg_info "Modo Bootstrap: OpenRC (Artix Linux Repos Oficiales)"

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

    # Paquetes esenciales para Artix con OpenRC (evitamos nombrar demonios deprecados o fantasmas)
    local artix_pkgs="base base-devel openrc openrc-system w3m htop fastfetch $ucode_pkg $kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog nano"

    # 3. Instalación vía basestrap de Artix
    echo ""
    msg_info "Ejecutando basestrap de Artix en /mnt..."
    if basestrap /mnt $artix_pkgs; then
        # 4. Generación del FSTAB con fstabgen
        msg_info "Generando archivo fstab..."
        fstabgen -U /mnt >> /mnt/etc/fstab
        msg_success "¡Bootstrap (OpenRC) y fstab generados correctamente con herramientas nativas!"
    else
        msg_error "Error al ejecutar basestrap con los repositorios de Artix."
    fi

    sleep 2
}
