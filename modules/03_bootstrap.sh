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
    gum spin --spinner dot --title "Detectando el microcódigo/AGESA del procesador" -- sleep 1
    local ucode_pkg=""
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        ucode_pkg="intel-ucode"
        msg_success "Procesador Intel detectado: Se instalará intel-ucode."
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        ucode_pkg="amd-ucode"
        msg_success "Procesador AMD detectado: Se instalará amd-ucode."
    fi

    # Asegurar el llavero de pacman en el Live para evitar errores de ALPM
    msg_info "Inicializando claves de pacman en el entorno de instalación..."
    pacman-key --init >/dev/null 2>&1
    pacman-key --populate archlinux >/dev/null 2>&1

    # Crear la estructura de directorios necesaria para alpm en /mnt
    mkdir -p /mnt/var/lib/pacman /mnt/etc

    # 3. Ejecución según el Init elegido
    if [[ "$init_choice" == *"SystemD"* ]]; then
        local essential_pkgs="base base-devel nano htop fastfetch w3m $ucode_pkg $kernel_pkg linux-firmware networkmanager wireless_tools wpa_supplicant dialog systemd systemd-sysvcompat"
        
        msg_info "Iniciando instalación mediante pacstrap (Systemd)..."
        echo ""
        pacstrap /mnt $essential_pkgs
    else
        gum spin --spinner dot --title "Configurando repositorios para OpenRC" -- sleep 1
        
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
        
        msg_info "Iniciando instalación mediante pacstrap (OpenRC)..."
        echo ""
        # Usamos pacstrap con el parámetro -C para leer los repositorios de Artix correctamente
        pacstrap -C /tmp/pacman-artix.conf /mnt $artix_pkgs
    fi

    # Comprobar si el bootstrap se completó antes de generar el fstab
    if [ $? -eq 0 ] && [ -d "/mnt/etc" ]; then
        # 4. Generación del FSTAB
        msg_info "Generando archivo fstab..."
        genfstab -U /mnt >> /mnt/etc/fstab
        msg_success "¡Bootstrap y fstab generados correctamente!"
    else
        msg_error "Error crítico durante el bootstrap de paquetes."
        return 1
    fi

    sleep 2
}
