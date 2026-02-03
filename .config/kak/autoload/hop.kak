declare-option -hidden str hop_pairs
declare-option -hidden range-specs hop_ranges

set-option global hop_pairs %sh{
    echo 'tnseriaodhfuwykvplgmc,x.' | awk '{
        for (i = 1; i <= length($0); i++)
            for (j = 1; j <= length($0); j++)
                printf "%s%s ", substr($0, i, 1), substr($0, j, 1); print "" }'
}

add-highlighter global/hop-ranges replace-ranges hop_ranges

define-command hop %{
    set-face window PrimaryCursor default,default
    set-face window SecondaryCursor default,default
    set-face window PrimarySelection default,default
    set-face window SecondarySelection default,default

    execute-keys s\w{2,}<ret>

    evaluate-commands %sh{
        eval set -- "$kak_opt_hop_pairs"
        for range in $kak_selections_desc; do
        	ranges="$ranges${range%%,*}+2|{hop_face}$1 "
        	shift
        done
        echo "set-option window hop_ranges %val{timestamp} $ranges"
    }

    on-key %{
        set-register t %val{key}
        on-key %{
            evaluate-commands %sh{
                for range in $kak_opt_hop_ranges; do
                	case $range in
                		*$kak_reg_t$kak_key) selection=${range%%[,+]*}
                			break;;
                	esac
                done

                if [ -z "$selection" ]; then
                	echo 'execute-keys z'
                	exit
                fi

                for range in $kak_selections_desc; do
                	case $range in
                		$selection,*) break;;
                	esac
                done

                echo "select $range"
            }
            unset-option window hop_ranges
            unset-face window PrimarySelection
            unset-face window SecondarySelection
            unset-face window PrimaryCursor
            unset-face window SecondaryCursor
        }
    }
}

