#!/usr/bin/env bash

# Colores y estilos globales para Gum
BANNER_COLOR="212" # Rosa/Púrpura neón
ERROR_COLOR="196"  # Rojo
SUCCESS_COLOR="82"  # Verde

show_header() {
    clear
    gum style \
        --foreground "$BANNER_COLOR" \
        --border double \
        --align center \
        --width 60 \
        --margin "1 2" \
        --padding "1 2" \
        "Pandamonium - ArchLinux Installer" "Script ligero de instalación"
}

run_spinner_network() {
    local title="$1"
    shift
    gum spin --spinner globe --title "$title" -- "$@"
}

msg_info() {
    gum style --foreground "$BANNER_COLOR" "➜ $1"
}

msg_success() {
    gum style --foreground "$SUCCESS_COLOR" "✔ $1"
}

msg_error() {
    gum style --foreground "$ERROR_COLOR" --bold "✖ ERROR: $1"
}

confirm_action() {
    local prompt="$1"
    gum confirm "$prompt" --affirmative "Continuar" --negative "Cancelar"
}
