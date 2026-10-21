#!/usr/bin/env bash

source ui/gum_helpers.sh

run_bootstrap() {
    show_header
    msg_info "Configuración de Bootstrap e Inicialización del Sistema"

    # 1. Selección del Sistema de Inicio (Init)
    msg_info "Selecciona el Sistema de Inicio (Init) deseado:"
    local init_choice
    init_choice=$(gum choose "SystemD (Arch Linux Oficial)" "OpenRC (Artix Repos)")

    # 2. Selección de Kernel
    msg_info "Selecciona la versión del Kernel:"
    local kernel_choice
    kernel_choice=$(gum choose "linux (Mainline estándar)" "linux-lts (Long Term Support)" "linux-zen (Optimizado para Desktop/Gaming)" "linux-cachyos (Alto rendimiento x86-64-v3/v4)")

    local kernel_pkg="linux"
    case "$kernel_choice" in
        "linux-lts (Long Term Support)") 
            kernel_pkg="linux-lts" 
            ;;
        "linux-zen (Optimizado para Desktop/Gaming)") 
            kernel_pkg="linux-zen" 
            ;;
        "linux-cachyos (Alto rendimiento x86-64-v3/v4)") 
            kernel_pkg="linux-cachyos" 
            ;;
    esac

    # --- AUTODETECCIÓN DE HARDWARE ---
    msg_info "Analizando el hardware del sistema..."

    # A. Microcódigo de CPU
    local ucode_pkg=""
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        ucode_pkg="intel-ucode"
        msg_success "-> CPU Intel detectada: Se añadirá intel-ucode."
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        ucode_pkg="amd-ucode"
        msg_success "-> CPU AMD detectada: Se añadirá amd-ucode."
    fi

    # B. Detección de GPU (Intel, AMD, Nvidia)
    local gpu_pkgs=""
    if lspci | grep -iE 'vga|3d|display' | grep -qi 'intel'; then
        gpu_pkgs="$gpu_pkgs mesa vulkan-intel libva-intel-driver"
        msg_success "-> GPU Intel detectada."
    fi
    if lspci | grep -iE 'vga|3d|display' | grep -qiE 'amd|ati'; then
        gpu_pkgs="$gpu_pkgs mesa vulkan-radeon"
        msg_success "-> GPU AMD detectada."
    fi
    if lspci | grep -iE 'vga|3d|display' | grep -qi 'nvidia'; then
        # Instalamos drivers propietarios estándar para Nvidia por compatibilidad
        gpu_pkgs="$gpu_pkgs nvidia nvidia-utils nvidia-settings"
        msg_success "-> GPU Nvidia detectada."
    fi

    # C. Red y Conectividad (Intel, Realtek, Qualcomm, Mediatek)
    # linux-firmware ya incluye la base, pero aseguramos utilidades de red esenciales
    local net_pkgs="networkmanager wireless_tools wpa_supplicant dialog"
    msg_success "-> Utilidades de red configuradas."

    # Paquetes esenciales base
    local essential_pkgs="base base-devel nano $ucode_pkg $kernel_pkg linux-firmware $gpu_pkgs $net_pkgs"

    # 3. Ejecución según el Init elegido
    if [[ "$init_choice" == *"SystemD"* ]]; then
        msg_info "Iniciando instalación mediante pacstrap (SystemD)..."
        echo ""
        pacstrap /mnt $essential_pkgs systemd systemd-sysvcompat
    else
        msg_info "Configurando entorno temporal para Artix (OpenRC)..."
        
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

        local artix_pkgs="base openrc openrc-system eudev $ucode_pkg $kernel_pkg linux-firmware $gpu_pkgs nano $net_pkgs"
        
        echo ""
        pacman -Sy --config /tmp/pacman-artix.conf --root /mnt --noconfirm $artix_pkgs
    fi

    # 4. Generación del FSTAB
    msg_info "Generando archivo fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab

    msg_success "¡Bootstrap y fstab generados correctamente con hardware detectado!"
    sleep 2
}
