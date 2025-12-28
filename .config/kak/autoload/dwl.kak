provide-module dwl %{

# # Ensure we're actually in Sway
# evaluate-commands %sh{
#     [ -z "${kak_opt_windowing_modules}" ] || 
#     [ -n "$SWAYSOCK" ] ||
#     echo 'fail SWAYSOCK is not set'
# }

require-module 'wayland'

alias global dwl-terminal-window wayland-terminal-window

define-command dwl-terminal-vertical -params 1.. -docstring '
    dwl-terminal-vertical <program> [<arguments>]: create a new terminal as a Sway window
    The current pane is split into two, top and bottom
    The program passed as argument will be executed in the new terminal' \
%{
    wayland-terminal-window %arg{@}
}
complete-command dwl-terminal-vertical shell

define-command dwl-focus-appid -hidden %{
    echo -end-of-line -to-file "%val{client_env_XDG_RUNTIME_DIR}/dwl" "focusappid %val{client_env_APPID}"
}

define-command dwl-focus -params ..1 -docstring '
dwl-focus [<kakoune_client>]: focus a given client''s window.
If no client is passed, then the current client is used' \
%{
    # Quick branch to make sure we're calling dwl-focus-pid from the client 
    # the user wants to focus on.
    evaluate-commands %sh{
        if [ $# -eq 1 ]; then
            printf "evaluate-commands -client '%s' dwl-focus-appid" "$1"
        else
            echo dwl-focus-appid
        fi
    }
}
complete-command -menu dwl-focus client

alias global focus dwl-focus

}

