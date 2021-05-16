if [[ -d "$HOME/.dotnet/tools" ]]; then
    export PATH="$PATH:$HOME/.dotnet/tools"
fi

_dotnet_zsh_complete() {
  local completions=("$(dotnet complete "$words")")

  reply=( "${(ps:\n:)completions}" )
}

alias dt='dotnet test'
alias dcl='dotnet clean'
alias dr='dotnet run'

compctl -K _dotnet_zsh_complete dotnet
