define-command -override surround-nest -params 2 %{
	evaluate-commands -draft -save-regs '"' %{
		set-register '"' %arg{1}
		execute-keys -draft P
		set-register '"' %arg{2}
		execute-keys -draft p
	}
}

define-command surround-sym %{
	on-key %{
		execute-keys -draft "i%val{key}<esc>a%val{key}"
	}
}

define-command surround-delete %{
	on-key %{
		execute-keys "<a-a>%val{key}i<del><esc>a<backspace><esc>" 
	}
}

define-command -override -hidden open-pair -params 1 %{
    try %{
        execute-keys -draft "<space>;<a-k>\s<ret>"
        execute-keys "%arg{1}<a-;>h"
    }
}

define-command -override -hidden close-pair -params 1 %{
	try %{
		execute-keys -draft "<space>;<a-k>\Q%arg{1}<ret>"
		execute-keys '<a-;>l'
	} catch %{
		execute-keys -with-hooks %arg{1}
	}
}

