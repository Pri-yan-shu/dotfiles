define-command -override surround-nest -params 2 %{
  evaluate-commands -draft -save-regs '"' %{
    set-register '"' %arg{1}
    execute-keys -draft P
    set-register '"' %arg{2}
    execute-keys -draft p
  }
}

define-command -hidden surround-sym-sub -params 1 %{
    evaluate-commands -draft -save-regs '"' %{
        set-register '"' %arg{1}
        execute-keys -draft P
        set-register '"' %arg{1}
        execute-keys -draft p
    }
}

define-command surround-sym %{
  on-key %{
      surround-sym-sub %val{key}
  }
}

define-command -hidden surround-delete-sub -params 1 %{
  execute-keys -draft "<a-a>%arg{1}i<del><esc>a<backspace><esc>"
}

define-command surround-delete %{
  on-key %{
    surround-delete-sub %val{key}
  }
}
define-command surround-replace %{
  on-key %{
    surround-replace-sub %val{key}
  }
}

define-command -hidden surround-replace-sub -params 1 %{
  on-key %{
    evaluate-commands -no-hooks -draft %{
      execute-keys "<a-a>%arg{1}"

      # select the surrounding pair and add the new one around it
      enter-user-mode surround-nest
      execute-keys %val{key}
    }

    # delete the old one
    surround-delete-sub %arg{1}
  }
}
