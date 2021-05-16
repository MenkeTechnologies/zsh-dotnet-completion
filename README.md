# zsh-dotnet-completion

Dotnet tab completion

Aliases

```sh
alias dt='dotnet test'
alias dcl='dotnet clean'
alias dr='dotnet run'
```

## Install for Zinit
> `~/.zshrc`
```sh
source "$HOME/.zinit/bin/zinit.zsh"
zinit ice lucid nocompile
zinit load MenkeTechnologies/zsh-dotnet-completion
```

## Install for Oh My Zsh

```sh
cd "$HOME/.oh-my-zsh/custom/plugins"  && git clone https://github.com/MenkeTechnologies/zsh-dotnet-completion.git
```

Add `zsh-dotnet-completion` to plugins array in ~/.zshrc

## General Install

```sh
git clone https://github.com/MenkeTechnologies/zsh-dotnet-completion.git
```

source zsh-dotnet-completion.plugin.zsh or add code to zshrc or any startup script
