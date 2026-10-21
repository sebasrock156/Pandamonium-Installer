#!/usr/bin/env bash

# Pedir al usuario que ejecute como root, en caso de que ARCHISO no lo priorice
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta el instalador como root (sudo ./main.sh)"
  exit 1
fi

# Carga de módulos
source ui/gum_helpers.sh
source modules/01_network.sh
source modules/02_disks.sh
source modules/03_bootstrap.sh
source modules/04_chroot.sh
source modules/05_desktop.sh

main_menu() {
    while true; do
        show_header
        msg_info "Pandamonium Installer - Otro script de instalación de Arch"

        local choice
        choice=$(gum choose \
            "1. Comprobar y Configurar Red" \
            "2. Particionado y Montajes" \
            "3. Bootstrap (Systemd/OpenRC)" \
            "4. Chroot y Configuración del Sistema" \
            "5. Elección de GUI (DE/WM)" \
            "6. Ejecutar Instalación Completa (Secuencial)" \
            "Salir")

        case "$choice" in
            "1. Comprobar y Configurar Red")
                check_and_configure_network
                ;;
            "2. Particionado y Montajes")
                setup_disks_and_mounts
                ;;
            "3. Bootstrap (Systemd/OpenRC)")
                run_bootstrap
                ;;
            "4. Chroot y Configuración del Sistema")
                run_chroot_config
                ;;
            "5. Elección de GUI (DE/WM)")
                run_desktop_selection
                ;;
            "6. Ejecutar Instalación Completa (Secuencial)")
                check_and_configure_network
                setup_disks_and_mounts
                run_bootstrap
                run_chroot_config
                run_desktop_selection
                msg_success "¡Instalación completada!"
                sleep 3
                ;;
            "Salir")
                msg_info "Saliendo del instalador..."
                exit 0
                ;;
        esac

        # Pausa previa al retorno
        echo ""
        msg_info "Pulsa Intro para volver al menú principal..."
        read -r
    done
}

# Menú principal
main_menu
