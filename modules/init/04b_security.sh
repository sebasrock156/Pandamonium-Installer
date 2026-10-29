#!/usr/bin/env bash

source ui/gum_helpers.sh

run_security_config() {
    show_header
    msg_info "Configuración de Seguridad del Sistema (Control de Acceso Obligatorio - MAC)"

    # Limpiamos cualquier rastro de ejecuciones previas del instalador
    rm -f /tmp/pandamonium_security /tmp/pandamonium_lsm_param

    local security_choice
    security_choice=$(gum choose \
        "Ninguna (Desactivado / Sistema Vanilla)" \
        "AppArmor (Recomendado - Flexible y nativo en Arch)" \
        "SELinux (Avanzado - Requiere configuración manual post-install)")

    case "$security_choice" in
        "AppArmor (Recomendado - Flexible y nativo en Arch)")
            msg_info "Configurando AppArmor..."
            
            # Guardamos el estado para el Bootloader
            echo "apparmor" > /tmp/pandamonium_security
            echo "lsm=landlock,lockdown,yama,apparmor,bpf" > /tmp/pandamonium_lsm_param

            # Instalamos paquetes requeridos dentro del target /mnt
            msg_info "Instalando apparmor y perfiles base..."
            arch-chroot /mnt pacman -S --noconfirm --needed apparmor apparmor-profiles

            # Habilitar servicio según el Init detectado previamente en /tmp/pandamonium_init
            local init_type=""
            [ -f /tmp/pandamonium_init ] && init_type=$(cat /tmp/pandamonium_init)

            if [ "$init_type" = "systemd" ]; then
                arch-chroot /mnt systemctl enable apparmor.service
            elif [ "$init_type" = "openrc" ]; then
                arch-chroot /mnt rc-update add apparmor default
            fi

            msg_success "AppArmor activado y preparado para el primer arranque."
            ;;

        "SELinux (Avanzado - Requiere configuración manual post-install)")
            msg_info "Configurando SELinux..."
            msg_warn "Limpiando paquetes de AppArmor para evitar conflictos LSM..."

            # Purgamos AppArmor del entorno chroot si estuviera instalado
            arch-chroot /mnt pacman -Rns --noconfirm apparmor 2>/dev/null || true

            # Guardamos la marca de SELinux para el Bootloader
            echo "selinux" > /tmp/pandamonium_security
            echo "lsm=landlock,lockdown,yama,selinux,bpf" > /tmp/pandamonium_lsm_param

            msg_success "Parámetros de kernel para SELinux definidos."
            ;;

        *)
            msg_info "Sistemas MAC desactivados."
            msg_warn "Asegurando que no queden paquetes de AppArmor en el sistema base..."
            
            # Si el usuario no quiere nada, nos aseguramos de purgar AppArmor
            arch-chroot /mnt pacman -Rns --noconfirm apparmor 2>/dev/null || true
            ;;
    esac

    sleep 1.5
}
