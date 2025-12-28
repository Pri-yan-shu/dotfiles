provide-module snippets ''
require-module snippets

declare-option str-list snippets

define-command snippets-impl -hidden -params 1.. %{
    eval %sh{
        use=$1
        shift 1
        index=4
        while [ $# -ne 0 ]; do
            if [ "$1" = "$use" ]; then
                printf "eval %%arg{%s}" "$index"
                exit
            fi
            index=$((index + 3))
            shift 3
        done
        printf "fail 'Snippet not found'"
    }
}

define-command snippets -params 1 -shell-script-candidates %{
    eval set -- "$kak_quoted_opt_snippets"
    if [ $(($#%3)) -ne 0 ]; then exit; fi
    while [ $# -ne 0 ]; do
        printf '%s\n' "$1"
        shift 3
    done
} %{
    snippets-impl %arg{1} %opt{snippets}
}

define-command snippets-insert -hidden -params 1 %<
    eval -save-regs 's' %<
        eval -draft -save-regs '"' %<
            # paste the snippet
            reg dquote %arg{1}
            exec P

            # replace $n with newlines
            eval -draft -verbatim try %<
                # select $n and $$ (to avoid transforming escaped $)
                exec 's\$\$|\$n<ret><a-k>\$n<ret>c
<esc>'
            >

            # replace leading tabs with the appropriate indent
            try %<
                reg dquote %sh<
                    if [ $kak_opt_indentwidth -eq 0 ]; then
                        printf '\t'
                    else
                        printf "%${kak_opt_indentwidth}s"
                    fi
                >
                exec -draft '<a-s>s\A\t+<ret>s.<ret>R'
            >

            # align everything with the current line
            eval -draft -itersel -save-regs '"' %<
                try %<
                    exec -draft -save-regs '/' '<a-s>),xs^\s+<ret>y'
                    exec -draft '<a-s>)<a-,>P'
                >
            >

            reg s %val{selections_desc}
            # process placeholders
            try %<
                # select all placeholders ${..} and  escaped-$ (== $$)
                exec 's\$\$|\$\{(\}\}|[^}])*\}<ret>'
                # nonsense test text to check the regex
                # qwldqwld {qldwlqwld} qlwdl$qwld {qwdlqwld}}qwdlqwldl}
                # lqlwdl$qwldlqwdl$qwdlqwld {qwd$$lqwld} $qwdlqwld$
                # ${asd.as.d.} lqwdlqwld $$${as.dqdqw}

                # remove one $ from all $$, and leading $ from ${..}
                exec -draft '<a-:><a-;>;d'
                # unselect the $
                exec '<a-K>\A\$\z<ret>'
                # we're left with only {..} placeholders, process them...
                eval reg dquote %sh<
                    eval set -- "$kak_quoted_selections"
                    for sel do
                        # remove trailing }
                        sel="${sel%\}}"
                        # and leading {
                        sel="${sel#{}"
                        # de-double }}
                        tmp="$sel"
                        sel=""
                        while true; do
                            case "$tmp" in
                                *}}*)
                                    sel="${sel}${tmp%%\}\}*}}"
                                    tmp=${tmp#*\}\}}
                                    ;;
                                *)
                                    sel="${sel}${tmp}"
                                    break
                                    ;;
                            esac
                        done
                        # and quote the result in '..', with escaping (== doubling of ')
                        tmp="$sel"
                        sel=""
                        while true; do
                            case "$tmp" in
                                *\'*)
                                    sel="${sel}${tmp%%\'*}''"
                                    tmp=${tmp#*\'}
                                    ;;
                                *)
                                    sel="${sel}${tmp}"
                                    break
                                    ;;
                            esac
                        done
                        # all done, print it
                        # nothing like some good old posix-shell text processing
                        printf "'%s' " "$sel"
                    done
                >
                exec R
                reg s %val{selections_desc}
            >
        >
        try %{ select %reg{s} }
    >
>

