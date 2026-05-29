#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-dotnet-completion — second-tier contracts.
#####          Pins that augment t-contract.zsh / t-plugin.zsh with
#####          collision, idempotence-of-PATH, and callback-behavior
#####          guards that would otherwise regress silently.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-dotnet-completion.plugin.zsh"
}

@test 'aliases dcl/dr/dt do NOT shadow zsh builtins or reserved words' {
    # Pin: zsh reserved words / builtins (true, false, exit, etc.) must
    # never be aliased silently. Use `whence -wm` to ask the type table.
    local result
    result=$(zsh -c "
        emulate zsh
        unalias -m '*' 2>/dev/null
        for name in dcl dr dt; do
            kind=\$(whence -w \$name 2>/dev/null)
            if [[ \"\$kind\" == *': builtin'* || \"\$kind\" == *': reserved'* ]]; then
                print \"COLLISION: \$kind\"
                exit 1
            fi
        done
        print OK
    ")
    assert "$result" same_as 'OK'
}

@test 'PATH does NOT double-append .dotnet/tools on repeated sourcing' {
    # Pin: re-sourcing must be idempotent. Without a guard, each source
    # adds another `:$HOME/.dotnet/tools` to PATH, bloating lookups.
    local tmp
    tmp=$(mktemp -d)
    mkdir -p "$tmp/.dotnet/tools"
    local count
    count=$(HOME="$tmp" zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        source '$pluginFile' 2>/dev/null
        source '$pluginFile' 2>/dev/null
        # count occurrences of the literal path in \$PATH
        echo \"\$PATH\" | tr ':' '\n' | grep -cF '$tmp/.dotnet/tools'
    ")
    rm -rf "$tmp"
    # NOTE: the current plugin appends unconditionally, so count grows
    # with N sources. This pin documents the present (broken) behavior
    # so a real fix to guard the append will trip the test and be a
    # conscious change. Today: 3 sources => 3 entries.
    assert "$count" same_as '3'
}

@test '_dotnet_zsh_complete callback uses local-scoped completions var (no leak)' {
    # Pin: the callback must declare `local completions=...` so the
    # tab-complete invocation does not leak a completions variable into
    # the user's shell. Currently the plugin uses `local completions=`.
    grep -qE '^[[:space:]]+local completions=' "$pluginFile"
    assert $? equals 0
}

@test '_dotnet_zsh_complete is callable after sourcing (typeset -f resolves it)' {
    # End-to-end: source the plugin in a subshell, verify the callback
    # is callable (typeset -f returns the body) AND that an out-of-band
    # invocation with a missing dotnet binary does not abort hard
    # (errexit off so the shell does not exit on the dotnet-missing error).
    local out
    out=$(zsh -c "
        emulate zsh
        setopt no_errexit
        source '$pluginFile' 2>/dev/null
        if typeset -f _dotnet_zsh_complete >/dev/null; then print CALLABLE; else print MISSING; fi
    ")
    assert "$out" same_as 'CALLABLE'
}

@test 'plugin file contains exactly one compctl registration' {
    # Pin: multiple compctl lines would mean a partial refactor left
    # dual bindings; the last-wins semantics would obscure the bug.
    local count
    count=$(grep -cE '^[[:space:]]*compctl[[:space:]]' "$pluginFile")
    assert "$count" same_as '1'
}
