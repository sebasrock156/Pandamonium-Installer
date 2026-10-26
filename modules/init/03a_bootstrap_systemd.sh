#!/usr/bin/env bash

source ui/gum_helpers.sh

run_bootstrap_systemd() {
    show_header
    msg_info "Modo Bootstrap: Systemd (Arch Linux)"

    # 1. Selección de Kernel
    msg_info "Selecciona la variante del Kernel:"
    local kernel_choice
    kernel_choice=$(gum choose "linux (Mainline)" "linux-lts (Soporte extendido)" "linux-rt (Tiempo real)" "linux-zen (Optimizado para Escritorio/Gaming)" "linux-custom (Compilación en base a tu PC)")

    local kernel_pkg="linux"
    local custom_kernel=false
    
    case "$kernel_choice" in
        "linux-lts (Soporte extendido)")
            kernel_pkg="linux-lts"
            ;;
        "linux-rt (Tiempo Real)")
            kernel_pkg="linux-rt"
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

    # 3. Paquetes esenciales para Systemd
    local essential_pkgs="base base-devel nano htop fastfetch w3m $ucode_pkg $base_kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog systemd systemd-sysvcompat"

    # 4. Instalación vía pacstrap
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

        # 5. Generación del FSTAB
        msg_info "Generando archivo fstab..."
        genfstab -U /mnt >> /mnt/etc/fstab
        echo "systemd" > /tmp/pandamonium_init
        msg_success "¡Bootstrap (Systemd) y fstab generados correctamente!"
    else
        msg_error "Error al ejecutar pacstrap."
    fi

    sleep 2
}
