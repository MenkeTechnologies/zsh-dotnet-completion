#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-dotnet-completion — third-tier surface pins.
#####          Pins specific to the `compctl -K` callback contract:
#####          subshell return propagation, splay-flag correctness
#####          (`ps:\n:` not `s:\n:`), and the PATH augmentation guard's
#####          ordering relative to the `[[ -d ... ]]` check.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-dotnet-completion.plugin.zsh"
}

@test 'PATH guard uses [[ ]] cond (NOT [ ] test) so empty $HOME does not error' {
    # Pin: `[[ -d ]]` is the zsh-native cond. `[ -d "$HOME"... ]` would
    # word-split an empty HOME and emit `[: -d: unary operator expected`.
    # The guard MUST be `[[` style to stay safe under empty HOME.
    grep -qE '\[\[ -d "\$HOME/\.dotnet/tools" \]\]' "$pluginFile"
    assert $? equals 0
}

@test 'callback uses ps-newline splay flag (preserves empty trailing elements)' {
    # Pin: the (ps backslash-n) parameter flag is the POSIX-split variant
    # that preserves empty fields, vs (s backslash-n) which drops them. For
    # `dotnet complete` output, trailing newlines from the binary would
    # otherwise produce a phantom empty candidate. Splay flag MUST be ps:.
    local pattern
    pattern=$(printf 'ps:%s:' '\n')
    pattern="(${pattern})completions"
    grep -qF -- "$pattern" "$pluginFile"
    assert $? equals 0
}

@test 'compctl callback fn name matches the binding (rename catches half-refactor)' {
    # Pin: the callback fn defined and the callback bound via compctl
    # are the same identifier. A rename in one place but not the other
    # would silently break completion (compctl would dispatch to a
    # nonexistent fn, returning no candidates).
    local defined bound
    defined=$(grep -oE '^_[a-z_]+(\(\))?' "$pluginFile" | head -1 | tr -d '()')
    bound=$(grep -oE 'compctl -K _[a-z_]+ ' "$pluginFile" | awk '{print $3}')
    assert "$defined" same_as "$bound"
}

@test 'aliases are SIMPLE (no backslash-quoting, no $variable interpolation)' {
    # Pin: simple aliases are the dotnet contract — no shell metachars,
    # no parameter expansion, no command substitution. An alias body
    # with `$()` or backticks would silently rerun every alias use.
    local out
    out=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>/dev/null
        for a in dcl dr dt; do
            body=\$(alias \$a)
            # body looks like: dcl='dotnet clean'
            value=\${body#*=}
            if [[ \"\$value\" == *'\$('* || \"\$value\" == *'\`'* ]]; then
                print BAD
                exit 1
            fi
        done
        print OK
    ")
    assert "$out" same_as 'OK'
}

@test 'plugin file has trailing newline (POSIX text-file requirement)' {
    # Pin: missing final newline trips `wc -l` undercount AND some
    # `read`-loop concatenations swallow the last line. Keep the
    # trailing newline pinned so a future editor does not strip it.
    local lastbyte
    lastbyte=$(tail -c 1 "$pluginFile" | xxd -p)
    assert "$lastbyte" same_as '0a'
}
