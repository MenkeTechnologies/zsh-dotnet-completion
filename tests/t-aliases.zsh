#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: alias-presence pins for zsh-dotnet-completion.
#####          Registers 5 dotnet * aliases for `dotnet` CLI shortcuts.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
}

@test 'sourcing registers exactly 3 dotnet aliases (dcl dr dt)' {
    local count
    count=$(zsh -c "
        emulate zsh
        source '$pluginDir/zsh-dotnet-completion.plugin.zsh' 2>/dev/null
        alias | grep -cE '^(dcl|dr|dt)='
    ")
    assert "$count" equals '3'
}

@test 'dcl resolves to dotnet clean' {
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginDir/zsh-dotnet-completion.plugin.zsh' 2>/dev/null
        alias dcl
    ")
    assert "$body" contains 'dotnet clean'
}

@test 'dr resolves to dotnet run' {
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginDir/zsh-dotnet-completion.plugin.zsh' 2>/dev/null
        alias dr
    ")
    assert "$body" contains 'dotnet run'
}

@test 'plugin sourcing is idempotent' {
    local first second
    first=$(zsh -c "
        emulate zsh
        source '$pluginDir/zsh-dotnet-completion.plugin.zsh' 2>/dev/null
        alias | grep -cE '^(dcl|dr|dt)='
    ")
    second=$(zsh -c "
        emulate zsh
        source '$pluginDir/zsh-dotnet-completion.plugin.zsh' 2>/dev/null
        source '$pluginDir/zsh-dotnet-completion.plugin.zsh' 2>/dev/null
        alias | grep -cE '^(dcl|dr|dt)='
    ")
    assert "$first" equals "$second"
}
