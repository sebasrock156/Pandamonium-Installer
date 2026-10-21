#!/usr/bin/env bash

source ui/gum_helpers.sh

# Mapa asociativo global para acumular la selección entre categorías
declare -gA SELECTED_EXTRA_PKGS_MAP=()

# Selección interactiva dentro de cada categoría con [X] / [Espacio]
_select_category_pkgs() {
    local cat_title="$1"
    shift
    local available_pkgs=("$@")

    clear
    show_header
    msg_info "Categoría: $cat_title"
    msg_info "Usa [X] para marcar paquetes y [Enter] para confirmar."
    echo

    local choices
    mapfile -t choices < <(gum choose --no-limit --cursor "➔ " "${available_pkgs[@]}")

    if [ ${#choices[@]} -gt 0 ]; then
        for pkg in "${choices[@]}"; do
            pkg="$(echo "$pkg" | xargs)"
            if [ -n "$pkg" ]; then
                SELECTED_EXTRA_PKGS_MAP["$pkg"]=1
            fi
        done
        msg_success "¡Paquetes de '$cat_title' guardados correctamente!"
    else
        msg_error "No se marcó ningún paquete en esta categoría."
    fi
    sleep 1.5
}

extras_sel() {
    while true; do
        clear
        show_header
        msg_info "Categorías de Aplicaciones y Utilidades Extra"

        local current_pkgs=("${!SELECTED_EXTRA_PKGS_MAP[@]}")

        if [ ${#current_pkgs[@]} -gt 0 ]; then
            msg_success "Paquetes marcados (${#current_pkgs[@]}): ${current_pkgs[*]}"
        else
            msg_info "No hay paquetes marcados para instalar aún."
        fi
        echo

        # Submenú interactivo
        local cat_choice
        cat_choice=$(gum choose --cursor "➔ " \
            "[01] Compiladores / Gestores de AUR" \
            "[02] Navegadores Web" \
            "[03] Reproductores de Vídeo" \
            "[04] Desarrollo y Programación" \
            "[05] Ofimática y Lectores" \
            "[06] Modelado 3D y Diseño" \
            "[07] Utilidades del Sistema" \
            "[08] 📥 INSTALAR PAQUETES SELECCIONADOS" \
            "[09] ↩ VOLVER AL MENÚ PRINCIPAL")

        case "$cat_choice" in
            *"[01]"*)
                # Depuración: Paquetes altamente populares y presentes en repos / Chaotic
                _select_category_pkgs "Compiladores / Gestores de AUR" \
                    "chaotic-mirrors" "paru" "yay"
                ;;
            *"[02]"*)
                _select_category_pkgs "Navegadores Web" \
                    "firefox" "chromium" "brave-bin" "google-chrome"
                ;;
            *"[03]"*)
                _select_category_pkgs "Reproductores de Vídeo" \
                    "vlc" "mpv" "celluloid"
                ;;
            *"[04]"*)
                _select_category_pkgs "Desarrollo y Programación" \
                    "git" "wget" "curl" "python" "go" "gcc" "cmake" "code" "visual-studio-code-bin"
                ;;
            *"[05]"*)
                _select_category_pkgs "Ofimática y Lectores" \
                    "libreoffice-fresh" "okular"
                ;;
            *"[06]"*)
                _select_category_pkgs "Modelado 3D y Diseño" \
                    "blender" "gimp"
                ;;
            *"[07]"*)
                _select_category_pkgs "Utilidades del Sistema" \
                    "htop" "btop" "fastfetch" "unzip" "p7zip"
                ;;
            *"[08]"*)
                local pkgs_to_install=("${!SELECTED_EXTRA_PKGS_MAP[@]}")
                if [ ${#pkgs_to_install[@]} -eq 0 ]; then
                    msg_error "No has marcado ningún paquete para instalar."
                    sleep 2
                else
                    # -------------------------------------------------------------
                    # Detección y Sugerencia de Chaotic-AUR
                    # -------------------------------------------------------------
                    local has_chaotic=false
                    for pkg in "${pkgs_to_install[@]}"; do
                        if [ "$pkg" == "chaotic-mirrors" ]; then
                            has_chaotic=true
                            break
                        fi
                    done

                    # Si el usuario NO marcó Chaotic, se lo sugerimos interactivamente
                    if [ "$has_chaotic" == "false" ]; then
                        echo
                        msg_info "Sugerencia: Activar Chaotic-AUR permite instalar paquetes de AUR (yay, paru, google-chrome, etc.) con pacman directo."
                        if gum confirm "¿Deseas activar Chaotic-AUR antes de instalar?"; then
                            SELECTED_EXTRA_PKGS_MAP["chaotic-mirrors"]=1
                            pkgs_to_install=("${!SELECTED_EXTRA_PKGS_MAP[@]}")
                            has_chaotic=true
                        fi
                    fi

                    msg_info "Procesando e instalando paquetes seleccionados..."

                    local target_dir="/"
                    [ -d "/mnt/var/lib/pacman" ] && target_dir="/mnt"

                    local run_cmd=""
                    [ "$target_dir" == "/mnt" ] && run_cmd="arch-chroot /mnt"

                    # -------------------------------------------------------------
                    # Configuración de Chaotic-AUR si corresponde
                    # -------------------------------------------------------------
                    if [ "$has_chaotic" == "true" ]; then
                        msg_info "Añadiendo llaves y repositorio Chaotic-AUR..."

                        $run_cmd pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
                        $run_cmd pacman-key --lsign-key 3056513887B78AEB || true

                        $run_cmd pacman -U --noconfirm \
                            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
                            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

                        local pacman_conf="$target_dir/etc/pacman.conf"
                        if ! grep -q "\[chaotic-aur\]" "$pacman_conf"; then
                            echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> "$pacman_conf"
                            msg_success "Chaotic-AUR inyectado correctamente en pacman.conf"
                        fi

                        $run_cmd pacman -Sy
                    fi

                    # Filterout 'chaotic-mirrors' para no enviarlo como nombre de paquete a pacman
                    local final_pkgs=()
                    for pkg in "${pkgs_to_install[@]}"; do
                        [ "$pkg" == "chaotic-mirrors" ] && continue
                        final_pkgs+=("$pkg")
                    done

                    # -------------------------------------------------------------
                    # Instalación directa vía Pacman
                    # -------------------------------------------------------------
                    if [ ${#final_pkgs[@]} -gt 0 ]; then
                        msg_info "Lanzando pacman para: ${final_pkgs[*]}"

                        if $run_cmd pacman -S --noconfirm --needed "${final_pkgs[@]}"; then
                            msg_success "¡Paquetes instalados con éxito!"
                            SELECTED_EXTRA_PKGS_MAP=()
                            sleep 3
                            return
                        else
                            msg_error "Ocurrió un error durante la instalación de pacman."
                            msg_info "Volviendo al menú de categorías..."
                            sleep 3
                        fi
                    else
                        msg_success "Configuración de repositorios completada."
                        SELECTED_EXTRA_PKGS_MAP=()
                        sleep 2
                        return
                    fi
                fi
                ;;
            *"[09]"*|*)
                return
                ;;
        esac
    done
}
