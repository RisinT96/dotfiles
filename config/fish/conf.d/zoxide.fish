if status is-interactive
    if type -q zoxide
        zoxide init fish --cmd cd | source
    end
end
