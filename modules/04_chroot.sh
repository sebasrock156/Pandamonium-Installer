#!/usr/bin/env bash

source ui/gum_helpers.sh

run_chroot_config() {
    show_header
    msg_info "Configuración Post-Instalación en Chroot"

    # Determinamos el gestor de init leyendo el archivo de estado compartido
    local init_system="systemd"
    if [ -f /tmp/pandamonium_init ]; then
        init_system=$(cat /tmp/pandamonium_init)
    fi

    # Detectar si estamos usando ZFS
    local use_zfs=false
    if [ -d /mnt/etc/zfs ] || [ -f /mnt/etc/zfs/zpool.cache ]; then
        use_zfs=true
    fi

    # Usamos arch-chroot universalmente
    local chroot_cmd="arch-chroot"

    # --- Interacción previa con Gum (fuera del chroot) ---

    # 1. Zona horaria / Región
    show_header
    msg_info "Selección de Región (Zona Horaria)"
    local region
    region=$(gum choose "Europe" "America" "Asia" "Africa" "Australia" "Pacific" "Atlantic")

    local cities
    cities=$(find "/usr/share/zoneinfo/$region" -maxdepth 2 -type f | sed "s|/usr/share/zoneinfo/$region/||" | sort)

    msg_info "Selecciona la ciudad / zona horaria:"
    local city
    city=$(echo "$cities" | gum filter --placeholder "Filtra o busca tu ciudad...")
    local timezone="$region/$city"

    # 2. Idioma / Locale
    show_header
    msg_info "Selección de Idioma del Sistema (Locale)"
    local selected_locale
    selected_locale=$(gum choose "es_ES.UTF-8" "en_US.UTF-8" "es_MX.UTF-8" "es_AR.UTF-8" "pt_BR.UTF-8" "fr_FR.UTF-8" "de_DE.UTF-8")

    # 3. Distribución del teclado (Keymap)
    msg_info "Selección de Distribución del Teclado"
    local selected_keymap
    selected_keymap=$(gum choose "es" "us" "latam" "fr" "de" "it" "pt-latin1")

    # 4. Hostname
    show_header
    msg_info "Nombre del equipo (Hostname)"
    local hostname
    hostname=$(gum input --placeholder "Introduce el hostname (ej. mi-pc):" --value "pandamonium-pc")

    # 5. Contraseña de Root obligatoria y segura con máscara de Gum
    show_header
    msg_info "Establece la contraseña de administrador (root):"
    local root_pass=""
    while true; do
        root_pass=$(gum input --password --prompt "Contraseña de root: ")
        local root_pass_confirm
        root_pass_confirm=$(gum input --password --prompt "Confirma la contraseña: ")

        if [ "$root_pass" = "$root_pass_confirm" ] && [ -n "$root_pass" ]; then
            msg_success "¡Contraseña de root validada!"
            break
        else
            msg_error "Las contraseñas no coinciden o están vacías. Inténtalo de nuevo."
        fi
    done

    # --- Generación del script interno con las variables capturadas ---
    cat << EOF > /mnt/tmp/configure_system.sh
#!/usr/bin/env bash

# 1. Zona horaria
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

# 2. Localización e Idiomas
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "$selected_locale UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$selected_locale" > /etc/locale.conf
echo "KEYMAP=$selected_keymap" > /etc/vconsole.conf

# 3. Hostname y Hosts
echo "$hostname" > /etc/hostname
echo "127.0.0.1   localhost" > /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   $hostname.localdomain   $hostname" >> /etc/hosts

EOF

    chmod +x /mnt/tmp/configure_system.sh
    $chroot_cmd /mnt /tmp/configure_system.sh
    rm -f /mnt/tmp/configure_system.sh

    # Asignar la contraseña de root de forma segura
    echo "root:$root_pass" | $chroot_cmd /mnt chpasswd
    msg_success "Contraseña de root configurada exitosamente."

    # Creación de usuario personalizado con contraseña enmascarada (Gum)
    show_header
    msg_info "Creación de usuario del sistema"

    local username
    username=$(gum input --placeholder "Introduce tu nombre de usuario (ej. tunombre):")

    if [ -n "$username" ]; then
        $chroot_cmd /mnt useradd -m -G wheel,audio,video -s /bin/bash "$username"
        
        show_header
        msg_info "Establece la contraseña para el usuario $username:"
        local user_pass=""
        while true; do
            user_pass=$(gum input --password --prompt "Contraseña de $username: ")
            local user_pass_confirm
            user_pass_confirm=$(gum input --password --prompt "Confirma la contraseña: ")

            if [ "$user_pass" = "$user_pass_confirm" ] && [ -n "$user_pass" ]; then
                msg_success "¡Contraseña de usuario validada!"
                break
            else
                msg_error "Las contraseñas no coinciden o están vacías. Inténtalo de nuevo."
            fi
        done

        # Asignar la contraseña de forma segura con chpasswd
        echo "$username:$user_pass" | $chroot_cmd /mnt chpasswd

        # Habilitar sudo para el grupo wheel
        $chroot_cmd /mnt sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
        msg_success "Usuario $username creado y configurado con privilegios de sudo."
    fi

    # --- CONFIGURACIÓN ESPECÍFICA DE ZFS (Mkinitcpio hooks) ---
    if [ "$use_zfs" = true ]; then
        msg_info "Configurando hooks de ZFS en mkinitcpio.conf..."
        $chroot_cmd /mnt sed -i 's/HOOKS=(base udev/HOOKS=(base udev zfs/' /etc/mkinitcpio.conf
        $chroot_cmd /mnt mkinitcpio -P
    fi

    # 5. Selección e Instalación del Bootloader
    show_header
    msg_info "Configuración del Gestor de Arranque (Bootloader)"

    local bootloader_choice
    if [ -d /sys/firmware/efi/efivars ]; then
        if [ "$init_system" = "openrc" ]; then
            msg_info "Entorno OpenRC detectado: Forzando GRUB (compatible con OpenRC y ZFS)."
            bootloader_choice="GRUB (Universal y flexible)"
        else
            if [ "$use_zfs" = true ]; then
                msg_info "Entorno ZFS detectado: Se recomienda GRUB por su compatibilidad robusta con zpools."
            fi
            bootloader_choice=$(gum choose "GRUB (Universal y flexible)" "systemd-boot (Nativo UEFI, ligero)")
        fi
    else
        msg_info "Modo BIOS/Legacy detectado. systemd-boot no está disponible."
        bootloader_choice="GRUB (Universal y flexible)"
        sleep 1
    fi

    case "$bootloader_choice" in
        "GRUB (Universal y flexible)")
            if [ -d /sys/firmware/efi/efivars ]; then
                msg_info "Instalando GRUB para UEFI..."
                if [ "$use_zfs" = true ]; then
                    $chroot_cmd /mnt pacman -S --noconfirm grub efibootmgr zfs-utils
                else
                    $chroot_cmd /mnt pacman -S --noconfirm grub efibootmgr
                fi
                $chroot_cmd /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
            else
                msg_info "Instalando GRUB para BIOS/Legacy..."
                local target_disk_boot
                target_disk_boot=$(lsblk -dno NAME,TYPE | grep disk | head -n 1 | awk '{print "/dev/" $1}')
                $chroot_cmd /mnt pacman -S --noconfirm grub
                $chroot_cmd /mnt grub-install --target=i386-pc "$target_disk_boot"
            fi

            if [ "$use_zfs" = true ]; then
                sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="zfs=zroot/ROOT/default /' /mnt/etc/default/grub 2>/dev/null || true
            fi

            $chroot_cmd /mnt grub-mkconfig -o /boot/grub/grub.cfg
            msg_success "GRUB configurado e instalado correctamente."
            ;;

        "systemd-boot (Nativo UEFI, ligero)")
            msg_info "Instalando systemd-boot..."
            $chroot_cmd /mnt bootctl install

            cat << 'EOF' > /mnt/boot/loader/loader.conf
default arch.*
timeout 4
editor 0
EOF

            if [ "$use_zfs" = true ]; then
                cat << 'EOF' > /mnt/boot/loader/entries/arch.conf
title   Arch Linux (Pandamonium ZFS)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options zfs=zroot/ROOT/default rw
EOF
            else
                local root_uuid
                root_uuid=$(findmnt -no UUID /mnt)

                cat << EOF > /mnt/boot/loader/entries/arch.conf
title   Arch Linux (Pandamonium)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rw
EOF
            fi
            msg_success "systemd-boot configurado correctamente."
            ;;
    esac
}
