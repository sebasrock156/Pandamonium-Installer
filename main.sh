#!/usr/bin/env bash

# Validar que se ejecute como Root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta el instalador como root (sudo ./main.sh)"
  exit 1
fi

# Cargar utilidades y módulos
source ui/gum_helpers.sh
source modules/01_network.sh
source modules/02_disks.sh
source modules/03_bootstrap.sh
source modules/04_chroot.sh

main_menu() {
    while true; do
        show_header
        msg_info "Panel de Control - Pandamonium Installer"

        local choice
        choice=$(gum choose \
            "1. Comprobar y Configurar Red" \
            "2. Particionado y Montajes" \
            "3. Bootstrap (Pacstrap / Artix)" \
            "4. Chroot y Configuración del Sistema" \
            "🚀 Ejecutar Instalación Completa (Secuencial)" \
            "Salir")

        case "$choice" in
            "1. Comprobar y Configurar Red")
                check_and_configure_network
                ;;
            "2. Particionado y Montajes")
                setup_disks_and_mounts
                ;;
            "3. Bootstrap (Pacstrap / Artix)")
                run_bootstrap
                ;;
            "4. Chroot y Configuración del Sistema")
                run_chroot_config
                ;;
            "🚀 Ejecutar Instalación Completa (Secuencial)")
                check_and_configure_network
                setup_disks_and_mounts
                run_bootstrap
                run_chroot_config
                msg_success "¡Instalación completa finalizada con éxito!"
                sleep 3
                ;;
            "Salir")
                msg_info "Saliendo del instalador..."
                exit 0
                ;;
        esac

        # Pausa breve antes de volver al menú
        echo ""
        msg_info "Pulsa Intro para volver al menú principal..."
        read -r
    done
}

# Lanzar el menú principal
main_menu
