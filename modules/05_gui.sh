#!/usr/bin/env bash

source ui/gum_helpers.sh

gui_sel() {
    show_header
    msg_info "Selección de Interfaz Gráfica (Entornos y Gestores de Ventanas)"

    # Determinamos el gestor de servicios activo leyendo el archivo de estado compartido
    local init_system="systemd"
    if [ -f /tmp/pandamonium_init ]; then
        init_system=$(cat /tmp/pandamonium_init)
    fi

    if [ "$init_system" = "openrc" ]; then
        msg_info "Modo Artix detectado por estado. Usando gestión de servicios con OpenRC..."
    else
        msg_info "Modo Arch detectado por estado. Usando gestión de servicios con SystemD..."
    fi

    # Usamos arch-chroot universalmente ya que artix-chroot no existe en la ISO base de Arch
    local chroot_cmd="arch-chroot"
    local display_manager=""

    # 1. Elegir la categoría principal
    local choice_type
    choice_type=$(gum choose "Entorno de Escritorio (DE)" "Gestor de Ventanas (WM)" "Ninguno (Solo CLI / Servidor)")

    case "$choice_type" in
        "Entorno de Escritorio (DE)")
            local de_choice
            de_choice=$(gum choose "KDE Plasma" "Gnome" "Cinnamon" "XFCE" "Budgie" "Mate")

            case "$de_choice" in
                "KDE Plasma")
                    msg_info "Instalando KDE Plasma y SDDM..."
                    $chroot_cmd /mnt pacman -S --noconfirm plasma kde-applications sddm
                    display_manager="sddm"
                    ;;
                "Gnome")
                    msg_info "Instalando Gnome y GDM..."
                    $chroot_cmd /mnt pacman -S --noconfirm gnome gnome-extra gdm
                    display_manager="gdm"
                    ;;
                "Cinnamon")
                    msg_info "Instalando Cinnamon y LightDM..."
                    $chroot_cmd /mnt pacman -S --noconfirm cinnamon lightdm lightdm-gtk-greeter
                    display_manager="lightdm"
                    ;;
                "XFCE")
                    msg_info "Instalando XFCE y LightDM..."
                    $chroot_cmd /mnt pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
                    display_manager="lightdm"
                    ;;
                "Budgie")
                    msg_info "Instalando Budgie y LightDM..."
                    $chroot_cmd /mnt pacman -S --noconfirm budgie-desktop budgie-extras lightdm lightdm-gtk-greeter
                    display_manager="lightdm"
                    ;;
                "Mate")
                    msg_info "Instalando Mate y LightDM..."
                    $chroot_cmd /mnt pacman -S --noconfirm mate mate-extra lightdm lightdm-gtk-greeter
                    display_manager="lightdm"
                    ;;
            esac
            ;;

        "Gestor de Ventanas (WM)")
            local wm_choice
            wm_choice=$(gum choose "i3" "Hyprland" "Fluxbox / Openbox")

            case "$wm_choice" in
                "i3")
                    msg_info "Instalando i3-wm, dmenu y LightDM..."
                    $chroot_cmd /mnt pacman -S --noconfirm i3-wm i3status dmenu lightdm lightdm-gtk-greeter
                    display_manager="lightdm"
                    ;;
                "Hyprland")
                    msg_info "Instalando Hyprland, Waybar y SDDM..."
                    $chroot_cmd /mnt pacman -S --noconfirm hyprland waybar kitty wofi sddm
                    display_manager="sddm"
                    ;;
                "Fluxbox / Openbox")
                    msg_info "Instalando Openbox, Fluxbox y LightDM..."
                    $chroot_cmd /mnt pacman -S --noconfirm openbox fluxbox obconf lightdm lightdm-gtk-greeter
                    display_manager="lightdm"
                    ;;
            esac
            ;;

        "Ninguno (Solo CLI / Servidor)")
            msg_info "Saltando la instalación gráfica. El sistema arrancará en consola."
            ;;
    esac

    # 2. Habilitación de servicios según el Init registrado
    if [ "$init_system" = "openrc" ]; then
        # Gestión para OpenRC en Artix
        $chroot_cmd /mnt rc-update add NetworkManager default
        [ -n "$display_manager" ] && $chroot_cmd /mnt rc-update add "$display_manager" default
    else
        # Gestión para SystemD en Arch oficial
        $chroot_cmd /mnt systemctl enable NetworkManager
        [ -n "$display_manager" ] && $chroot_cmd /mnt systemctl enable "$display_manager"
    fi

    msg_success "¡Módulo de gráficos y servicios configurado con éxito!"
    sleep 2
}
