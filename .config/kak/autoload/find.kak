declare-option str-list find_marks
declare-option int find_depth 1

map global user l :find-buf<ret>

define-command find %{
    execute-keys "%%d!find -maxdepth %opt{find_depth} -printf '%%P\n' | sort<ret>ggd"
}

define-command find-buf %{
    edit -scratch *find*
    set-option buffer filetype find
    find
}

# symlinks

define-command find-enter %{
    evaluate-commands %sh{
        eval set -- "$kak_quoted_selections"

        case $(file -Lb --mime-type -- "$@") in
        inode/directory)
        	echo "cd $1"
    	;;
        application/vnd.microsoft.portable-executable)
            env -u DISPLAY ~/.local/wine/bin/wine "$@"
        ;;
        text/*)
        	printf "eval -try-client %%opt{jumpclient} %%{e $kak_selections}\n"
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
    	*)
        	xdg-open -- "$@" >/dev/null 2>&1 &
        ;;
        esac
    }
}

define-command find-chmod %{
    reg a %reg{.}
    execute-keys 'xs^[\w-]([\w-]{3})([\w-]{3})([\w-]{3})<ret>'
    nop %sh{
        chmod u=$kak_reg_1,g=$kak_reg_2,o=$kak_reg_3 "$kak_reg_a"
    }
}

define-command find-mark %{
    try %{
        # add-highlighter buffer/
    } catch %{
    }
    set-option -add buffer find_marks 
    hook -always -once buffer NormalKey <esc> %{
        unset-option buffer find_marks
        rmhl buffer/find_marks
    }
}

define-command find-move %{
    execute-keys -draft %{x_:reg a %reg{.}<ret>}
    execute-keys i
    hook -always -once -group find-move buffer InsertKey <esc> %{
        execute-keys x_
        nop %sh{
            dirname=$(dirname "$kak_selection")
            if ! [ -d $dirname ]
            then
            	if [ -e $dirname ]
            	then
            		exit
            	else
            		mkdir -p $dirname
            	fi
            fi


            mv "$kak_reg_a" "$kak_selection"
        }
        # remove-hooks buffer find-move
    }

    # hook -always -once -group find-move buffer InsertKey <esc> %{
    #     remove-hooks buffer find-move
    # }
}

hook global BufSetOption filetype=find %{
    # add-highlighter buffer/find-flags flag-lines red find_flags
    # map buffer normal p 'x_:find-chmod<ret>'
    map buffer normal c 'x_:find-rename<ret>'
    map buffer normal d 'x_:nop %sh{rm $kak_reg_dot}<ret>xd'
    map buffer normal <a-d> 'x_:nop %sh{rm -r $kak_reg_dot}<ret>xd'
    map buffer normal <ret> 'x_:find-enter<ret>'
    map buffer normal <s-ret> 'x_<a-!>find <c-r>. -maxdepth 1 -mindepth 1 -printf ''\n%p''<ret>;' # sort inserts ugly \n in end
    map buffer normal o ':prompt dir: %{nop %sh{mkdir $kak_text}; find}<ret>'
    map buffer normal i ':prompt file: %{nop %sh{touch $kak_text}; find}<ret>'
    map buffer normal f ':prompt file: %{nop %sh{mkfifo $kak_text}; find}<ret>'
    map buffer normal p 'x_y;I<c-x>f:nop %sh{cp }'
    map buffer normal x ':find-mark<ret>'
    map buffer normal l ':set-option buffer find_depth %val{count}<ret>:find<ret>'
    map buffer normal b ':cd ..<ret>'
    map buffer normal r ':find-move<ret>'
    map buffer goto h '<esc>:cd<ret>:find<ret>'
    map buffer goto r '<esc>:cd /<ret>:find<ret>'
    # define-command -override z -params 1 %{ cd %arg{1}; find }
    # complete-command z -menu shell-script-candidates %{ zoxide query -l }

    hook -always global EnterDirectory .* %{
        edit -scratch *find*
        find
    }

}

