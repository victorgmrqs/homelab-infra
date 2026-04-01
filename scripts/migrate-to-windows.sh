#!/bin/bash

# Script para migrar projetos do WSL para o sistema de arquivos do Windows
# Uso: ./migrate-to-windows.sh [caminho-origem] [caminho-destino-windows]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir mensagens
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se está rodando no WSL
if ! grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    error "Este script deve ser executado no WSL"
    exit 1
fi

# Obter caminhos
ORIGEM="${1:-$HOME/projects}"
DESTINO="${2:-/mnt/c/Users/$USER/projects}"

# Validar origem
if [ ! -d "$ORIGEM" ]; then
    error "Diretório de origem não encontrado: $ORIGEM"
    exit 1
fi

# Validar destino (criar se não existir)
if [ ! -d "$DESTINO" ]; then
    info "Criando diretório de destino: $DESTINO"
    mkdir -p "$DESTINO"
fi

# Verificar se destino está no sistema de arquivos do Windows
if [[ ! "$DESTINO" =~ ^/mnt/[a-z]/ ]]; then
    warn "O destino não parece estar no sistema de arquivos do Windows (/mnt/c/, /mnt/d/, etc.)"
    read -p "Continuar mesmo assim? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Obter nome do projeto
PROJECT_NAME=$(basename "$ORIGEM")

info "Migrando projeto: $PROJECT_NAME"
info "De: $ORIGEM"
info "Para: $DESTINO/$PROJECT_NAME"

# Verificar se destino já existe
if [ -d "$DESTINO/$PROJECT_NAME" ]; then
    error "O diretório de destino já existe: $DESTINO/$PROJECT_NAME"
    read -p "Deseja sobrescrever? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    warn "Removendo diretório existente..."
    rm -rf "$DESTINO/$PROJECT_NAME"
fi

# Copiar projeto
info "Copiando arquivos (isso pode demorar)..."
cp -r "$ORIGEM" "$DESTINO/"

# Configurar Git (line endings)
if [ -d "$DESTINO/$PROJECT_NAME/.git" ]; then
    info "Configurando Git para usar LF..."
    cd "$DESTINO/$PROJECT_NAME"
    git config core.autocrlf input
    
    # Criar .gitattributes se não existir
    if [ ! -f .gitattributes ]; then
        echo "* text=auto eol=lf" > .gitattributes
        info "Criado .gitattributes"
    fi
fi

# Criar link simbólico (opcional)
read -p "Deseja criar um link simbólico de $ORIGEM para o novo local? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -e "$ORIGEM" ] && [ ! -L "$ORIGEM" ]; then
        warn "Fazendo backup do diretório original..."
        mv "$ORIGEM" "${ORIGEM}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    ln -sf "$DESTINO/$PROJECT_NAME" "$ORIGEM"
    info "Link simbólico criado: $ORIGEM -> $DESTINO/$PROJECT_NAME"
fi

# Verificar permissões de scripts
info "Verificando permissões de scripts..."
find "$DESTINO/$PROJECT_NAME" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

info "Migração concluída!"
info ""
info "Próximos passos:"
info "1. Teste o projeto no novo local: cd $DESTINO/$PROJECT_NAME"
info "2. Configure o terminal para abrir neste diretório"
info "3. Consulte docs/wsl-windows-integration.md para mais informações"
info ""
warn "Lembre-se: Performance pode ser reduzida no sistema de arquivos do Windows"




