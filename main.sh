#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
    echo "Por favor, ejecuta el instalador como root (sudo ./main.sh)"
    exit 1
fi

source ui/gum_helpers.sh
source modules/01_network.sh
source modules/02_disks.sh
source modules/03_bootstrap.sh
source modules/04_chroot.sh
source modules/05_gui.sh


main_menu() {

    while true; do
        # Mostramos los paneles como el selector en sí
        local selected_panel
        selected_panel=$(show_interactive_5panel_dashboard)

        case "$selected_panel" in
            *"[01] CONFIGURACIÓN DE RED"*)
                check_and_configure_network
                ;;
            *"[02] PARTICIONADO Y DISCOS"*)
                setup_disks_and_mounts
                ;;
            *"[03] BOOTSTRAP DEL SISTEMA"*)
                run_bootstrap
                ;;
            *"[04] CONFIGURACIÓN EN CHROOT"*)
                run_chroot_config
                ;;
            *"[05] ENTORNO GRÁFICO"*)
                gui_sel
                ;;
            *"EJECUTAR INSTALACIÓN COMPLETA"*)
                msg_info "Lanzando secuencia completa de instalación..."
                check_and_configure_network
                setup_disks_and_mounts
                run_bootstrap
                run_chroot_config
                gui_sel
                msg_success "¡Instalación finalizada con éxito!"
                sleep 3
                ;;
            *"SALIR"*)
                msg_info "Saliendo de Pandamonium..."
                exit 0
                ;;
        esac
    done
}

main_menu
