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

    # Mapeo del nombre del paquete del kernel y repositorios especiales
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
            
            msg_info "Configurando llavero y repositorio de CachyOS..."
            
            # Inicializar y poblar el keyring si fuera necesario para evitar rechazos de firmas
            pacman-key --init
            pacman-key --populate archlinux

            # Descargar y firmar localmente la clave oficial de CachyOS
            pacman-key --recv-keys F3B607488DBAF4A4 --keyserver keyserver.ubuntu.com
            pacman-key --lsign-key F3B607488DBAF4A4
            
            if ! grep -q "\[cachyos\]" /etc/pacman.conf; then
                # Insertar el repositorio de CachyOS arriba del todo en pacman.conf
                sed -i '1i [cachyos]\nServer = https://mirror.cachyos.org/repo/\$arch/\$repo\n' /etc/pacman.conf
            fi

            # Sincronizar bases de datos con el nuevo repositorio y claves listas
            pacman -Sy
            ;;
    esac

    # --- AUTODETECCIÓN SEGURA DE MICROCÓDIGO ---
    msg_info "Detectando microcódigo de CPU..."
    local ucode_pkg=""
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        ucode_pkg="intel-ucode"
        msg_success "-> CPU Intel detectada: Se instalará intel-ucode."
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        ucode_pkg="amd-ucode"
        msg_success "-> CPU AMD detectada: Se instalará amd-ucode."
    fi

    # Paquetes esenciales limpios y sin sobrecarga
    local essential_pkgs="base base-devel nano $ucode_pkg $kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog"

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

        local artix_pkgs="base openrc openrc-system eudev $ucode_pkg $kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog nano"
        
        echo ""
        pacman -Sy --config /tmp/pacman-artix.conf --root /mnt --noconfirm $artix_pkgs
    fi

    # 4. Generación del FSTAB
    msg_info "Generando archivo fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab

    msg_success "¡Bootstrap y fstab generados correctamente!"
    sleep 2
}
