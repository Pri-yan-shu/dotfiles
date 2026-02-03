declare-option int find_depth 1

define-command find %{
    execute-keys "%%d!find -maxdepth %opt{find_depth} -printf '%%P\n' | sort<ret>ggd"
}

define-command find-buf %{
    edit -scratch *find*
    set-option buffer filetype find
    find
}

define-command find-enter %{
    evaluate-commands %sh{
        eval set -- "$kak_quoted_selections"

        case $(file -Lb --mime-type -- "$@") in
        inode/directory)
        	printf "cd '$1'\n"
    	;;
        text/*)
        	printf "eval -try-client %%opt{jumpclient} %%{e $kak_quoted_selections; focus}\n"
        ;;
        image/*)
        	swayimg "$@" >/dev/null 2>&1 &
        ;;
        video/*)
        	mpv "$@" >/dev/null 2>&1 &
        ;;
        audio/*)
        	mpv "$@" >/dev/null 2>&1 &
        ;;
        application/pdf)
        	zathura "$@" >/dev/null 2>&1 &
        ;;
        application/x-pie-executable)
        	"$@" >/dev/null 2>&1 &
        ;;
        application/vnd.microsoft.portable-executable)
            env -u DISPLAY ~/.local/wine/bin/wine "$@"
        ;;
    	*)
        	xdg-open -- "$@" >/dev/null 2>&1 &
        ;;
        esac
    }
}

define-command find-chmod %{
    reg f %reg{.}
    prompt -init %sh{stat $kak_selection --format %a} permissions: %{
        nop %sh{
            chmod $kak_text "$kak_selection"
        }
    }
}

define-command -params 2..3 find-cmd %{
    prompt -file-completion %arg{1} %{
        nop %sh{ $2 -- "$3" $kak_text || printf "fail command failed:$?" }
        find
    }
}

define-command -params 1 find-mv %{
    nop %sh{
        mv -- $kak_quoted_selections $1 || printf "mv failed: $?"
        find
    }
}

complete-command find-mv file

hook global BufSetOption filetype=find %{
    map buffer normal D 'x_:nop %sh{rm -- $kak_selections}<ret>:find<ret>'
    map buffer normal <a-d> 'x_:nop %sh{rm -r -- $kak_selections}<ret>:find<ret>'
    map buffer normal <ret> 'x_:find-enter<ret>'
    map buffer normal <s-ret> 'x_<a-!>find "$kak_selection" -maxdepth 1 -mindepth 1 -printf ''\n%p''<ret>;' # sort inserts ugly \n in end
    map buffer normal o ':find-cmd dir: "mkdir -p"<ret>'
    map buffer normal i ':find-cmd file: touch<ret>'
    map buffer normal f ':find-cmd fifo: mkfifo<ret>'
    map buffer normal p 'x_:find-cmd copy: cp<ret>'
    map buffer normal s 'x_:find-cmd link: "ln -s" $PWD/$kak_selection<ret>'
    map buffer normal c 'x_:find-mv '
    # map buffer normal c 'x_:find-cmd move: mv "%val{selections}"<ret>'
    map buffer normal L 'x_:echo "%sh{ls -l $kak_selection}"<ret>'
    map buffer normal x 'x_<a-z>aZ,;'
    map buffer normal l ':set-option buffer find_depth %sh{printf $(($kak_count + 1))}<ret>:find<ret>'
    map buffer normal b ':cd ..<ret>'
    map buffer normal m 'x_:find-chmod<ret>'
    map buffer goto h '<esc>:cd<ret>:find<ret>'
    map buffer goto r '<esc>:cd /<ret>:find<ret>'

    hook -always global EnterDirectory .* %{
        edit -scratch *find*
        find
    }

}

