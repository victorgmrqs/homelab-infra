# Integração WSL com Windows - Guia Completo

## 📋 Visão Geral

Este guia explica como trabalhar com projetos no sistema de arquivos do Windows através do WSL, incluindo cuidados importantes e melhores práticas.

## 🚀 Como Mover Projetos para o Windows

### 1. Escolhendo o Local no Windows

Os arquivos do Windows são acessíveis no WSL através dos pontos de montagem:
- `/mnt/c/` → `C:\`
- `/mnt/d/` → `D:\`
- `/mnt/e/` → `E:\`
- etc.

**Recomendação:** Use uma pasta dedicada para projetos, por exemplo:
- Windows: `C:\Users\SeuUsuario\projects\`
- WSL: `/mnt/c/Users/SeuUsuario/projects/`

### 2. Movendo os Projetos

```bash
# 1. Criar a pasta de destino no Windows (se não existir)
mkdir -p /mnt/c/Users/SeuUsuario/projects

# 2. Mover o projeto atual
mv ~/projects/homelab-workspaces /mnt/c/Users/SeuUsuario/projects/

# 3. Criar um link simbólico (opcional, para manter compatibilidade)
ln -s /mnt/c/Users/SeuUsuario/projects/homelab-workspaces ~/projects/homelab-workspaces
```

### 3. Atualizando Caminhos em Scripts

Após mover, atualize qualquer referência a caminhos absolutos:

```bash
# Verificar scripts que podem ter caminhos hardcoded
grep -r "/home/victor" . --include="*.sh" --include="*.yml" --include="*.yaml"
```

## 🖥️ Abrindo Terminal Diretamente no Path do Windows

### Opção 1: Usando o Terminal do Windows

1. Abra o **Terminal do Windows** (Windows Terminal)
2. Pressione `Ctrl + Shift + ,` para abrir settings
3. Ou clique no dropdown e selecione "Settings"
4. Adicione um perfil WSL que inicia no diretório desejado:

```json
{
    "name": "WSL - Projects",
    "commandline": "wsl.exe -d Ubuntu --cd /mnt/c/Users/SeuUsuario/projects",
    "startingDirectory": "C:\\Users\\SeuUsuario\\projects"
}
```

### Opção 2: Usando o Explorer do Windows

1. Navegue até a pasta do projeto no **Explorer do Windows**
2. Clique com botão direito na pasta
3. Selecione **"Abrir no Terminal"** ou **"Open in Windows Terminal"**
4. O terminal abrirá no diretório correto

### Opção 3: Criando um Atalho

1. Crie um arquivo `.bat` ou `.ps1`:

**wsl-projects.bat:**
```batch
@echo off
wsl.exe -d Ubuntu --cd /mnt/c/Users/SeuUsuario/projects
```

2. Execute o arquivo para abrir o WSL diretamente no diretório

### Opção 4: Configurando o Zsh para Iniciar no Diretório do Windows

Adicione ao seu `~/.zshrc`:

```bash
# Se estiver no WSL e quiser iniciar em um diretório específico do Windows
if [[ -d /mnt/c/Users/SeuUsuario/projects ]]; then
    cd /mnt/c/Users/SeuUsuario/projects
fi
```

## ⚠️ Cuidados Importantes

### 1. Performance

**Problema:** Arquivos no sistema de arquivos do Windows (`/mnt/c/`) são significativamente mais lentos que arquivos no sistema de arquivos nativo do Linux.

**Impacto:**
- Operações de I/O podem ser 10-20x mais lentas
- `npm install`, `yarn install`, compilações podem ser muito lentas
- Git operations podem ser mais lentas

**Solução:**
- Para projetos com muitas dependências (Node.js, Python), considere manter no sistema de arquivos do WSL
- Use o sistema de arquivos do Windows apenas para projetos leves ou quando precisar de integração com ferramentas do Windows

### 2. Permissões de Arquivos

**Problema:** Permissões entre Windows e Linux podem causar problemas.

**Sintomas:**
- Arquivos criados no WSL podem não ter permissões corretas no Windows
- Scripts podem não ser executáveis
- Git pode reclamar sobre permissões

**Solução:**
```bash
# Configurar ummask para arquivos no Windows
# Adicione ao ~/.zshrc ou ~/.bashrc
if [[ $(pwd) == /mnt/* ]]; then
    umask 022
fi

# Corrigir permissões de scripts
chmod +x script.sh
```

### 3. Line Endings (CRLF vs LF)

**Problema:** Windows usa CRLF (`\r\n`), Linux usa LF (`\n`).

**Sintomas:**
- Scripts podem não executar corretamente
- Git mostra todos os arquivos como modificados

**Solução:**
```bash
# Configurar Git para usar LF
git config --global core.autocrlf input

# Ou criar/editar .gitattributes no projeto
echo "* text=auto eol=lf" > .gitattributes
```

### 4. Links Simbólicos

**Problema:** Links simbólicos podem não funcionar corretamente entre Windows e WSL.

**Solução:**
- Evite links simbólicos que cruzam os sistemas de arquivos
- Use caminhos absolutos quando necessário

### 5. Node Modules e Dependências

**Problema:** `node_modules` pode ter problemas de performance e permissões.

**Solução:**
```bash
# Usar .wslconfig para melhorar performance
# Crie/edite C:\Users\SeuUsuario\.wslconfig no Windows:

[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true

# Para projetos Node.js, considere usar .npmrc:
echo "cache=/home/victor/.npm-cache" > .npmrc
```

### 6. Git e Autenticação

**Problema:** Credenciais do Git podem precisar ser reconfiguradas.

**Solução:**
```bash
# Reconfigurar Git após mover
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"

# Se usar SSH keys, certifique-se de que estão acessíveis
# Geralmente ficam em ~/.ssh/ (que está no sistema de arquivos do WSL)
```

### 7. Variáveis de Ambiente

**Problema:** PATH e outras variáveis podem precisar de ajustes.

**Solução:**
```bash
# Verificar se caminhos do Windows estão no PATH
echo $PATH

# Adicionar ao ~/.zshrc se necessário
export PATH="/mnt/c/Windows/System32:$PATH"
```

## 🔧 Configurações Recomendadas

### 1. Arquivo `.wslconfig` (Windows)

Crie `C:\Users\SeuUsuario\.wslconfig`:

```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true

# Melhorar performance de I/O
[experimental]
sparseVhd=true
```

### 2. Configuração do Git

```bash
# Configurar Git para melhor performance no Windows
git config --global core.preloadindex true
git config --global core.fscache true
git config --global gc.auto 256

# Configurar line endings
git config --global core.autocrlf input
```

### 3. Configuração do Zsh

Adicione ao `~/.zshrc`:

```bash
# Detectar se estamos em um diretório do Windows
is_windows_path() {
    [[ $(pwd) == /mnt/* ]]
}

# Ajustar configurações baseado no sistema de arquivos
if is_windows_path; then
    # Desabilitar algumas otimizações que podem causar problemas
    export NODE_OPTIONS="--no-warnings"
    
    # Aviso sobre performance
    if [[ -z "$WSL_WINDOWS_PATH_WARNING" ]]; then
        echo "⚠️  Você está em um diretório do Windows. Performance pode ser reduzida."
        export WSL_WINDOWS_PATH_WARNING=1
    fi
fi
```

## 📝 Checklist de Migração

- [ ] Escolher local no Windows para projetos
- [ ] Mover projetos para o novo local
- [ ] Atualizar caminhos em scripts e configurações
- [ ] Configurar Git (line endings, autocrlf)
- [ ] Testar permissões de arquivos
- [ ] Configurar terminal para abrir no diretório correto
- [ ] Criar `.wslconfig` no Windows (opcional, mas recomendado)
- [ ] Testar performance e decidir se vale a pena
- [ ] Atualizar documentação do projeto com novos caminhos

## 🎯 Quando Usar Cada Sistema de Arquivos

### Use Sistema de Arquivos do Windows (`/mnt/c/`) quando:
- ✅ Precisar de integração com ferramentas do Windows (VS Code, Docker Desktop, etc.)
- ✅ Projetos leves (documentação, scripts simples)
- ✅ Quiser acesso fácil pelo Explorer do Windows
- ✅ Não houver muitas operações de I/O

### Use Sistema de Arquivos do WSL (`~/`) quando:
- ✅ Projetos com muitas dependências (Node.js, Python, etc.)
- ✅ Necessitar de máxima performance
- ✅ Trabalhar com compilações pesadas
- ✅ Usar ferramentas que fazem muitas operações de arquivo

## 🔗 Recursos Adicionais

- [Documentação oficial do WSL](https://docs.microsoft.com/en-us/windows/wsl/)
- [WSL2 Performance](https://docs.microsoft.com/en-us/windows/wsl/compare-versions)
- [Git e Line Endings](https://docs.github.com/en/get-started/getting-started-with-git/configuring-git-to-handle-line-endings)




