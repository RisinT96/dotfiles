if status is-interactive
    if type -q fzf
        fzf_configure_bindings \
            --directory=\ct \
            --git_log=\eL \
            --git_status=\eS \
            --history=\cr \
            --processes=\eP \
            --variables=\cv
    end
end

if test -e "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end
