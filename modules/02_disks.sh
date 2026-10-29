#!/usr/bin/env bash

source ui/gum_helpers.sh

setup_disks_and_mounts() {
    show_header
    msg_info "Configuración y particionado de Almacenamiento"

    # 1. Detección de discos
    gum spin --spinner dot --title "Buscando unidades de almacenamiento..." -- sleep 2
    local disks=()
    while read -r line; do
        [[ -n "$line" ]] && disks+=("$line")
    done < <(lsblk -dno NAME,SIZE,TYPE | grep disk | awk '{print "/dev/" $1 " (" $2 ")"}')

    if [ ${#disks[@]} -eq 0 ]; then
        msg_error "No se han encontrado unidades de almacenamiento válidas."
        exit 1
    fi

    msg_info "Selecciona la unidad donde deseas instalar el sistema:"
    local selected_disk_raw
    selected_disk_raw=$(gum choose "${disks[@]}")
    local target_disk
    target_disk=$(echo "$selected_disk_raw" | awk '{print $1}')

    msg_info "Has seleccionado la unidad: $target_disk"

    # Elección del Sistema de Archivos para la Raíz (¡Incluyendo ZFS!)
    msg_info "Selecciona el sistema de archivos para la Raíz (/):"
    local fs_root
    fs_root=$(gum choose "ext4" "btrfs" "xfs" "f2fs" "zfs")

    local use_zfs=false
    [ "$fs_root" == "zfs" ] && use_zfs=true

    if ! confirm_action "¿Deseas abrir cfdisk para particionar $target_disk?"; then
        msg_info "Particionado cancelado. Volviendo a intentar..."
        sleep 1
        setup_disks_and_mounts
        return
    fi

    # Lanzar cfdisk interactivo
    clear
    cfdisk "$target_disk"

    # 2. Selección de particiones creadas
    show_header
    msg_info "Asignación de particiones"

    local partitions=()
    while read -r line; do
        [[ -n "$line" ]] && partitions+=("$line")
    done < <(lsblk -no NAME,SIZE,TYPE | grep part | sed 's/[│├└─]//g' | awk 'NF>=2 {print "/dev/" $1 " (" $2 ")"}')

    if [ ${#partitions[@]} -eq 0 ]; then
        msg_error "No se detectaron particiones. ¿Olvidaste guardarlas en cfdisk diciéndole 'yes'?"
        exit 1
    fi

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
        boot_part_raw=$(gum choose "${partitions[@]}")
        boot_part=$(echo "$boot_part_raw" | awk '{print $1}')
    fi

    # Seleccionar partición Raíz (o ZFS pool partition)
    msg_info "Selecciona la partición para la raíz (/):"
    local root_part_raw
    root_part_raw=$(gum choose "${partitions[@]}")
    local root_part
    root_part=$(echo "$root_part_raw" | awk '{print $1}')

    if [ "$is_uefi" = true ] && [ "$root_part" = "$boot_part" ]; then
        msg_error "La partición raíz y la EFI no pueden ser la misma."
        sleep 2
        setup_disks_and_mounts
        return
    fi

    # Control de /home convencional
    local home_part=""
    local fs_home=""
    local use_separate_home=false

    if [ "$use_zfs" = false ]; then
        local remaining_parts=()
        for p in "${partitions[@]}"; do
            local p_dev
            p_dev=$(echo "$p" | awk '{print $1}')
            if [ "$p_dev" != "$root_part" ] && [ "$p_dev" != "$boot_part" ]; then
                remaining_parts+=("$p")
            fi
        done

        if [ ${#remaining_parts[@]} -gt 0 ]; then
            echo ""
            if gum confirm "¿Deseas asignar una partición independiente para /home?"; then
                use_separate_home=true
                msg_info "Selecciona la partición para /home:"
                local home_part_raw
                home_part_raw=$(gum choose "${remaining_parts[@]}")
                home_part=$(echo "$home_part_raw" | awk '{print $1}')

                msg_info "Selecciona el sistema de archivos para /home:"
                fs_home=$(gum choose "ext4" "btrfs" "xfs" "f2fs")
            fi
        fi
    else
        msg_info "ZFS seleccionado: /home se gestionará mediante datasets internos del zpool."
    fi

    # 3. Confirmar formateo
    clear
    show_header
    msg_info "¡ATENCIÓN! Se van a formatear/inicializar las particiones seleccionadas."
    echo " - Raíz (/): $root_part [Formato: $fs_root]"
    [ "$is_uefi" = true ] && echo " - EFI (/boot/EFI): $boot_part [Formato: FAT32]"
    [ "$use_separate_home" = true ] && echo " - Home (/home): $home_part [Formato: $fs_home]"

    if ! confirm_action "¿Estás totalmente seguro de proceder con la operación?"; then
        msg_info "Operación abortada por seguridad."
        exit 0
    fi

    # 4. Formateo y Montajes
    if [ "$is_uefi" = true ]; then
        msg_info "Formateando partición EFI (FAT32)..."
        mkfs.vfat -F32 "$boot_part"
    fi

    if [ "$use_zfs" = true ]; then
        msg_info "Configurando ZFS Pool y Datasets..."
        # Asegurar que las herramientas de zfs estén disponibles
        modprobe zfs 2>/dev/null || true
        
        # Crear zpool temporal en /mnt para la raíz (zroot)
        zpool create -f -o ashift=12 -O normalization=formD \
             -O mountpoint=/ -R /mnt zroot "$root_part"
             
        # Crear dataset para root y home
        zfs create -o mountpoint=none zroot/data
        zfs create -o mountpoint=/home zroot/data/home
        zfs create -o mountpoint=/ zroot/ROOT
        
        msg_success "¡ZFS Pool 'zroot' creado y datasets montados correctamente!"
    else
        msg_info "Formateando partición Raíz ($fs_root)..."
        case "$fs_root" in
            ext4) mkfs.ext4 -F "$root_part" ;;
            btrfs) mkfs.btrfs -f "$root_part" ;;
            xfs) mkfs.xfs -f "$root_part" ;;
            f2fs) mkfs.f2fs -f "$root_part" ;;
        esac

        msg_info "Montando partición raíz en /mnt..."
        mount "$root_part" /mnt
    fi

    # Montaje persistente del EFI para UEFI (las particiones ESP tienen una condición de desmontaje cuando están desde el liveCD)
    if [ "$is_uefi" = true ]; then
        msg_info "Creando directorio /mnt/boot/EFI y montando partición..."
        mkdir -p /mnt/boot/EFI
        mount "$boot_part" /mnt/boot/EFI
    fi

    # Montaje de /home (si está disponible)
    if [ "$use_separate_home" = true ]; then
        msg_info "Formateando partición /home ($fs_home)..."
        case "$fs_home" in
            ext4) mkfs.ext4 -F "$home_part" ;;
            btrfs) mkfs.btrfs -f "$home_part" ;;
            xfs) mkfs.xfs -f "$home_part" ;;
            f2fs) mkfs.f2fs -f "$home_part" ;;
        es]
        mkdir -p /mnt/home
        mount "$home_part" /mnt/home
    fi

    msg_success "¡Particionado, almacenamiento y montajes completados con éxito!"
    sleep 2
}
