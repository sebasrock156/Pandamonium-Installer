#!/usr/bin/env bash

source ui/gum_helpers.sh

run_bootstrap_openrc() {
    show_header
    msg_info "Modo Bootstrap: OpenRC (ArchLinux => Artix Linux)"

    # 1. Selección de Kernel
    msg_info "Selecciona la variante del Kernel:"
    local kernel_choice
    kernel_choice=$(gum choose "linux (Mainline)" "linux-rt (Tiempo real)" "linux-zen (Optimizado para Escritorio/Gaming)" "linux-custom (Compilación en base a tu PC)")

    local kernel_pkg="linux"
    local custom_kernel=false
    
    case "$kernel_choice" in
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

    # 3. Inyección del pacman.conf de Artix (SigLevel permisivo para la inyección inicial)
    gum spin --spinner dot --title "Inyectando repositorios de Artix Linux" -- sleep 2

    cat << 'EOF' > /tmp/pacman-artix.conf
[options]
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
SigLevel    = Optional TrustAll
LocalFileSigLevel = Optional

[system]
Server = https://mirror1.artixlinux.org/repos/$repo/os/$arch
[world]
Server = https://mirror1.artixlinux.org/repos/$repo/os/$arch
[galaxy]
Server = https://mirror1.artixlinux.org/repos/$repo/os/$arch
EOF

    # Paquetes base para Artix con OpenRC (si es custom kernel, omitimos el paquete precompilado genérico)
    local base_kernel_pkg="$kernel_pkg"
    if [ "$custom_kernel" = true ]; then
        base_kernel_pkg="" # Se compilará dentro del entorno o chroot
    fi

    # Paquetes base para Artix con OpenRC (usando $base_kernel_pkg)
    local artix_pkgs="base base-devel artix-keyring artix-archlinux-support openrc openrc-system w3m htop fastfetch $ucode_pkg $base_kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog nano"

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
        
        # 5. Generación del FSTAB
        msg_info "Generando archivo fstab..."
        genfstab -U /mnt >> /mnt/etc/fstab
        echo "openrc" > /tmp/pandamonium_init
        
        msg_success "¡Bootstrap de OpenRC e inyección de Artix completados con éxito!"
    else
        msg_error "Error al instalar los paquetes de Artix en /mnt."
    fi

    sleep 2
}
