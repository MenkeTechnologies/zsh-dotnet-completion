```
 ███████╗███████╗██╗  ██╗
 ╚══███╔╝██╔════╝██║  ██║
   ███╔╝ ███████╗███████║
  ███╔╝  ╚════██║██╔══██║
 ███████╗███████║██║  ██║
 ╚══════╝╚══════╝╚═╝  ╚═╝
       [ d o t n e t ]
```

[![CI](https://github.com/MenkeTechnologies/zsh-dotnet-completion/actions/workflows/ci.yml/badge.svg)](https://github.com/MenkeTechnologies/zsh-dotnet-completion/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![zsh](https://img.shields.io/badge/zsh-plugin-cyan.svg)](https://github.com/MenkeTechnologies/zpwr)

### `[DOTNET TAB COMPLETION FOR ZSH]`

> *"dotnet, completed."*

Dotnet tab completion

## Aliases

| Alias | Expands to |
| --- | --- |
| `dt` | `dotnet test` |
| `dcl` | `dotnet clean` |
| `dr` | `dotnet run` |

### [`strykelang`](https://github.com/MenkeTechnologies/strykelang) &middot; [`zshrs`](https://github.com/MenkeTechnologies/zshrs) · [`MenkeTechnologiesMeta`](https://github.com/MenkeTechnologies/MenkeTechnologiesMeta) · [`zsh-cargo-completion`](https://github.com/MenkeTechnologies/zsh-cargo-completion) · [`zsh-gem-completion`](https://github.com/MenkeTechnologies/zsh-gem-completion) · [`zsh-more-completions`](https://github.com/MenkeTechnologies/zsh-more-completions) · [`zpwr`](https://github.com/MenkeTechnologies/zpwr)

---

## Table of Contents

- [\[0x00\] Install for Zinit](#0x00-install-for-zinit)
- [\[0x01\] Install for Oh My Zsh](#0x01-install-for-oh-my-zsh)
- [\[0x02\] General Install](#0x02-general-install)

---

## [0x00] Install for Zinit
> `~/.zshrc`
```sh
source "$HOME/.zinit/bin/zinit.zsh"
zinit ice lucid nocompile
zinit load MenkeTechnologies/zsh-dotnet-completion
```

## [0x01] Install for Oh My Zsh

```sh
cd "$HOME/.oh-my-zsh/custom/plugins"  && git clone https://github.com/MenkeTechnologies/zsh-dotnet-completion.git
```

Add `zsh-dotnet-completion` to plugins array in ~/.zshrc

## [0x02] General Install

```sh
git clone https://github.com/MenkeTechnologies/zsh-dotnet-completion.git
```

source zsh-dotnet-completion.plugin.zsh or add code to zshrc or any startup script
