define-command -hidden modeline %{
    set-option buffer modelinefmt %sh{
        eval set -- "$kak_quoted_buflist"
        [ "$kak_bufname" = "*debug*" ] || shift
    	[ $kak_modified = "true" ] && modified='+u'
        for buffer in "$@"; do
        	if [ "$buffer" = "$kak_bufname" ]; then
        		modeline="$modeline{$modified@PrimarySelection} ${buffer##*/} {StatusLine}"
       		else
        		modeline="$modeline ${buffer##*/} "
       		fi
        done
        printf "$modeline{StatusLineMode} %%val{session} "
    }
}

hook -always global WinDisplay .* mod
hook -always global BufWritePost .* mod
hook -always global FocusIn .* %{ set-face window StatusLineMode PrimarySelection }
hook -always global FocusOut .* %{ set-face window StatusLineMode StatusLine }

define-command reset-debug %{
    echo -debug ''
    arrange-buffers *debug*
}

define-command -hidden mod %{
    set-option buffer modelinefmt %sh{
    	[ $kak_modified = "true" ] && modified='+u'

    	stripped_bef=${kak_quoted_buflist%%"$kak_quoted_bufname"*}
        eval set -- "$stripped_bef"
        [ "$1" = '*debug*' ] && shift || printf 'reset-debug\n' > $kak_command_fifo
        for buffer in "$@"; do
        	before_mod="$before_mod ${buffer##*/} "
        done

        before_len=$(($kak_window_width / 2))
        [ ${#before_mod} -lt $before_len ] && before_len=${#before_mod}

        after_len=$(($kak_window_width - $before_len - ${#kak_session}))

    	stripped_aft=${kak_quoted_buflist##*"$kak_quoted_bufname"}
        eval set -- "$stripped_aft"
        for buffer in "$@"; do
        	after_mod="$after_mod ${buffer##*/} "
        	[ ${#after_mod} -gt $after_len ] && break
        done

        printf "$before_mod{$modified@PrimarySelection} ${kak_bufname##*/} {StatusLine}$after_mod{StatusLineMode} %%val{session}"
    }
}
