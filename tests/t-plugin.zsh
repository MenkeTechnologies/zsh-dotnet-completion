#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: zsh-dotnet-completion full contract pins.
#####          The plugin is tiny but has 4 distinct surfaces:
#####          PATH augmentation, alias registration, compctl
#####          binding, and the `dotnet complete` callback. All
#####          four get pinned so a regression in any one of them
#####          surfaces in CI rather than during the user's repl.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-dotnet-completion.plugin.zsh"
}

@test 'plugin guards PATH augmentation on -d $HOME/.dotnet/tools (no-op on fresh hosts)' {
    # Pin: the if-guard ensures the plugin is silent on hosts without
    # dotnet installed. Without the guard, PATH would gain a phantom
    # entry pointing at a non-existent dir, which slows lookups.
    grep -q 'if \[\[ -d "$HOME/.dotnet/tools" \]\]' "$pluginFile"
    assert $? equals 0
}

@test 'plugin appends $HOME/.dotnet/tools to PATH (NOT prepends)' {
    # Pin: documented dotnet-tools install path is appended so it
    # never shadows /usr/local/bin or similar. If a refactor prepends,
    # system commands could be shadowed by stale dotnet-tools entries.
    grep -q 'export PATH="$PATH:$HOME/.dotnet/tools"' "$pluginFile"
    assert $? equals 0
}

@test 'plugin defines _dotnet_zsh_complete callback fn' {
    # Pin: this is the function compctl binds to. Renaming it
    # silently breaks tab completion for `dotnet`.
    grep -qE '^_dotnet_zsh_complete\(\) \{' "$pluginFile"
    assert $? equals 0
}

@test 'completion callback delegates to `dotnet complete "$words"` (the official tool)' {
    # Pin: `dotnet complete` is the OFFICIAL completion subcommand
    # — keeps the completion list current with whatever dotnet
    # version is installed. Replacing with a hardcoded list would
    # silently rot on every dotnet SDK update.
    grep -qF 'dotnet complete "$words"' "$pluginFile"
    assert $? equals 0
}

@test 'completion callback splits output on newlines into the reply array (compctl contract)' {
    # Pin: compctl -K expects $reply populated with candidates.
    # The newline-split parameter flag splits the multi-line
    # `dotnet complete` output. If it changes to space-split,
    # filenames with spaces would break.
    grep -qF 'reply=( "${(ps:\n:)completions}" )' "$pluginFile"
    assert $? equals 0
}

@test 'plugin binds the completion via compctl -K (NOT _arguments / compdef)' {
    # Pin: compctl is the OLD zsh completion API; _dotnet_zsh_complete
    # uses it because that's what `dotnet complete` returns plain-text
    # candidates for. A refactor to compdef would need a different
    # callback contract. Pin the binding shape so a half-refactor is caught.
    grep -qF 'compctl -K _dotnet_zsh_complete dotnet' "$pluginFile"
    assert $? equals 0
}

@test 'dt is dotnet test (NOT dotnet tool — that namespace overlap is real)' {
    # Pin: `dt` is the test runner. `dotnet tool list/install` is
    # a separate namespace; if a refactor renames dt to dotnet tool,
    # users lose test-running shortcut silently.
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        alias dt
    ")
    assert "$body" same_as "dt='dotnet test'"
}

@test 'dcl is dotnet clean (NOT dotnet cli — same namespace overlap risk)' {
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        alias dcl
    ")
    assert "$body" same_as "dcl='dotnet clean'"
}

@test 'dr is dotnet run (NOT dotnet restore — that is dotnet restore not dr)' {
    # Pin: `dr` is run. If a refactor maps dr -> restore (alphabetic
    # logic), every `dr` from muscle memory rebuilds dependencies
    # instead of running the app.
    local body
    body=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        alias dr
    ")
    assert "$body" same_as "dr='dotnet run'"
}

@test 'plugin registers EXACTLY 3 aliases (no scope creep)' {
    # Pin: dcl / dr / dt only. Adding more aliases needs a deliberate
    # PR; silent additions during a release bump would risk shadowing
    # other tools (e.g., `db` would shadow `db` for sqlite users).
    local count
    count=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        alias | grep -cE '^(dcl|dr|dt)='
    ")
    assert "$count" same_as '3'
}

@test 'plugin file is <= 20 lines (tiny plugin contract)' {
    # Pin: this is a focused dotnet bridge, not a kitchen-sink plugin.
    # Growth beyond 20 lines almost certainly means scope creep
    # belongs in a separate file.
    local lines
    lines=$(wc -l < "$pluginFile" | tr -d ' ')
    local result=$([[ "$lines" -le 20 ]] && echo yes || echo "no:$lines")
    assert "$result" same_as 'yes'
}

@test 'sourcing the plugin defines _dotnet_zsh_complete as a callable fn' {
    # End-to-end: source the plugin in a clean subshell, verify the
    # completion callback exists. Catches a syntax-clean-but-eval-
    # broken fn definition.
    local out
    out=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        typeset -f _dotnet_zsh_complete >/dev/null && print DEFINED || print MISSING
    ")
    assert "$out" same_as 'DEFINED'
}

@test 'compctl registration survives sourcing (binding is in place)' {
    # End-to-end: after source, `compctl -L` should show dotnet
    # bound to _dotnet_zsh_complete.
    local out
    out=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        compctl -L dotnet 2>/dev/null
    ")
    assert "$out" contains '_dotnet_zsh_complete'
}

@test 're-sourcing the plugin is idempotent (alias count stable)' {
    local first second
    first=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        alias | grep -cE '^(dcl|dr|dt)='
    ")
    second=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        source '$pluginFile' 2>/dev/null
        alias | grep -cE '^(dcl|dr|dt)='
    ")
    assert "$first" same_as "$second"
}

@test 'plugin sources cleanly on a host WITHOUT $HOME/.dotnet/tools (no-error path)' {
    # End-to-end: pretend HOME is a tmpdir with no .dotnet subtree.
    # Plugin must NOT error and MUST NOT augment PATH.
    local tmp
    tmp=$(mktemp -d)
    local result
    result=$(HOME="$tmp" zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        echo \$?
    ")
    rm -rf "$tmp"
    assert "$result" same_as '0'
}

@test 'plugin augments PATH on a host WITH $HOME/.dotnet/tools' {
    # End-to-end: create the dir in a tmpdir, source, verify PATH
    # gained the entry.
    local tmp
    tmp=$(mktemp -d)
    mkdir -p "$tmp/.dotnet/tools"
    local out
    out=$(HOME="$tmp" zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        echo \"\$PATH\"
    ")
    rm -rf "$tmp"
    assert "$out" contains "$tmp/.dotnet/tools"
}
