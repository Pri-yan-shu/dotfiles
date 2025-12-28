add-highlighter global/ show-matching

require-module dwl
set-option global termcmd "footclientappid sh -c"

declare-user-mode useruser
declare-user-mode edit
declare-user-mode snippets
declare-user-mode rg
declare-user-mode shell
# declare-user-mode j
# declare-user-mode regx

hook global BufSetOption filetype=(man|markdown|shell|make) %{ add-highlighter buffer/wrap wrap -word }
hook global BufCreate .*\.smd %{ set-option buffer filetype markdown }

hook -once global BufCreate .* %{
    rename-buffer *find*
    set-option buffer filetype find
    find
}

hook global KakBegin .* %{ set global jumpclient client0 }
hook global FocusIn .* %{ echo -to-file /tmp/kakfocus "%val{session} %val{client} %val{client_env_APPID}" }
hook global ClientCreate .* %{ echo -to-file /tmp/kakfocus "%val{session} %val{hook_param} %val{client_env_APPID}" }
hook global ClientRenamed .* %{ echo -to-file /tmp/kakfocus "%val{session} %val{client} %val{client_env_APPID}" }
hook global SessionRenamed .* %{ echo -to-file /tmp/kakfocus "%val{session} %val{client} %val{client_env_APPID}" }

hook global WinSetOption filetype=(c|cpp|zig|java|kotlin) %{
    hook window -group semantic-tokens BufReload .* lsp-semantic-tokens
    hook window -group semantic-tokens NormalIdle .* lsp-semantic-tokens
    hook window -group semantic-tokens InsertIdle .* lsp-semantic-tokens
    hook -once -always window WinSetOption filetype=.* %{
        remove-hooks window semantic-tokens
    }
}

hook global ModeChange .*:.*:insert %{
    set-face window PrimaryCursor InsertCursor
    set-face window PrimaryCursorEol InsertCursor
}

hook global ModeChange .*:insert:.* %{ try %{
    unset-face window PrimaryCursor
    unset-face window PrimaryCursorEol
}}

hook global ModeChange .*:normal:next-key.* %{
    set-face window PrimaryCursor NormalModeCursor
    set-face window PrimaryCursorEol NormalModeCursor
}

hook global ModeChange .*:next-key.*:normal %{ try %{
    unset-face window PrimaryCursor
    unset-face window PrimaryCursorEol
}}

hook global BufSetOption filetype=markdown %{
    set-option buffer formatcmd 'pandoc -f commonmark -t commonmark'
}

hook global BufSetOption filetype=(grep|lsp-goto) %{
	hook buffer -group mouse NormalKey <mouse:press:left:.*> jump
    hook -once -always window WinSetOption filetype=.* %{ remove-hooks buffer mouse }
}

hook global BufSetOption filetype=(?:c|cpp) %{
    set-option buffer formatcmd 'clang-format --style=Microsoft'
    set-option -add buffer snippets 'class'    '' %{ snippets-insert %{} }
    set-option -add buffer snippets 'define'   '' %{ snippets-insert %{#define } }
    set-option -add buffer snippets 'function' '' %{ snippets-insert %{} }
    set-option -add buffer snippets 'if'       '' %{ snippets-insert %{if (${}) {$n	${}$n}} }
    set-option -add buffer snippets 'include'  '' %{ snippets-insert %{#include ${}} }
    set-option -add buffer snippets 'for'      '' %{ snippets-insert %{for (int ${i} = 0; i < ${}; i++) {$n}} }
    set-option -add buffer snippets 'forr'     '' %{ snippets-insert %{for (int ${i} = ${}; i > 0; i--) {$n}} }
    set-option -add buffer snippets 'struct'   '' %{ snippets-insert %{} }
    set-option -add buffer snippets 'switch'   '' %{ snippets-insert %{switch (${}) {$n	case ${}: ${};$n		break;$n}} }
    # set-option -add buffer snippets 'test'     '' %{ snippets-insert %{} }
    set-option -add buffer snippets 'while'    '' %{ snippets-insert %{while (${}) {$n}} }
    set-option -add buffer snippets 'print'    '' %{ snippets-insert %{fprintf(stderr, "%s:%d:%s: ${}\n", __FILE__, __LINE__, __func__${});}}
}

hook global BufSetOption filetype=zig %{
    set-option buffer formatcmd 'zig fmt --stdin'
    set-option buffer makecmd 'zig build'
    # set-option -add buffer snippets 'class'    '' %{ snippets-insert %{} }
    set-option -add buffer snippets 'else'     '' %{ snippets-insert %{else {$n	${}$n}} }
    set-option -add buffer snippets 'function' '' %{ snippets-insert %{fn ${}(${}) ${} {$n	${}$n}} }
    set-option -add buffer snippets 'if'       '' %{ snippets-insert %{if (${}) {$n${}$n}} }
    set-option -add buffer snippets 'ifelse'   '' %{ snippets-insert %{if (${}) |${}| {$n	${}$n} else |${}| {$n	${}$n}} }
    set-option -add buffer snippets 'include'  '' %{ snippets-insert %{const ${} = @import("${}");} }
    set-option -add buffer snippets 'for'      '' %{ snippets-insert %{for (${}) |${}| {$n}} }
    set-option -add buffer snippets 'forr'     '' %{ snippets-insert %{for (${}, 0..) |${}, ${i}| {$n}} }
    set-option -add buffer snippets 'struct'   '' %{ snippets-insert %{const ${} = struct {$n};} }
    set-option -add buffer snippets 'switch'   '' %{ snippets-insert %{switch (${}) {$n	${} => ${},$n	${} => ${}$n};} }
    set-option -add buffer snippets 'test'     '' %{ snippets-insert %{test "${}" {$n}} }
    set-option -add buffer snippets 'while'    '' %{ snippets-insert %{while (${}) {$n}} }
    set-option -add buffer snippets 'print'    '' %{ snippets-insert %{std.debug.print("${}", .{ ${} });}}
}

hook global BufSetOption filetype=rust %{
    ctags-enable-autocomplete
    set-option buffer formatcmd 'rustfmt --emit stdout'
    set-option buffer makecmd 'cargo build'
    # set-option -add buffer snippets 'class'    '' %{ snippets-insert %{} }
    set-option -add buffer snippets 'else'     '' %{ snippets-insert %{else {$n	${}$n}} }
    set-option -add buffer snippets 'function' '' %{ snippets-insert %{fn ${}(${}) ${} {$n	${}$n}} }
    set-option -add buffer snippets 'if'       '' %{ snippets-insert %{if (${}) {$n${}$n}} }
    set-option -add buffer snippets 'ifelse'   '' %{ snippets-insert %{if (${}) {$n	${}$n} else {$n	${}$n}} }
    set-option -add buffer snippets 'include'  '' %{ snippets-insert %{const ${} = @import("${}");} }
    set-option -add buffer snippets 'for'      '' %{ snippets-insert %{for (${}) {$n}} }
    set-option -add buffer snippets 'forr'     '' %{ snippets-insert %{for (${}, 0..) |${}, ${i}| {$n}} }
    set-option -add buffer snippets 'struct'   '' %{ snippets-insert %{const ${} = struct {$n};} }
    set-option -add buffer snippets 'switch'   '' %{ snippets-insert %{switch (${}) {$n	${} => ${},$n	${} => ${}$n};} }
    set-option -add buffer snippets 'test'     '' %{ snippets-insert %{test "${}" {$n}} }
    set-option -add buffer snippets 'while'    '' %{ snippets-insert %{while (${}) {$n}} }
    set-option -add buffer snippets 'print'    '' %{ snippets-insert %{std.debug.print("${}", .{ ${} });}}
}

hook global BufSetOption filetype=java %{
    set-option buffer formatcmd 'clang-format'
    set-option -add buffer snippets 'class'    '' %{ snippets-insert %{} }
    # set-option -add buffer snippets 'define'   '' %{ snippets-insert %{#define } }
    set-option -add buffer snippets 'function' '' %{ snippets-insert %{} }
    set-option -add buffer snippets 'if'       '' %{ snippets-insert %{if (${}) {$n	${}$n}} }
    # set-option -add buffer snippets 'include'  '' %{ snippets-insert %{#include ${}} }
    set-option -add buffer snippets 'for'      '' %{ snippets-insert %{for (int ${i} = 0; i < ${}; i++) {$n}} }
    set-option -add buffer snippets 'forr'     '' %{ snippets-insert %{for (int ${i} = ${}; i > 0; i--) {$n}} }
    set-option -add buffer snippets 'struct'   '' %{ snippets-insert %{} }
    set-option -add buffer snippets 'switch'   '' %{ snippets-insert %{switch (${}) {$n	case ${}: ${};$n		break;$n}} }
    # set-option -add buffer snippets 'test'     '' %{ snippets-insert %{} }
    set-option -add buffer snippets 'while'    '' %{ snippets-insert %{while (${}) {$n}} }
    set-option -add buffer snippets 'print'    '' %{ snippets-insert %{fprintf(stderr, "%s:%d:%s: ${}\n", __FILE__, __LINE__, __func__${});}}
}

autorestore-disable
