declare-option str sh_fifo
declare-option str sh_pwd
declare-option str sh_pid
declare-option str-list sh_exe

define-command -params 1.. sh-spawn %{
    nop %sh{
        export kak_session
        export kak_client
        export TERM=dumb
        export sh_fifo=$(mktemp -d "${TMPDIR:-/tmp}"/sh.XXXX)

        mkfifo $sh_fifo/in $sh_fifo/out

        exec 3<>$sh_fifo/in

        setsid $@ >$sh_fifo/out <$sh_fifo/in 2>&1 &

        printf "edit -fifo $sh_fifo/out -scroll $!
                set-option buffer sh_pid $!
                set-option buffer sh_fifo $sh_fifo
                " > $kak_command_fifo
    }

    hook -once -always buffer BufCloseFifo .* %{
        evaluate-commands %sh{
            echo "echo -debug sh_fifo: $kak_opt_sh_fifo sh_pid: $kak_opt_sh_pid"
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

define-command -params 1 sh-cd %{
    set-option buffer path %sh{ realpath -e $kak_opt_sh_pwd/$1 }
    set-option buffer sh_pwd %opt{path}
    sh-send cd ""%opt{path}""
    rename-buffer "$%sh{basename ""$1""}"
    modeline
}

complete-command -menu sh-cd shell-script-candidates %{ ls $kak_opt_sh_pwd }

define-command -params 1 sh-z %{
    sh-send "cd '%arg{1}'"
    rename-buffer "$%sh{basename ""$1""}"
    set-option buffer path %arg{1}
    set-option buffer sh_pwd %arg{1}
    modeline
}
complete-command -menu sh-z shell-script-candidates %{ zoxide query --list }

§

evaluate-commands %sh{
    executables=$({ IFS=:; find -L /usr/bin/ /usr/local/bin/ $HOME/.local/bin/ -maxdepth 1 -type f -printf "%f\n" 2>/dev/null; } | sort | sed 's/[][\/.^$*+?()|{}]/\\&/g' | paste -sd "|")
    printf 'add-highlighter shared/shellexe regex (^|\\s)(?:%s)\\s 0:keyword\n' "$executables"
}

map global lsp l "!find -maxdepth 1 . "
map global lsp c ":sh-cd "
map global lsp z ":sh-z "
map global lsp n ":sh-send nnn -e"

hook global WinSetOption filetype=shell %{
    require-module shell
    map window normal V '<a-i><a-w>:enter-user-mode sh-plumb<ret>'
    map window normal <ret> 'Z:eval -itersel %{mulsel sh-send}<ret>'
    map window insert <ret> '<esc>Zx:sh-send %reg{.}<ret>o'
    map window normal <a-ret> 'Z:mulsel sh-send<ret>jxGedo<esc>'
    map window insert <a-ret> '<esc>Zx:sh-send %reg{.}<ret>jxGedo<esc>'
    map window insert <c-ret> <ret>
    map window normal = '<a-i>w<a-Z>a'
    map window user l  ":sh-send ls<ret>"

    add-highlighter window/shell ref shell
    add-highlighter window/shellexe ref shellexe
    add-highlighter window/make ref make
}
