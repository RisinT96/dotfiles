if status is-interactive
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
