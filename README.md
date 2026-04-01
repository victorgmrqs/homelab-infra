# Homelab Infrastructure

Infraestrutura de homelab para aprendizado de DevOps, Kubernetes e tecnologias cloud-native.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Hardware](#hardware)
- [Rede](#rede)
- [Servidores](#servidores)
- [Tecnologias](#tecnologias)
- [Guias de Configuração](#guias-de-configuração)
- [Playbooks Ansible](#playbooks-ansible)

## 🎯 Visão Geral

Cluster Kubernetes (K3s) com 3 nós físicos rodando Ubuntu Server 24.04, configurado via Ansible para:
- Testes de aplicações
- Aprendizado de DevOps
- Observabilidade e monitoramento
- Gestão de bancos de dados

## 🖥️ Hardware

### Servidor 1 - Control Plane (kube-main-01)
- **IP:** 192.168.10.103
- **CPU:** Intel Core i9-12900F
- **RAM:** 32GB DDR5 (expansível até 192GB)
- **Storage:** 1TB NVMe SSD
- **GPU:** RTX 2060
- **PSU:** Corsair 850W
- **Função:** Control plane K3s

### Servidor 2 - Worker DNS (kube-worker-dns-01)
- **IP:** 192.168.10.2
- **Modelo:** Mini PC Kamrui GK3PLUS
- **CPU:** Intel N97
- **RAM:** 8GB DDR4 SO-DIMM (expansível até 16GB)
- **Storage:** 256GB SSD
- **Função:** Worker node + Pi-hole DNS + APT Cache

### Servidor 3 - Worker DB (kube-worker-db-01)
- **IP:** 192.168.10.105
- **CPU:** AMD Ryzen 7 1700
- **RAM:** 32GB DDR4 (2x16GB, expansível até 64GB)
- **Storage:** 256GB NVMe + 2x 1TB HDD 2.5"
- **GPU:** Nvidia GT 710 2GB
- **Função:** Worker node + Database storage

## 🌐 Rede

- **Switch:** TP-Link TL-SG108E (gerenciável)
- **Modem:** Provedor ISP
- **Roteador:** TP-Link VPN
- **Access Point:** TP-Link
- **DNS Filtering:** Pi-hole (192.168.10.2)
- **Subnet:** 192.168.10.0/24

### Portas e Serviços
| Porta | Serviço | Servidor |
|-------|---------|----------|
| 2816  | SSH     | Todos    |
| 6443  | K3s API | 103      |
| 3142  | APT Cache | 2      |
| 53    | DNS (Pi-hole) | 2  |
| 80    | Pi-hole Web | 2    |

## 🛠️ Tecnologias

- **OS:** Ubuntu Server 24.04 LTS
- **Orquestração:** Kubernetes (K3s)
- **Automação:** Ansible 2.16+
- **Shell:** Zsh + Oh My Zsh + Powerlevel10k
- **DNS:** Pi-hole
- **Cache:** apt-cacher-ng
- **Segurança:** SSH hardening, UFW, Fail2ban
- **Versionamento:** Git

## 📁 Estrutura do repositório

- **ansible/** – Inventário, playbooks e templates (SSH, Zsh, K3s, etc.)
- **host-configs/** – Configurações por host (netplan, referência SSH) para documentação/aplicação manual
- **docs/** – Guias de configuração e setup
- **scripts/** – Scripts de manutenção (atualizar docs, migração WSL)
- **archive/** – Backup/legado (ex.: configs de outro ambiente)

## 📚 Guias de Configuração

- [Configuração Inicial](docs/setup/initial-setup.md)
- [SSH Hardening](docs/setup/ssh-hardening.md)
- [Ansible Setup](docs/setup/ansible-setup.md)
- [Instalação K3s](docs/setup/k3s-installation.md)
- [Troubleshooting](docs/setup/troubleshooting.md)
- [Integração WSL com Windows](docs/wsl-windows-integration.md) - Trabalhando com projetos no sistema de arquivos do Windows

## 🤖 Playbooks Ansible

```bash
cd ansible && ansible-playbook playbooks/<playbook>.yml
```
Ou da raiz: `ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/<playbook>.yml`

### Disponíveis
- `ssh-hardening.yml` - Hardening de SSH em todos os servidores
- `setup-zsh.yml` - Instalação e configuração do Zsh/Powerlevel10k
- `install-k3s.yml` - Preparação e instalação do K3s (control plane + workers)
- `setup-apt-cache.yml` - apt-cacher-ng no worker DNS
- `update-servers.yml` / `update-simple.yml` - Atualização dos servidores
