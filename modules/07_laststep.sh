#!/usr/bin/env bash

source ui/gum_helpers.sh

run_last_step() {
    show_header
    msg_info "Finalización de Instalación"

    # Efecto estético mientras se leen los estados
    gum spin --spinner points --title "Mostrando resumen de instalación..." -- sleep 2

    # 1. LECTURA DE ESTADOS TEMPORALES (/tmp/pandamonium_state/)
    local distro="Desconocida"
    [ -f /tmp/pandamonium_state/distro ] && distro=$(cat /tmp/pandamonium_state/distro)

    local target_disk="No especificado"
    [ -f /tmp/pandamonium_state/target_disk ] && target_disk=$(cat /tmp/pandamonium_state/target_disk)

    local root_part="Desconocida"
    [ -f /tmp/pandamonium_state/root_part ] && root_part=$(cat /tmp/pandamonium_state/root_part)

    local fs_root="Desconocido"
    [ -f /tmp/pandamonium_state/fs_root ] && fs_root=$(cat /tmp/pandamonium_state/fs_root)

    local boot_part="N/A (BIOS/Legacy)"
    [ -f /tmp/pandamonium_state/boot_part ] && boot_part=$(cat /tmp/pandamonium_state/boot_part)

    local home_info="Integrado en Raíz"
    [ -f /tmp/pandamonium_state/home_info ] && home_info=$(cat /tmp/pandamonium_state/home_info)

    local kernel_choice="linux (Mainline)"
    [ -f /tmp/pandamonium_state/kernel_choice ] && kernel_choice=$(cat /tmp/pandamonium_state/kernel_choice)

    local ucode_pkg="Ninguno"
    [ -f /tmp/pandamonium_state/ucode_pkg ] && ucode_pkg=$(cat /tmp/pandamonium_state/ucode_pkg)

    local root_pass_status="No asignada"
    [ -f /tmp/pandamonium_state/root_password_status ] && root_pass_status=$(cat /tmp/pandamonium_state/root_password_status)

    local username="Ninguno"
    [ -f /tmp/pandamonium_state/username ] && username=$(cat /tmp/pandamonium_state/username)

    local user_pass_status="No asignada"
    [ -f /tmp/pandamonium_state/user_password_status ] && user_pass_status=$(cat /tmp/pandamonium_state/user_password_status)

    local security_choice="Ninguna (Sistema Vanilla)"
    [ -f /tmp/pandamonium_state/security_choice ] && security_choice=$(cat /tmp/pandamonium_state/security_choice)

    local bootloader="No especificado"
    [ -f /tmp/pandamonium_state/bootloader_choice ] && bootloader=$(cat /tmp/pandamonium_state/bootloader_choice)

    local gui_choice="Ninguno (Solo CLI / Servidor)"
    [ -f /tmp/pandamonium_state/gui_choice ] && gui_choice=$(cat /tmp/pandamonium_state/gui_choice)

    # 2. LECTURA DE PAQUETES EXTRA (/tmp/pandamonium_extra_pkgs)
    local extra_pkgs_count=0
    local extra_pkgs_list=""
    if [ -f /tmp/pandamonium_extra_pkgs ]; then
        extra_pkgs_count=$(wc -l < /tmp/pandamonium_extra_pkgs | tr -d ' ')
        extra_pkgs_list=$(paste -sd, /tmp/pandamonium_extra_pkgs | sed 's/,/, /g')
    fi

    # 3. CUADRO DE RESUMEN FINAL
    show_header
    echo -e "\033[1;36m========================================================\033[0m"
    echo -e "\033[1;32m       PANDAMONIUM INSTALLER - RESUMEN DE SISTEMA       \033[0m"
    echo -e "\033[1;36m========================================================\033[0m"
    echo -e " • \033[1mSistema Base / Init:\033[0m $distro"
    echo -e " • \033[1mUnidad Destino:\033[0m      $target_disk"
    echo -e " • \033[1mPartición Raíz (/):\033[0m  $root_part [$fs_root]"
    echo -e " • \033[1mPartición EFI (/boot):\033[0m $boot_part"
    echo -e " • \033[1mEstructura /home:\033[0m    $home_info"
    echo -e " • \033[1mKernel Seleccionado:\033[0m $kernel_choice"
    echo -e " • \033[1mMicrocódigo CPU:\033[0m     $ucode_pkg"
    echo -e " • \033[1mSeguridad (MAC):\033[0m     $security_choice"
    echo -e " • \033[1mGestor de Arranque:\033[0m  $bootloader"
    echo -e " • \033[1mInterfaz Gráfica:\033[0m    $gui_choice"
    echo -e " • \033[1mAdmin (root):\033[0m        Contraseña: $root_pass_status"
    echo -e " • \033[1mUsuario Personal:\033[0m    $username (Contraseña: $user_pass_status)"
    if [ "$extra_pkgs_count" -gt 0 ]; then
        echo -e " • \033[1mPaquetes Extra ($extra_pkgs_count):\033[0m $extra_pkgs_list"
    else
        echo -e " • \033[1mPaquetes Extra:\033[0m      Ninguno seleccionado"
    fi
    echo -e "\033[1;36m========================================================\033[0m"
    echo ""

    # Mensaje irónico característico de Arch Linux
    echo -e "\033[1;33m[ NOTA ]\033[0m"
    echo " Si instalar ArchLinux te ha parecido difícil, pásate a una distro más User-Friendly."
    echo ""

    # 4. MENÚ INTERACTIVO FINAL (GUM CHOOSE)
    msg_info "Selecciona qué deseas hacer a continuación:"
    local choice
    choice=$(gum choose \
        "Reiniciar el sistema" \
        "Volver al menú principal" \
        "Pasarme a Ubuntu")

    case "$choice" in
        "Reiniciar el sistema")
            msg_info "Desmontando sistemas de archivos de forma segura..."
            umount -R /mnt 2>/dev/null || true
            swapoff -a 2>/dev/null || true
            zpool export zroot 2>/dev/null || true

            msg_success "¡Todo listo! Reiniciando equipo en 3 segundos..."
            sleep 3
            reboot
            ;;
        "Volver al menú principal")
            msg_info "Regresando al menú principal del instalador..."
            sleep 1
            return 0
            ;;
        "Pasarme a Ubuntu")
            msg_info "Abriendo la realidad alternativa en w3m..."
            pacman -S --noconfirm w3m
            sleep 1
            clear
            w3m https://ubuntu.com/download
            
            #Volver al Last Step luego de la broma
            run_last_step
            ;;
    esac
}
