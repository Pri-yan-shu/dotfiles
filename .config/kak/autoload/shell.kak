declare-option str sh_fifo
# declare-option str sh_pwd
declare-option str sh_pid

define-command -params 1.. sh-spawn %{
    evaluate-commands %sh{
        export kak_session
        export kak_client
        export TERM=dumb
        export sh_fifo=$(mktemp -d "${TMPDIR:-/tmp}"/sh.XXXX)

        mkfifo $sh_fifo/in $sh_fifo/out

        exec 3<>$sh_fifo/in
        exec 4<>$sh_fifo/out

        setsid $@ >&4 <&3 2>&1 &

        printf "edit -fifo $sh_fifo/out -scroll '$!:${PWD##*/}'
                set-option buffer sh_pid $!
                set-option buffer sh_fifo $sh_fifo\n"
    }

    hook -once -always buffer BufCloseFifo .* %{
        evaluate-commands %sh{
            rm -r $kak_opt_sh_fifo
            kill -s 9 $kak_opt_sh_pid
        }
    }

    set-option buffer filetype shell
}

define-command -params 1.. sh-file %{
    nop %sh{
        cat $@ > $kak_opt_sh_fifo/out
    }
}

complete-command sh-file file

define-command -params 1.. sh-send %{
    echo -end-of-line -to-file "%opt{sh_fifo}/in" %arg{@}
}


provide-module shell %§

add-highlighter shared/shell regions
add-highlighter shared/shell/code default-region group
add-highlighter shared/shell/arithmetic region -recurse \(.*?\( (\$|(?<=for)\h*)\(\( \)\) group
add-highlighter shared/shell/double_string region  %{(?<!\\)(?:\\\\)*\K"} %{(?<!\\)(?:\\\\)*"} group
add-highlighter shared/shell/expansion region -recurse (?<!\\)(?:\\\\)*\K\$\{ (?<!\\)(?:\\\\)*\K\$\{ \}|\n fill value
add-highlighter shared/shell/comment region (?<!\\)(?:\\\\)*(?:^|\h)\K# '$' fill comment
# add-highlighter shared/shell/heredoc region -match-capture '<<-?\h*''?(\w+)''?' '^\t*(\w+)$' fill string

add-highlighter shared/shell/arithmetic/expansion ref shell/double_string/expansion
add-highlighter shared/shell/double_string/fill fill string
# add-highlighter shared/shell/single_string region %{(?<!\\)(?:\\\\)*\K'} %{[^'\n]*(?:\\'[^'\n]*)*'} fill string

add-highlighter shared/shell/code/operators regex [\[\]\(\)&|]{1,2} 0:operator
add-highlighter shared/shell/code/variable regex ((?<![-:])\b\w+)= 1:variable
add-highlighter shared/shell/code/alias regex \balias(\h+[-+]\w)*\h+([\w-.]+)= 2:variable
add-highlighter shared/shell/code/function regex ^\h*(\S+(?<!=))\h*\(\) 1:function

add-highlighter shared/shell/code/unscoped_expansion regex (?<!\\)(?:\\\\)*\K\$(\w+|#|@|\?|\$|!|-|\*) 0:value
add-highlighter shared/shell/double_string/expansion regex (?<!\\)(?:\\\\)*\K\$(\w+|#|@|\?|\$|!|-|\*|\{.+?\}) 0:value

define-command -params 2 sh-new-in %{
    edit -scratch "%val{bufname}:"
    set-option buffer sh_fifo "%arg{1}"
    set-option buffer filetype dash
}

define-command -params 2 sh-cd %{
    rename-buffer %arg{1}
    set-option buffer path %arg{2}
    modeline
}

define-command -params 1 sh-z %{
    sh-send t %arg{1}
}
complete-command -menu sh-z shell-script-candidates %{ zoxide query --list }

§

define-command -params 1.. sh-sudo %{
    prompt -password 'Password:' %{
        reg f %opt{sh_fifo}
        edit -scratch '*sudo-password-tmp*'
        reg '"' "%val{text}"
        exec <a-P>
        nop %sh{
            if sudo -n true > /dev/null 2>&1; then
                sudo -n -- $@ > $kak_reg_f/out 2>&1
            else
            	printf 'exec %s\n' "'|sudo -S -- $@ > $kak_reg_f/out<ret>'" > $kak_command_fifo
            fi
        }
        delete-buffer! '*sudo-password-tmp*'
    }
}

# evaluate-commands %sh{
#     executables=$({ IFS=:; find -L /usr/bin/ /usr/local/bin/ $HOME/.local/bin/ -maxdepth 1 -type f -printf "%f\n" 2>/dev/null; } | sort | sed 's/[][\/.^$*+?()|{}]/\\&/g' | paste -sd "|")
#     printf 'add-highlighter shared/shellexe regex ^(?:%s)\\s 0:keyword\n' "$executables"
# }

# map global lsp l "!find -maxdepth 1 . "
map global lsp c ":sh-cd "
map global lsp z ":sh-z "

hook global WinSetOption filetype=shell %{
    require-module shell
    map window normal <ret> 'Z:eval -itersel %{mulsel sh-send}<ret>'
    map window insert <ret> '<esc>Zx:sh-send %reg{.}<ret>o'
    map window normal <a-ret> 'Z:mulsel sh-send<ret>jxGedo<esc>'
    map window insert <a-ret> '<esc>Zx:sh-send %reg{.}<ret>jxGedo<esc>'
    map window insert <s-ret> <ret>
    map window normal = '<a-i>w<a-Z>a'
    map window user l  ":sh-send ls<ret>"

    add-highlighter window/shell ref shell
    add-highlighter window/shellexe ref shellexe
    add-highlighter window/make ref make
}
