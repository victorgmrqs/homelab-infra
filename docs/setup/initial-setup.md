# Configuração Inicial dos Servidores

## Pré-requisitos
- Ubuntu Server 24.04 instalado
- Conexão de rede configurada
- Acesso físico ou via console

## 1. Configuração de Rede

### Definir IP fixo
```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

### Alterar hostname
```bash
sudo hostnamectl set-hostname <nome>
sudo nano /etc/hosts
```

## 2. Primeiro acesso SSH
```bash
# Da máquina local
ssh-keygen -t ed25519 -C "victor@homelab"
ssh-copy-id usuario@<ip>
```

## 3. Atualização inicial
```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

## 4. Próximos passos

- Instalar o Ansible na máquina de controle: `uv tool install ansible-core` e
  `ansible-galaxy collection install ansible.posix community.general`
- Autorizar a chave padrão: `ansible-playbook playbooks/deploy-ssh-key.yml`
- SSH hardening e fail2ban: `ansible-playbook playbooks/ssh-hardening.yml playbooks/fail2ban.yml -K`