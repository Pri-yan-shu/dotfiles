map global goto s '<esc>:git status -bs --porcelain<ret>' -docstring 'git status'
map global goto l '<esc>:git log --oneline --graph<ret>'
map global goto L '<esc>:git log --oneline --graph -- <c-x>f'
# map global goto o '<esc>:git log --oneline --graph -- <c-x>f'
map global goto / '<esc>:git log -S %val{selections}<a-!><home>'
map global goto c '<esc>:git commit --verbose '
map global goto b '<esc>:git blame<ret>'
map global goto B '<esc>:git show-branch<ret>'
map global goto c '<esc>:git checkout<ret>'
map global goto d '<esc>:git diff '
map global goto ) '<esc>:git next-hunk<ret>'
map global goto ( '<esc>:git prev-hunk<ret>'
# map global goto S '<esc>:'

hook global WinSetOption filetype=git-status %{
	map window normal d 'xs[^\s]+$<ret>:-- %val{selections}<a-!><home> git diff '
	map window normal D 'xs[^\s]+$<ret>:-- %val{selections}<a-!><home> git diff --cached '
	map window normal a 'xs[^\s]+$<ret>:-- %val{selections}<a-!><home> git add '
	map window normal A 'xs[^\s]+$<ret>:-- %val{selections}<a-!><home> terminal git add -p '
	map window normal r 'xs[^\s]+$<ret>:-- %val{selections}<a-!><home> git reset '
	map window normal R 'xs[^\s]+$<ret>:-- %val{selections}<a-!><home> terminal git reset -p '
	map window normal o 'xs[^\s]+$<ret>:-- %val{selections}<a-!><home> git checkout '
	map window normal l 'xs[^\s]+$<ret>:-- %val{selections}<a-!><home> git log --oneline --graph '
}

define-command git-diff-add %{
    reg f %sh{ mktemp -t XXXXXX }
    write %reg{f}
    git add %reg{f}
}

hook global WinSetOption filetype=git-diff %{
    map window normal o '/^@@.*?@@.*?^(?=@@)<ret>'
    map window normal <ret> 'd%s^@@.*?@@.*?^(?=@@)<ret><a-d>p'
    map window object h '^@@.*?@@.*?^(?:(?=@@)|(?=$))'
    map window normal a ''
}

hook global WinSetOption filetype=git-log %{
	map window normal d 'xs^.*?\K\w+<ret>:%val{selections}<a-!><home>git diff '
	map window normal r 'xs^.*?\K\w+<ret>:%val{selections}<a-!><home>git reset '
	map window normal R 'xs^.*?\K\w+<ret>:%val{selections}<a-!><home>terminal git reset -p '
	map window normal o 'xs^.*?\K\w+<ret>:%val{selections}<a-!><home>git checkout '
    map window normal s 'xs^.*?\K\w+<ret>:%val{selections}<a-!><home>git show '
	map window normal l ':git log --oneline --graph -- <c-x>f'
	# map window normal <ret>  m
}

hook global WinSetOption filetype=git-.* %{
	map window normal <a-d> ':git diff<ret>'
	map window normal <a-D> ':git diff --cached<ret>'
	map window normal c ':git commit --verbose '
    map window normal <quote> ':rename-buffer "*%opt{filetype}*"<ret>'
}

