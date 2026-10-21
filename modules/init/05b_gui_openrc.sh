#!/usr/bin/env bash

source ui/gum_helpers.sh

run_gui_openrc() {
    local display_manager=""

    # 1. Elegir la categoría principal
    local choice_type
    choice_type=$(gum choose "Entorno de Escritorio (DE)" "Gestor de Ventanas (WM)" "Ninguno (Solo CLI / Servidor)")[cite: 2]

    case "$choice_type" in
        "Entorno de Escritorio (DE)")
            local de_choice
            de_choice=$(gum choose "KDE Plasma" "Gnome" "Cinnamon" "XFCE" "Budgie" "Mate")[cite: 2]

            case "$de_choice" in
                "KDE Plasma")
                    msg_info "Instalando KDE Plasma y SDDM..."[cite: 2]
                    artix-chroot /mnt pacman -S --noconfirm plasma kde-applications sddm[cite: 2]
                    display_manager="sddm"[cite: 2]
                    ;;
                "Gnome")
                    msg_info "Instalando Gnome y GDM..."[cite: 2]
                    artix-chroot /mnt pacman -S --noconfirm gnome gnome-extra gdm[cite: 2]
                    display_manager="gdm"[cite: 2]
                    ;;
                "Cinnamon")
                    msg_info "Instalando Cinnamon y LightDM..."[cite: 2]
                    artix-chroot /mnt pacman -S --noconfirm cinnamon lightdm lightdm-gtk-greeter[cite: 2]
                    display_manager="lightdm"[cite: 2]
                    ;;
                "XFCE")
                    msg_info "Instalando XFCE y LightDM..."[cite: 2]
                    artix-chroot /mnt pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter[cite: 2]
                    display_manager="lightdm"[cite: 2]
                    ;;
                "Budgie")
                    msg_info "Instalando Budgie y LightDM..."[cite: 2]
                    artix-chroot /mnt pacman -S --noconfirm budgie-desktop budgie-extras lightdm lightdm-gtk-greeter[cite: 2]
                    display_manager="lightdm"[cite: 2]
                    ;;
                "Mate")
                    msg_info "Instalando Mate y LightDM..."[cite: 2]
                    artix-chroot /mnt pacman -S --noconfirm mate mate-extra lightdm lightdm-gtk-greeter[cite: 2]
                    display_manager="lightdm"[cite: 2]
                    ;;
            endcase
            ;;

        "Gestor de Ventanas (WM)")
            local wm_choice
            wm_choice=$(gum choose "i3" "Hyprland" "Fluxbox / Openbox")[cite: 2]

            case "$wm_choice" in
                "i3")
                    msg_info "Instalando i3-wm, dmenu y LightDM..."[cite: 2]
                    artix-chroot /mnt pacman -S --noconfirm i3-wm i3status dmenu lightdm lightdm-gtk-greeter[cite: 2]
                    display_manager="lightdm"[cite: 2]
                    ;;
                "Hyprland")
                    msg_info "Instalando Hyprland, Waybar y SDDM..."[cite: 2]
                    artix-chroot /mnt pacman -S --noconfirm hyprland waybar kitty wofi sddm[cite: 2]
                    display_manager="sddm"[cite: 2]
                    ;;
                "Fluxbox / Openbox")
                    msg_info "Instalando Openbox, Fluxbox y LightDM..."[cite: 2]
                    artix-chroot /mnt pacman -S --noconfirm openbox fluxbox obconf lightdm lightdm-gtk-greeter[cite: 2]
                    display_manager="lightdm"[cite: 2]
                    ;;
            endcase
            ;;

        "Ninguno (Solo CLI / Servidor)")
            msg_info "Saltando la instalación gráfica. El sistema arrancará en consola."[cite: 2]
            ;;
    esac

    # 2. Habilitación de servicios con OpenRC
    artix-chroot /mnt rc-update add NetworkManager default[cite: 2]
    [ -n "$display_manager" ] && artix-chroot /mnt rc-update add "$display_manager" default[cite: 2]

    msg_success "¡Módulo gráfico (OpenRC) configurado con éxito!"[cite: 2]
    sleep 2
}
