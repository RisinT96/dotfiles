if status is-interactive
    if type -q fzf
        # do stuff
        fzf_configure_bindings \
            --directory=\ct \
            --git_log=\eL \
            --git_status=\eS \
            --history=\cr \
            --processes=\eP \
            --variables=\cv

        function fzf --wraps=fzf --description="Use fzf-tmux if in tmux session"
            if set --query TMUX
                fzf-tmux $argv
            else
                command fzf $argv
            end
        end
    end

    if type -q zoxide
        zoxide init fish | source
    end
end

if test -e "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end
