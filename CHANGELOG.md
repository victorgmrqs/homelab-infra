# Changelog

Todas as mudanças notáveis neste projeto serão documentadas aqui.

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
- [ ] Instalar K3s (control plane + workers)
- [ ] Configurar apt-cacher-ng
- [ ] Migrar Pi-hole para K8s
- [ ] Configurar Fail2ban
- [ ] Setup de observabilidade (Prometheus/Grafana)
- [ ] Configurar storage persistente (Longhorn)
