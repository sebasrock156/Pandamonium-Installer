#!/usr/bin/env bash

source ui/gum_helpers.sh

check_and_configure_network() {
    show_header
    msg_info "Comprobando conexión a Internet..."
    gum spin --spinner globe --title "Conectando con servidores de Arch Linux..." -- sleep 5

    if ping -c 1 archlinux.org >/dev/null 2>&1; then
        msg_success "Conexión a Internet detectada correctamente."
        sleep 1.5
        return 0
    fi

    msg_error "No hay conexión a Internet activa."

    local net_mode
    net_mode=$(gum choose "Conectar a Wi-Fi (iwd)" "Conectar por Ethernet (dhcpcd/NM)" "Reintentar comprobación" "Salir")

    case "$net_mode" in
        "Conectar a Wi-Fi (iwd)")
            msg_info "Abriendo entorno interactivo de iwctl..."
            sleep 1
            iwctl
            check_and_configure_network
            ;;
        "Conectar por Ethernet (dhcpcd/NM)")
            msg_info "Solicitando IP vía DHCP..."
            dhcpcd
            sleep 2
            check_and_configure_network
            ;;
        "Reintentar comprobación")
            check_and_configure_network
            ;;
        *)
            msg_error "Se requiere Internet para continuar con la instalación."
            exit 1
            ;;
    esac
}
