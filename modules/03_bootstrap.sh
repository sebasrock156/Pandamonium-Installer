#!/usr/bin/env bash

source ui/gum_helpers.sh
source modules/init/03a_bootstrap_systemd.sh
source modules/init/03b_bootstrap_openrc.sh

run_bootstrap() {
    show_header
    msg_info "Configuración de Bootstrap e Inicialización del Sistema"

    # Selección de Init
    msg_info "Selecciona el Sistema de Inicio (Init) deseado:"
    local init_choice
    init_choice=$(gum choose "Systemd (ArchLinux Repos)" "OpenRC (Artix Repos)")

    case "$init_choice" in
        "Systemd (ArchLinux Repos)")
            run_bootstrap_systemd
            ;;
        "OpenRC (Artix Repos)")
            run_bootstrap_openrc
            ;;
        *)
            msg_error "Selección no válida. Cancelando bootstrap."
            sleep 2
            return 1
            ;;
    esac
}
