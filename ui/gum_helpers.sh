#!/usr/bin/env bash

show_header() {
    gum style \
        --border "rounded" \
        --align "center" \
        --width 90 \
        --margin "1 0" \
        --padding "0 1" \
        --foreground "39" \
        --border-foreground "39" \
        "PANDAMONIUM INSTALLER (v0.2)"
}

msg_info() {
    gum style --foreground "39" "➔ $1"
}

msg_success() {
    gum style --foreground "46" "✔ $1"
}

msg_error() {
    gum style --foreground "196" "✖ $1"
}

# Paneles como botones
show_interactive_panel_dashboard() {
    show_header

    local p1 p2 p3 p4 p5 p6 p_all b_exit

    p1=$(gum style --border "rounded" --border-foreground "39" --padding "0 2" --width 90 \
        " [01] CONFIGURACIÓN DE RED" \
        "      Interfaces de red, asignación IP y prueba de conectividad")

    p2=$(gum style --border "rounded" --border-foreground "212" --padding "0 2" --width 90 \
        " [02] PARTICIONADO Y DISCOS" \
        "      Estructura de tablas de particiones (CFDisk/FDisk) y puntos de montaje")

    p3=$(gum style --border "rounded" --border-foreground "208" --padding "0 2" --width 90 \
        " [03] BOOTSTRAP DEL SISTEMA" \
        "      Instalación base del Kernel y selección de Init (Systemd/OpenRC)")

    p4=$(gum style --border "rounded" --border-foreground "99" --padding "0 2" --width 90 \
        " [04] CONFIGURACIÓN EN CHROOT" \
        "      Zona horaria, Locale, Hostname, contraseña Root y Bootloader")

    p5=$(gum style --border "rounded" --border-foreground "46" --padding "0 2" --width 90 \
        " [05] ENTORNO GRÁFICO (DE/WM)" \
        "      KDE, Gnome, Hyprland, i3, etc. y activación de Display Manager")

    p6=$(gum style --border "rounded" --border-foreground "46" --padding "0 2" --width 90 \
        " [06] EXTRAS" \
        "      Navegadores, reproductores, compiladores de paquetes, etc.")

    p_all=$(gum style --border "double" --border-foreground "226" --padding "0 2" --width 90 \
        " [07] EJECUTAR INSTALACIÓN COMPLETA" \
        "      Lanza toda la instalación en automático")

    # Botón de salida movido hacia la derecha
    b_exit=$(gum style --border "rounded" --border-foreground "196" --padding "0 2" --width 24 \
        "      SALIR")
    b_exit_right=$(echo "$b_exit" | sed 's/^/                                                             /')

    # Indicador de foco invisible
    gum choose --cursor "" "$p1" "$p2" "$p3" "$p4" "$p5" "$p6" "$p_all" "$b_exit_right"
}
