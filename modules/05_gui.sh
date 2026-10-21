#!/usr/bin/env bash

source ui/gum_helpers.sh
source modules/init/05a_gui_systemd.sh
source modules/init/05b_gui_openrc.sh

gui_sel() {
    show_header
    msg_info "Selección de Interfaz Gráfica (Entornos y Gestores de Ventanas)"

    # Autodetección del entorno instalado para elegir el init correcto
    if [ -d /mnt/etc/openrc ]; then
        msg_info "Entorno Artix detectado. Cargando gestor gráfico para OpenRC..."
        run_gui_openrc
    else
        msg_info "Entorno Arch detectado. Cargando gestor gráfico para Systemd..."
        run_gui_systemd
    fi
}
