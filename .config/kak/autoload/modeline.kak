define-command -hidden modeline %{ evaluate-commands %sh{
    eval set -- "$kak_quoted_buflist"
    for word in "$@"; do
    	[ "$word" = '*debug*' ] && [ "$kak_buffile" != '*debug*' ] && continue
    	[ $kak_modified = "true" ] && modified='+u'
    	base=${word##*/}
    	case "$kak_buffile" in
    		*"${word#~*}")
        		modeline="$modeline{$modified@PrimarySelection} ${word##*/} {StatusLine}"
        		selected_in=true
        		;;
    		*)
        		modeline="$modeline $base "
        		;;
    	esac
    	count=$(($count + ${#base} + 2))
    	[ $count -gt $kak_window_width ] && [ -n "$selected_in" ] && break
    done
    printf "set-option window modelinefmt '%s'" "$modeline {StatusLine}%val{session}"
}}

hook -always global WinDisplay .*   modeline
hook -always global BufWritePost .* modeline
