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
        "PANDAMONIUM INSTALLER (v0.2)r"
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

# --- FUNCIÓN CON LOS 5 PANELES COMO BOTONES DE SELECCIÓN ---
show_interactive_5panel_dashboard() {
    show_header

    # Generamos cada panel individual estilizado
    local p1 p2 p3 p4 p5 p_all p_exit

    p1=$(gum style --border "rounded" --border-foreground "39" --padding "0 2" --width 86 \
        " [01] CONFIGURACIÓN DE RED" \
        "      Interfaces de red, asignación IP y prueba de conectividad")

    p2=$(gum style --border "rounded" --border-foreground "212" --padding "0 2" --width 86 \
        " [02] PARTICIONADO Y DISCOS" \
        "      Estructura de tablas de particiones (CFDisk/FDisk) y puntos de montaje")

    p3=$(gum style --border "rounded" --border-foreground "208" --padding "0 2" --width 86 \
        " [03] BOOTSTRAP DEL SISTEMA" \
        "      Instalación base del Kernel y selección de Init (Systemd/OpenRC)")

    p4=$(gum style --border "rounded" --border-foreground "99" --padding "0 2" --width 86 \
        " [04] CONFIGURACIÓN EN CHROOT" \
        "      Zona horaria, Locale, Hostname, contraseña Root y Bootloader")

    p5=$(gum style --border "rounded" --border-foreground "46" --padding "0 2" --width 86 \
        " [05] ENTORNO GRÁFICO (DE/WM)" \
        "      KDE, Gnome, Hyprland, i3, etc. y activación de Display Manager")

    p_all=$(gum style --border "double" --border-foreground "226" --padding "0 2" --width 86 \
        " [06] EJECUTAR INSTALACIÓN COMPLETA" \
        "      Lanza toda la instalación en automático")

    p_exit=$(gum style --border "rounded" --border-foreground "196" --padding "0 2" --width 86 \
        " SALIR")

    # Pasamos las tarjetas enteras como opciones de gum choose
    gum choose "$p1" "$p2" "$p3" "$p4" "$p5" "$p_all" "$p_exit"
}
