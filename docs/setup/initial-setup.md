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

- [Configurar SSH Hardening](ssh-hardening.md)
- [Instalar Ansible](ansible-setup.md)