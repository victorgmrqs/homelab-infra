Port 2816
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding yes
PermitTunnel no
PrintMotd no

PermitTTY yes
PermitUserEnvironment yes


# Segurança e controle
LoginGraceTime 30s
MaxAuthTries 3
MaxSessions 4
MaxStartups 3:30:10
ClientAliveInterval 300
ClientAliveCountMax 2
PermitEmptyPasswords no
UseDNS no

AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server