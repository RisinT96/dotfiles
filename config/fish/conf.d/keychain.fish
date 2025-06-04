if status is-interactive
    if type -q keychain
        keychain --nogui $HOME/.ssh/id_ed25519
        source $HOME/.keychain/(hostname)-fish
    end
end
