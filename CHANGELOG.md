# Changelog

Todas as mudanças notáveis neste projeto serão documentadas aqui.

## [2026-09-24] — Fase 0 do roadmap

### Corrigido
- `install-k3s.yml`: removida linha espúria que quebrava o YAML
- `ansible.cfg`: callback `community.general.yaml` (removido) trocado por `result_format = yaml`
- Netplan de referência do kube-main-01 atualizado: o nó agora usa o cabo (`enp0s31f6`), sem Wi-Fi
- Documentação: removidos 4 links para guias inexistentes

### Segurança
- Senha do Wi-Fi removida do netplan de referência; o Wi-Fi do kube-main-01 foi desativado
- Chave SSH padronizada na ed25519 `~/.ssh/id_homelab`; arquivo `key` e inventário alinhados

### Adicionado
- `group_vars/all` e `host_vars` no inventário (usuário, porta, chave e arquivo netplan por nó)
- Playbooks `deploy-ssh-key.yml`, `fail2ban.yml` e `fix-netplan-cloud-init.yml`
- `docs/roadmap.md` e `docs/fase-1-vpn.md`

## [2025-11-26]

### Adicionado
- Configuração inicial dos 3 servidores Ubuntu 24.04
- SSH hardening (porta 2816, sem root, sem senha)
- Ansible setup e inventário
- Zsh + Oh My Zsh + Powerlevel10k em todos os servidores
- Playbooks Ansible para automação
- Documentação completa

### Configurado
- IPs fixos: 103 (master), 2 (dns), 105 (db)
- Hostnames: kube-main-01, kube-worker-dns-01, kube-worker-db-01
- Pi-hole no servidor DNS (192.168.10.2)
- UFW firewall em todos os servidores

### Segurança
- Autenticação SSH apenas por chave
- Porta SSH customizada (2816)
- Root login desabilitado
- Algoritmos de criptografia modernos

## [Planejado]

### A fazer
- [x] Instalar K3s (control plane + workers)
- [x] Configurar apt-cacher-ng
- [ ] Migrar Pi-hole para K8s
- [ ] Configurar Fail2ban
- [ ] Setup de observabilidade (Prometheus/Grafana)
- [ ] Configurar storage persistente (Longhorn)
