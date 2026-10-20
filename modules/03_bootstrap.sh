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

    # Mapeo del nombre del paquete del kernel
    local kernel_pkg="linux"
    case "$kernel_choice" in
        "linux-lts (Long Term Support)")
            kernel_pkg="linux-lts"
            ;;
        "linux-zen (Optimizado para Desktop/Gaming)")
            kernel_pkg="linux-zen"
            ;;
        "linux-cachyos (Alto rendimiento x86-64-v3/v4)")
            # Nota: Para cachyos se requeriría su repo, por defecto lo mapeamos o dejamos preparado
            kernel_pkg="linux-cachyos"
            ;;
    esac

    # Paquetes esenciales hardcodeados por defecto
    local essential_pkgs="base base-devel nano dialog wpa_supplicant dhcpcd linux-firmware $kernel_pkg"

    # 3. Ejecución según el Init elegido
    if [[ "$init_choice" == *"SystemD"* ]]; then
        msg_info "Ejecutando pacstrap oficial con SystemD..."

        # Usamos nuestro spinner favorito para una tarea larga
        run_spinner "Instalando paquetes base y kernel..." pacstrap /mnt $essential_pkgs systemd systemd-sysvcompat

    else
        msg_info "Configurando entorno temporal para Artix (OpenRC)..."

        # Inyectamos un pacman.conf temporal apuntando a los mirrors de Artix
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

        local artix_pkgs="base openrc openrc-system eudev $kernel_pkg linux-firmware nano dialog wpa_supplicant dhcpcd"

        run_spinner "Instalando sistema base con Artix (OpenRC)..." pacman -Sy --config /tmp/pacman-artix.conf --root /mnt --noconfirm $artix_pkgs
    fi

    # 4. Generación del FSTAB
    msg_info "Generando archivo fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab

    msg_success "¡Bootstrap y fstab generados correctamente!"
    sleep 2
}
