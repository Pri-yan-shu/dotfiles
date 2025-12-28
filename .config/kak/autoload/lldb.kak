declare-option line-specs lldb_flags

declare-user-mode lldb
map global lldb a ':sh-send process attach -p '
map global lldb A ':sh-send process attach -n '
map global lldb b ':sh-send breakpoint set --file %val{bufname} --line %val{cursor_line}<ret>'
map global lldb B ':sh-send breakpoint set --file %val{bufname} --line %val{cursor_line} --condition ''''<left>'
map global lldb c ':sh-send continue<ret>'
map global lldb d ':sh-send process detach<ret>'
map global lldb e ':sh-send expr %reg{.}<ret>'
map global lldb E ':sh-send settings remove target.env-vars '
map global lldb i ':sh-send settings set target.process.thread.step-avoid-regexp '
map global lldb I ':sh-send settings show target.process.thread.step-avoid-regexp<ret>'
map global lldb j ':sh-send kak jump<ret>'
map global lldb k ':sh-send process kill<ret>'
map global lldb K ':sh-send process signal '
map global lldb l ':sh-send process launch<ret>'
map global lldb L ':sh-send process launch --tty=/dev/pts/'
map global lldb q ':lldb-spawn lldb<ret>'
map global lldb Q ':lldb-despawn<ret>'
map global lldb s ':sh-send thread step-over<ret>'
map global lldb S ':sh-send thread step-in<ret>'
map global lldb <a-s> ':sh-send thread step-out<ret>'
map global lldb t ':sh-send target create <c-x>f'
map global lldb w '<a-i>w:sh-send watchpoint set variable %reg{.}<ret>'
map global lldb W ':sh-send watchpoint set expression %reg{.}<ret>'
map global lldb <a-w> ':sh-send watchpoint modify -c ''(%reg{.})''<left><left>'

declare-user-mode lldb-hook
map global lldb h ':enter-user-mode lldb-hook<ret>'
map global lldb-hook l ':sh-send target stop-hook list<ret>'
map global lldb-hook a ':sh-send target stop-hook add '
map global lldb-hook e ':sh-send target stop-hook enable '
map global lldb-hook d ':sh-send target stop-hook disable '
map global lldb-hook D ':sh-send target stop-hook delete '

hook global BufSetOption filetype=lldb-bp %{
    map buffer normal e 'xs^.*? <ret>:sh-send breakpoint enable %reg{.}<ret>'
    map buffer normal E 'xs^.*? <ret>:sh-send breakpoint disable %reg{.}<ret>'
    map buffer normal <a-e> 'xs^\d+.<ret>:sh-send breakpoint enable %reg{.}<ret>'
    map buffer normal <a-E> 'xs^\d+.<ret>:sh-send breakpoint disable %reg{.}<ret>'
    map buffer normal d 'xs^\d+<ret>:sh-send breakpoint delete %reg{.}<ret>'
    map buffer normal i 'xs^.*? <ret>:sh-send breakpoint modify -i %val{count} %reg{.}<ret>'
    map buffer normal o 'xs^.*? <ret>:sh-send breakpoint modify -o true %reg{.}<ret>'
    map buffer normal c 'xs^.*? <ret>:sh-send breakpoint command add %reg{.}'
    map buffer normal C 'xs^.*? <ret>:sh-send breakpoint command delete %reg{.}'
    map buffer normal s 'xs^.*? <ret>:sh-send breakpoint modify -c %reg{.}'
    map buffer normal r ':sh-send breakpoint read -f <c-x>f'
    map buffer normal w ':sh-send breakpoint write -f <c-x>f'
}

hook global BufSetOption filetype=lldb-wp %{
    map buffer normal a ':sh-send watchpoint set '
    map buffer normal e 'xs^\d+<ret>:sh-send watchpoint enable %reg{.}<ret>'
    map buffer normal E 'xs^\d+<ret>:sh-send watchpoint disable %reg{.}<ret>'
    map buffer normal d 'xs^\d+<ret>:sh-send watchpoint delete %reg{.}<ret>'
    map buffer normal i 'xs^\d+<ret>:sh-send watchpoint ignore -i %val{count} %reg{.}<ret>'
    map buffer normal w 'xs^\d+<ret>:sh-send watchpoint modify -c  %reg{.}<ret>'
    map buffer normal c ':sh-send watchpoint command add '
    map buffer normal C ':sh-send watchpoint command delete '
}

hook global BufSetOption filetype=lldb-threads %{
    map buffer normal <ret> ':sh-send thread select %val{cursor_line}<ret>'
    map buffer normal b ':sh-send thread backtrace -c %val{count} %reg{.}<ret>'
    map buffer normal c ':sh-send thread continue %reg{.}<ret>'
    map buffer normal i ':sh-send thread info %reg{.}<ret>'
    map buffer normal r ':sh-send thread return '
    map buffer normal s ':sh-send thread siginfo %reg{.}'
    map buffer normal u ':sh-send thread until -t %reg{.} -f %val{count}<ret>'
}

hook global BufSetOption filetype=lldb-trace %{
    map buffer normal <ret> ':sh-send frame select %sh{ echo $(($kak_cursor_line - 1)) }<ret>:addhl -override buffer/selframe line %val{cursor_line} ,rgb:333333<ret>'
    map buffer normal i ':sh-send frame info<ret>'
    map buffer normal v ':sh-send frame variable<ret>'
    map buffer normal V ':sh-send frame variable '
    hook buffer BufReload .* %{
        addhl -override buffer/selframe line 1 ,rgb:333333
    }
}

hook global BufSetOption filetype=lldb-frame %{
    map buffer normal w 'xs^\s*\K[^\s]+<ret>:sh-send watchpoint set variable %reg{.}<ret>'
    map buffer normal p 'xs^\s*\K[^\s]+<ret>:sh-send kak show_value %reg{.} %val{count}<ret>'
    map buffer normal s 'xs^\s*\K[^\s]+<ret>:sh-send expr <c-r>. = '
    map buffer normal d ':sh-send kak var_depth %val{count}<ret>'
    map buffer normal [ '' # array from ptr

    add-highlighter buffer/ regex ^\s*[^:]+ 0:variable
    add-highlighter buffer/ regex :\s*([^=]+?)(=|$) 1:type
    add-highlighter buffer/ regex =\s*(.*?)$ 1:value
}

define-command -params 1.. lldb-spawn %{
    sh-spawn %arg{@}
	rename-buffer lldb
	set-option global sh_fifo %opt{sh_fifo}

    edit "%opt{sh_fifo}/breakpoints"; set buffer filetype lldb-bp; set buffer autoreload yes; set buffer fs_check_timeout 100
    edit "%opt{sh_fifo}/watchpoints"; set buffer filetype lldb-wp; set buffer autoreload yes; set buffer fs_check_timeout 100
    edit "%opt{sh_fifo}/threads"; set buffer filetype lldb-threads; set buffer autoreload yes; set buffer fs_check_timeout 100
    edit "%opt{sh_fifo}/trace"; set buffer filetype lldb-trace; set buffer autoreload yes; set buffer fs_check_timeout 100
    edit "%opt{sh_fifo}/frame"; set buffer filetype lldb-frame; set buffer autoreload yes; set buffer fs_check_timeout 100

	add-highlighter global/lldb-flags flag-lines red lldb_flags
}

define-command lldb-despawn %{
    try %{db! "%opt{sh_fifo}/breakpoints"}
    try %{db! "%opt{sh_fifo}/watchpoints"}
    try %{db! "%opt{sh_fifo}/threads"}
    try %{db! "%opt{sh_fifo}/trace"}
    try %{db! "%opt{sh_fifo}/frame"}
    try %{db! "lldb"}

    remove-highlighter global/lldb-flags
}

