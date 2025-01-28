declare-option -hidden str sess_dir

define-command -params 1 sh-send-command %{evaluate-commands %sh{ printf "$1\n" > $kak_opt_sess_dir/in }}

define-command -hidden spawn-shell %{ evaluate-commands %sh{
    tmpdir=$(mktemp -d -p ${TMPDIR:-/tmp} kak-shell.XXXXXX)
    printf "set-option global sess_dir $tmpdir"
    mkfifo $tmpdir/in $tmpdir/out
    exec 3<> $tmpdir/in
    exec 4<> $tmpdir/out
    setsid sh -i < $tmpdir/in > $tmpdir/out 2>&1 &
}}

hook global WinSetOption filetype=sh %{
    # map global insert <ret> %{ <a-;>evaluate-commands echo test;<ret>}
    map global normal <ret>  ': sh-send-command "%reg{.}"<ret>'
    map global user l  ": sh-send-command ls<ret>"
    map global user f ": sh-send-command fd<ret>"

    # add-highlighter
}

define-command sh-new-session %{
    evaluate-commands spawn-shell
    edit -fifo "%opt{sess_dir}/out" -scroll "%sh{ basename $kak_opt_sess_dir }.sh"
    set-option buffer filetype shell-session
}

define-command exit-shell %{sh-send-command "exit"}

