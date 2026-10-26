#!/usr/bin/env bash

source ui/gum_helpers.sh

# Mapa asociativo global para acumular la selección entre categorías
declare -gA SELECTED_EXTRA_PKGS_MAP=()

# Selección interactiva dentro de cada categoría con [X] y [Enter]
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
    # gum choose devuelve las líneas completas seleccionadas (ej. "firefox — Navegador web...")
    mapfile -t choices < <(gum choose --no-limit --cursor "➔ " "${available_pkgs[@]}")

    if [ ${#choices[@]} -gt 0 ]; then
        for item in "${choices[@]}"; do
            # Extraer únicamente el nombre técnico del paquete (lo que está antes del separador " — ")
            local pkg
            pkg=$(echo "$item" | awk -F ' — ' '{print $1}' | xargs)
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
             msg_info "NOTA: Etiqueta (AUR): Para compilar con Paru o Yay | Etiqueta (Chaotic): Ya precompilados"
        fi
        echo

        # Submenú interactivo
        local cat_choice
        cat_choice=$(gum choose --cursor "➔ " \
            "[01] Compiladores / Gestores de AUR" \
            "[02] Navegadores Web" \
            "[03] Comunicación y Mensajería" \
            "[04] Reproductores de Vídeo y Música" \
            "[05] Desarrollo y Programación" \
            "[06] Ofimática y Lectores" \
            "[07] Modelado 3D y Diseño" \
            "[08] Editores de Audio y Vídeo" \
            "[09] ArtCraft AI Slop" \
            "[10] Utilidades del Sistema" \
            "[11] INSTALAR PAQUETES SELECCIONADOS" \
            " ↩ VOLVER AL MENÚ PRINCIPAL")

        case "$cat_choice" in
            *"[01]"*)
                _select_category_pkgs "Compiladores / Gestores de AUR" \
                    "chaotic-mirrors — Repositorio binario comunitario precompilado" \
                    "paru — Ayudante de AUR veloz escrito en Rust" \
                    "yay — Asistente de AUR clásico basado en pacman"
                ;;
            *"[02]"*)
                _select_category_pkgs "Navegadores Web" \
                    "firefox — Navegador web libre y de código abierto" \
                    "chromium — Navegador web de código abierto base para Chrome" \
                    "brave-bin — (Chaotic) Navegador enfocado a la privacidad con bloqueo nativo" \
                    "google-chrome — (Chaotic) Navegador web oficial de Google" \
                    "microsoft-edge-stable-bin — (AUR) Navegador web oficial de Microsoft" \
                    "midori-bin — (AUR) Navegador web ligero basado en Firefox" \
                    "opera — (AUR) Navegador web oficial de Opera" \
                    "opera-gx — Navegador web oficial de Opera para Gamers"
                ;;

            *"[03]"*)
                _select_category_pkgs "Comunicación y Mensajería" \
                    "telegram-desktop — Aplicación oficial de Telegram" \
                    "discord — Aplicación oficial de Discord" \
                    "teams-for-linux — (Chaotic) Cliente no oficial de Microsoft Teams"
                ;;
            *"[04]"*)
                _select_category_pkgs "Reproductores de Vídeo" \
                    "vlc — Reproductor multimedia universal todoterreno" \
                    "mpv — Reproductor multimedia minimalista basado en MPlayer" \
                    "celluloid — Interfaz gráfica elegante para MPV" \
                    "audacious — Reproductor multimedia avanzado" \
                    "tauon-music-box — Tu reproductor musical de otra galaxia" \
                    "feishin — Reproductor moderno de música en local" \
                    "spotify — (AUR) Un servicio de música por streaming privativo"
                ;;
            *"[05]"*)
                _select_category_pkgs "Desarrollo y Programación" \
                    "git — Sistema de control de versiones distribuido" \
                    "wget — Utilidad para descarga de archivos por red" \
                    "curl — Herramienta de línea de comandos para transferir datos" \
                    "python — Lenguaje de programación interpretado de alto nivel" \
                    "go — Lenguaje de programación concurrente de Google" \
                    "gcc — Compilador GNU para C y C++" \
                    "cmake — Sistema cruzado de generadores de compilación" \
                    "neovim — Editor de texto basado en Vim" \
                    "code — Editor de código fuente, versión Open Source de VSCode" \
                    "visual-studio-code-bin — (Chaotic) Editor de código fuente oficial de Microsoft" \
                    "sublime-text-4 — (Chaotic) Editor de texto avanzado para código y marcado" \
                    "antigravity — (AUR) IDE impulsado por agentes desarrollado por Google" \
                    "lmstudio-bin — (AUR) Gestor de agentes y modelos para uso local" \
                    "claude-code — (AUR)"
                ;;
            *"[06]"*)
                _select_category_pkgs "Ofimática y Lectores" \
                    "libreoffice-fresh — Suite de oficina completa y actualizada" \
                    "onlyoffice-bin — (Chaotic) Suite de oficina similar a MS Office" \
                    "wps-office — (AUR) Suite de oficina de Kingsoft" \
                    "okular — Visor de documentos universal de KDE"
                ;;
            *"[07]"*)
                _select_category_pkgs "Modelado 3D y Diseño" \
                    "blender — Suite de creación 3D completa" \
                    "librecad — Edición comunitaria de QCad" \
                    "gimp — Programa libre de edición de imágenes rasterizadas" \
                    "pinta — Programa de dibujo libre con una estética similar a PaintdotNET"
                ;;
            *"[08]"*)
                _select_category_pkgs "Editores de Audio y Vídeo" \
                    "audacity — Editor multipista de audio" \
                    "kdenlive — Editor de vídeo desarrollado por KDE" \
                    "davinci-resolve — (AUR) Editor de vídeo de grado profesional" 
                ;;
           *"[09]"*)
                _select_category_pkgs "ArtCraft AI Slop" \ #Solo está aquí porque sé que muchos lo desean.
                    "photocraft — (Chaotic) Photoshop vibecodeado, colorimetría errónea" \
                    "filmcraft — (Chaotic) Premiere vibecodeado, mal tiempo de rendering" \
                    "pdfcraft — (Chaotic) Editor y lector de PFDs vibecodeado, no esperes mucho más" \
                    "effectcraft — (Chaotic) AfterEffects vibecodeado, sin buen timeline de animación" \
                    "vectorcraft — (Chaotic) Illustrator vibecodeado, no entiende algunos vectores" \
                    "lightcraft — (Chaotic) Lightroom vibecodeado, los filtros y colores funcionan mal" \
                    "cadcraft — (Chaotic) AutoCAD vibecodeado, sin todas las implementaciones de escala" \
                    "wordcraft — (Chaotic) Word vibecodeado, sin citas o estilos" \
                    "gridcraft — (Chaotic) Excel vibecodeado, sin macros y bases de datos" \
                    "deckcraft — (Chaotic) PowerPoint vibecodeado, no esperes gran cosa" \
                    "soundcraft — (Chaotic) Avid Pro Tools vibecodeado, Open Source del mismo" 
                    
                ;; 
            *"[10]"*)
                _select_category_pkgs "Utilidades del Sistema" \
                    "htop — Monitor interactivo de procesos en terminal" \
                    "btop — Monitor de recursos moderno y visual en terminal" \
                    "fastfetch — Información del sistema rápida y personalizable" \
                    "unzip — Utilidad para descompresión de archivos ZIP" \
                    "p7zip — Compresor de archivos de alta tasa con soporte 7z"
                ;;
            *"[11]"*)
                msg_info "Estos paquetes necesitan de una versión estable del kernel para no romper dependencias con DKMS" \
                _select_category_pkgs "Virtualización y Contenedores" \
                    "docker — Adminstrador de aplicaciones en contenedores" \
                    "docker-desktop — (AUR) Interfaz gráfica de Docker (recomendado instalar junto a docker)" \
                    "kubeadm — Orquestador de contenedores para gestión de aplicaciones (recomendado instalar junto a kubelet)" \
                    "kubelet — Agente de automatización de nodos (recomendado instalar junto a kubeadm)" \
                    "qemu-full — Hipervisor (cliente) de alta fidelidad (recomendado usar junto a Virt Manager)" \
                    "virt-manager — Hipervisor gráfico que usa KVM (recomendado usar junto a QEMU)" \
                    "vmware-workstation — (AUR) Hipervisor gráfico de Broadcom (recomendado instalar linux firmware según tu kernel)" \
                    "virtualbox — Hipervisor gráfico de Oracle (recomendado instalar virtualbox host dkms para mejor integración)"
                ;;
            *"[12]"*)
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
