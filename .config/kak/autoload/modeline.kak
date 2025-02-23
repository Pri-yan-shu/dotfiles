declare-option bool focused true
define-command -hidden update-modeline %{ evaluate-commands %sh{
	[ $kak_modified = "true"  ] && selcolor="{cyan,default}{black,cyan+b}" || selcolor="{green,default}{black,green+b}"
	[ $kak_opt_focused = "true" ] && servercol="cyan" || servercol="bright-black"
	modeline=$(printf "$kak_buflist" | sed "s/\*debug\*//g; s|$kak_bufname|$selcolor${kak_bufname##*/}{bright-white,black}|g; s|[^ ]*/\([^ ]\+\)|\1|g")
	printf "set-option window modelinefmt '%s'" "$modeline {{mode_info}}{$servercol}{$servercol+rb}%val{session}"
}}

hook -always global WinDisplay .* %{ update-modeline }
hook -always global BufWritePost .* %{ update-modeline }
hook -always global FocusIn .* %{ set-option window focused true ; update-modeline }
hook -always global FocusOut .* %{ set-option window focused false ; update-modeline }

# define-command -hidden update-modeline %{
# 	evaluate-commands %sh{
# 		focus_file=${kak_buffile##*/}
# 		[ $kak_modified = "true"  ] && selcolor="green" || selcolor="cyan"
# 		eval "set -- $kak_quoted_buflist"
# 		
# 		while [ "$1" ]; do
# 			buf=${1##*/}
# 			# buf=$(basename "$1")
# 			if [ "$buf" = "*debug*" ]; then
# 				shift
# 				continue
# 			elif [ "$buf" = "$focus_file" ]; then
# 				buflist="${buflist}{$selcolor,default}{black,$selcolor}$buf{bright-white,black}"
# 			else
# 				buflist="${buflist} $buf "
# 			fi
# 			shift
# 		done
# 		
# 		printf "set-option window modelinefmt '%s'" "$buflist{{mode_info}}{cyan}{cyan+r}%val{session}"
# 	}
# }

