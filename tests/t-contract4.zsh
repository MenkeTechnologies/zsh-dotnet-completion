#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-dotnet-completion — fourth-tier contracts.
#####          Pins for dotnet-specific surfaces: callback dispatch
#####          flows `$words` to `dotnet complete`, alias targets
#####          are all `dotnet`-prefixed (workload/tool semantics live
#####          inside `dotnet complete`, not in the plugin), and
#####          callback never accidentally invokes a non-dotnet tool.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-dotnet-completion.plugin.zsh"
}

@test 'callback delegates to `dotnet complete` (not `dotnet-complete` nor any other binary)' {
    # Pin: completion routing must go through `dotnet complete "$words"`.
    # If a refactor accidentally drops the space or swaps the binary
    # (e.g. `dotnet-complete`, `dotnet-cli`, `complete-dotnet`), the
    # entire completion pipeline silently breaks because dotnet's
    # built-in completer is only reachable via `dotnet complete`.
    grep -qE 'dotnet[[:space:]]+complete[[:space:]]+"\$words"' "$pluginFile"
    assert $? equals 0
}

@test 'callback splits dotnet output by NEWLINE not by space' {
    # Pin: dotnet complete emits one candidate per line. The plugin
    # must split on newline via the ps parameter expansion flag.
    # Swapping to space or comma would produce one giant candidate
    # string with embedded newlines instead of N candidates.
    grep -qF 'ps:\n:' "$pluginFile"
    assert $? equals 0
}

@test 'every alias target resolves to `dotnet <subcmd>` (no third-party tool routing)' {
    # Pin: the plugin only knows about dotnet workload/tool subcommands
    # via the upstream `dotnet` CLI. If an alias starts dispatching to
    # `mono`, `nuget`, or a wrapper script, the global-vs-local toggle
    # semantics break (those tools have different scope flags).
    local violation=""
    local line target
    while IFS= read -r line; do
        # form: `alias name='target ...'`
        target="${line#*=\'}"
        target="${target%%[[:space:]\']*}"
        [[ "$target" == "dotnet" ]] || violation="$violation $line"
    done < <(grep -E "^alias[[:space:]]+[a-z]+='" "$pluginFile")
    assert "$violation" is_empty
}

@test 'plugin does NOT hardcode `--global` or `--local` (delegate scope to user)' {
    # Pin: workload commands honor `dotnet tool install --global` vs
    # `--local`. The plugin must NOT bake either scope into its aliases
    # because that would hide the toggle from the user's tab path. Pin
    # both literal forms so a future "convenience" alias addition trips.
    ! grep -qE -- '(--global|--local)' "$pluginFile"
    assert $? equals 0
}

@test 'callback does NOT swallow stderr from dotnet (debuggability)' {
    # Pin: if a future refactor adds `2>/dev/null` to the `dotnet
    # complete` call, the user loses visibility into completer crashes
    # (missing SDK, broken global.json, etc.). Pin absence of stderr
    # redirection on the dotnet-complete call line.
    ! grep -qE 'dotnet[[:space:]]+complete[^|\n]*2>' "$pluginFile"
    assert $? equals 0
}
