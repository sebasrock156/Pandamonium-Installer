#!/usr/bin/env bash

source ui/gum_helpers.sh

setup_disks_and_mounts() {
    show_header
    msg_info "Configuración de Discos y Particionado"

    # 1. Detectar discos disponibles de forma limpia (excluyendo loops, rom, etc.)
    local disks
    disks=$(lsblk -dno NAME,SIZE,TYPE | grep disk | awk '{print "/dev/" $1 " (" $2 ")"}')

    if [ -z "$disks" ]; then
        msg_error "No se han encontrado discos de almacenamiento válidos."
        exit 1
    fi

    msg_info "Selecciona el disco donde deseas instalar Arch Linux:"
    local selected_disk_raw
    selected_disk_raw=$(gum choose $disks)

    # Extraer solo la ruta limpia (ej. /dev/sda o /dev/nvme0n1)
    local target_disk
    target_disk=$(echo "$selected_disk_raw" | awk '{print $1}')

    msg_info "Has seleccionado el disco: $target_disk"

    if ! confirm_action "¿Deseas abrir cfdisk para particionar $target_disk?"; then
        msg_info "Particionado cancelado. Volviendo a intentar..."
        sleep 1
        setup_disks_and_mounts
        return
    fi

    # Lanzar cfdisk interactivo
    clear
    cfdisk "$target_disk"

    # 2. Seleccionar particiones creadas
    show_header
    msg_info "Ahora vamos a asignar las particiones creadas."

    # Listar particiones disponibles del sistema
    local partitions
    partitions=$(lsblk -no NAME,SIZE,TYPE | grep part | awk '{print "/dev/" $1 " (" $2 ")"}')

    if [ -z "$partitions" ]; then
        msg_error "No se detectaron particiones. ¿Olvidaste guardarlas en cfdisk?"
        exit 1
    fi

    # Seleccionar partición Raíz (/)
    msg_info "Selecciona la partición para la raíz (/):"
    local root_part_raw
    root_part_raw=$(gum choose $partitions)
    local root_part
    root_part=$(echo "$root_part_raw" | awk '{print $1}')

    # Comprobación de modo UEFI / BIOS
    local is_uefi=false
    if [ -d /sys/firmware/efi/efivars ]; then
        is_uefi=true
        msg_success "Sistema arrancado en modo UEFI detectado."
    else
        msg_info "Sistema arrancado en modo BIOS/Legacy detectado."
    fi

    local boot_part=""
    if [ "$is_uefi" = true ]; then
        msg_info "Selecciona la partición EFI (ESP):"
        local boot_part_raw
        boot_part_raw=$(gum choose $partitions)
        boot_part=$(echo "$boot_part_raw" | awk '{print $1}')

        if [ "$root_part" = "$boot_part" ]; then
            msg_error "La partición raíz y la EFI no pueden ser la misma."
            sleep 2
            setup_disks_and_mounts
            return
        fi
    fi

    # 3. Confirmar formateo
    clear
    show_header
    msg_error "¡ATENCIÓN! Se van a formatear las particiones seleccionadas."
    echo " - Raíz (/): $root_part (Se formateará a ext4)"
    [ "$is_uefi" = true ] && echo " - EFI (/boot/EFI): $boot_part (Se formateará a FAT32)"

    if ! confirm_action "¿Estás totalmente seguro de proceder con el formateo y montaje?"; then
        msg_info "Operación abortada por seguridad."
        exit 0
    fi

    # 4. Formateo y Montajes
    msg_info "Formateando partición Raíz..."
    mkfs.ext4 -F "$root_part"

    if [ "$is_uefi" = true ]; then
        msg_info "Formateando partición EFI..."
        mkfs.vfat -F32 "$boot_part"
    fi

    # Montaje de la Raíz
    msg_info "Montando partición raíz en /mnt..."
    mount "$root_part" /mnt

    # Montaje estricto de EFI para UEFI
    if [ "$is_uefi" = true ]; then
        msg_info "Creando directorio /mnt/boot/EFI y montando partición..."
        mkdir -p /mnt/boot/EFI
        mount "$boot_part" /mnt/boot/EFI
    fi

    msg_success "¡Particionado, formateo y montajes completados con éxito!"
    sleep 2
}
