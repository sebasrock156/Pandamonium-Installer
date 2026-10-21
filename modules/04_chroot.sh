#!/usr/bin/env bash

source ui/gum_helpers.sh

run_chroot_config() {
    show_header
    msg_info "Configuración Post-Instalación en Chroot"

    # Determinamos qué comando de chroot usar según la existencia de openrc o systemd
    local chroot_cmd="arch-chroot"
    if [ -d /mnt/etc/openrc ]; then
        chroot_cmd="artix-chroot"
        msg_info "Entorno Artix detectado. Usando artix-chroot..."
    else
        msg_info "Entorno Arch detectado. Usando arch-chroot..."
    fi

    # --- Interacción previa con Gum (fuera del chroot) ---

    # 1. Zona horaria / Región
    show_header
    msg_info "Selección de Región (Zona Horaria)"
    local region
    region=$(gum choose "Europe" "America" "Asia" "Africa" "Australia" "Pacific" "Atlantic")

    # Listar ciudades de la región elegida usando /usr/share/zoneinfo
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
    hostname=$(gum input --placeholder "Introduce el hostname (ej. mi-pc):" --value "arch-pc")

    # 5. Contraseña de Root obligatoria y segura
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

# 3. Hostname y Hosts (Sin comillas en HOSTS para permitir la expansión de \$hostname)
echo "$hostname" > /etc/hostname
cat << HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
HOSTS

EOF

    # Damos permisos y ejecutamos el script base dentro del chroot
    chmod +x /mnt/tmp/configure_system.sh
    $chroot_cmd /mnt /tmp/configure_system.sh
    rm -f /mnt/tmp/configure_system.sh

    # Asignar la contraseña de root de forma segura mediante chpasswd
    echo "root:$root_pass" | $chroot_cmd /mnt chpasswd
    msg_success "Contraseña de root configurada exitosamente."

    # Creación de usuario personalizado de forma interactiva
    show_header
    msg_info "Creación de usuario del sistema"

    local username
    username=$(gum input --placeholder "Introduce tu nombre de usuario (ej. tunombre):")

    if [ -n "$username" ]; then
        $chroot_cmd /mnt useradd -m -G wheel,audio,video -s /bin/bash "$username"
        msg_info "Establece la contraseña para el usuario $username:"
        $chroot_cmd /mnt passwd "$username"

        # Habilitar sudo para el grupo wheel
        $chroot_cmd /mnt sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
        msg_success "Usuario $username creado y configurado con privilegios de sudo."
    fi

    # 5. Selección e Instalación del Bootloader
    show_header
    msg_info "Configuración del Gestor de Arranque (Bootloader)"

    local bootloader_choice
    if [ -d /sys/firmware/efi/efivars ]; then
        bootloader_choice=$(gum choose "GRUB (Universal y flexible)" "systemd-boot (Nativo UEFI, ligero)")
    else
        msg_info "Modo BIOS/Legacy detectado. systemd-boot no está disponible."
        bootloader_choice="GRUB (Universal y flexible)"
        sleep 1
    fi

    case "$bootloader_choice" in
        "GRUB (Universal y flexible)")
            if [ -d /sys/firmware/efi/efivars ]; then
                msg_info "Instalando GRUB para UEFI..."
                $chroot_cmd /mnt pacman -S --noconfirm grub efibootmgr
                $chroot_cmd /mnt grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB
            else
                msg_info "Instalando GRUB para BIOS/Legacy..."
                local target_disk_boot
                target_disk_boot=$(lsblk -dno NAME,TYPE | grep disk | head -n 1 | awk '{print "/dev/" $1}')
                $chroot_cmd /mnt pacman -S --noconfirm grub
                $chroot_cmd /mnt grub-install --target=i386-pc "$target_disk_boot"
            fi
            $chroot_cmd /mnt grub-mkconfig -o /boot/grub/grub.cfg
            ;;

        "systemd-boot (Nativo UEFI, ligero)")
            msg_info "Instalando systemd-boot..."
            $chroot_cmd /mnt bootctl install

            cat << 'EOF' > /mnt/boot/loader/loader.conf
default arch.*
timeout 4
editor 0
EOF

            local root_uuid
            root_uuid=$(findmnt -no UUID /mnt)

            cat << EOF > /mnt/boot/loader/entries/arch.conf
title   Arch Linux (Pandamonium)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rw
EOF
            msg_success "systemd-boot configurado correctamente."
            ;;
    esac
}
