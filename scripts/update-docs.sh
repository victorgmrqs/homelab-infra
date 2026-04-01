#!/bin/bash
# Script para atualizar documentação automaticamente
# Executar a partir da raiz do repositório: ./scripts/update-docs.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
PLAYBOOKS_DIR="$REPO_ROOT/ansible/playbooks"
INVENTORY_FILE="$REPO_ROOT/ansible/inventory/hosts.ini"

cd "$REPO_ROOT"

echo "📝 Atualizando documentação..."

# Gera lista de playbooks
echo "## Playbooks disponíveis" > "$DOCS_DIR/playbooks-list.md"
echo "" >> "$DOCS_DIR/playbooks-list.md"
ls -1 "$PLAYBOOKS_DIR"/*.yml 2>/dev/null | while read file; do
    filename=$(basename "$file")
    echo "- [\`$filename\`](../ansible/playbooks/$filename)" >> "$DOCS_DIR/playbooks-list.md"
done

# Gera inventário em markdown
echo "## Inventário de Servidores" > "$DOCS_DIR/inventory.md"
echo "" >> "$DOCS_DIR/inventory.md"
echo "\`\`\`ini" >> "$DOCS_DIR/inventory.md"
cat "$INVENTORY_FILE" >> "$DOCS_DIR/inventory.md"
echo "\`\`\`" >> "$DOCS_DIR/inventory.md"

echo "✅ Documentação atualizada!"
echo "Commit changes? (y/n)"
read answer
if [ "$answer" = "y" ]; then
    git add docs/
    git commit -m "docs: Update auto-generated documentation"
    echo "📤 Push to remote? (y/n)"
    read push
    if [ "$push" = "y" ]; then
        git push
    fi
fi
