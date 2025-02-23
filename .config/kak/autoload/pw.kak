declare-option int pw_module_id

define-command -params 1 pw-lm %{
	sh-send "load-module libpipewire-module-filter-chain filter.graph { nodes = [ { type = lv2 name = lv2 plugin = ""%arg{1}"" } ] }"
}

complete-command pw-lm shell-script-candidates %{ lv2ls }

define-command pw-getparams %{
	execute-keys %{!pw-dump $kak_opt_pw_module_id | jq -c '.[].info.params.Props[]'<ret>}
}

define-command -params 1 pw-setparams %{
		edit -scratch "pw.%arg{1}"
		set-option window pw_module_id %arg{1}
		set-option window filetype json
		pw-getparams
		map window user <c> "x!pw-cli set-param $kak_opt_pw_module_id Props $kak_selection >/dev/null <ret>"
}

define-command -params 2 pw-link %{
	evaluate-commands %sh{ pw-link -P $1 $2 }
}

define-command -params 2 pw-link-pair %{
	evaluate-commands %sh{
		pw-link -P $1_FL $2_FL
		pw-link -P $1_FR $2_FR
	}
}

complete-command -menu pw-link shell-script-candidates %{ [ $kak_token_to_complete -eq 0 ] && pw-link -i || pw-link -o }

