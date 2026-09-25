# Roadmap de evolução do homelab

Levantamento feito em 22/09/2026, a partir da inspeção dos repositórios `homelab-infra`,
`homelab-gitops`, `homelab-ci-cd-test` e do estado real dos três nós.

O objetivo é transformar o homelab em um ambiente com padrão profissional: reproduzível a
partir do git, observável, seguro por identidade e com esteira de entrega auditável.

---

## 0. Duas decisões estruturais antes de tudo

### 0.1 k3s continua. Minikube seria um retrocesso

| | Minikube | k3s (atual) | Talos Linux |
|---|---|---|---|
| Propósito | Estação de desenvolvimento, um cluster descartável por máquina | Cluster real, multi-nó, bare metal | Cluster real, SO imutável dedicado a Kubernetes |
| Multi-nó | Só simulado, com VMs ou contêineres dentro de um host | Nativo, um agente por máquina física | Nativo |
| Uso dos 3 servidores | Não aproveita: cada host teria um cluster isolado | Aproveita os três como um cluster só | Aproveita |
| Produção/homolog | Não suportado | Suportado, é uma distribuição Kubernetes certificada | Suportado |
| Gerenciamento | Comandos imperativos `minikube start` | systemd + arquivo de config declarativo | API declarativa, sem SSH nem shell |

Minikube é excelente para rodar um cluster no laptop enquanto se desenvolve uma aplicação, e é
exatamente esse o papel que o `homelab-gitops/local/` (kind) já cumpre. Trocar o k3s por ele
significaria perder o cluster multi-nó, a distribuição de carga entre as três máquinas e a
semelhança com produção. **Recomendação: manter k3s**, corrigindo a forma como ele é instalado
e configurado (ver fase 2).

O caminho de amadurecimento, se um dia quiser ir além, é **Talos Linux**: SO imutável, sem SSH,
configurado por API declarativa, com upgrades atômicos e rollback. É o que mais se aproxima de
um cluster gerenciado de nuvem rodando em casa. Só vale a pena depois que as fases 1 a 4
estiverem prontas, porque exige reinstalar os três nós.

### 0.2 O que "VPN padrão ouro" significa

Uma VPN corporativa moderna não é só um túnel cifrado. O que a torna padrão ouro é:

1. **Identidade, não chave compartilhada.** O acesso é do *usuário*, autenticado por SSO com MFA,
   e expira. Não é um arquivo `.conf` que, se vazar, dá acesso para sempre.
2. **Autorização granular (ACL como código).** Quem acessa o quê, por porta e por serviço,
   versionado em git e revisado em PR. Nada de "entrou na VPN, enxerga a rede inteira".
3. **Postura do dispositivo.** Só dispositivos registrados e aprovados conectam.
4. **Zero portas abertas na borda.** Nada de encaminhar porta no roteador e esperar pelo melhor.
5. **Auditoria.** Registro de quem conectou, de onde e o que acessou.
6. **Malha, não concentrador.** Conexão direta entre dispositivos (WireGuard ponto a ponto), com
   travessia de NAT, o que funciona mesmo sob CGNAT.

O que existe hoje, o Cloudflare Tunnel com `warp-routing`, atende de 1 a 5, mas depende
inteiramente da Cloudflare e só funciona enquanto o cluster e os pods do `cloudflared` estiverem
de pé, o que é frágil: o acesso de emergência morre junto com o cluster.

---

## 1. Fase 0 — Estancar o sangramento (esforço: 1 dia)

Itens que estão quebrados agora e não dependem de nenhuma decisão.

| # | Item | Ação |
|---|---|---|
| 0.1 | Argo CD parado há ~21 dias | Apagar o pod `argocd-repo-server` (o init `copyutil` falha com `ln: File exists` em volume reaproveitado) e atualizar o chart |
| 0.2 | `homelab-prod` nunca aplicado | Substituir o placeholder `REPO_URL` e alinhar o overlay de prod (hoje aponta para MySQL, o homolog já migrou para PostgreSQL) |
| 0.3 | Pod `infra/echo` em ImagePullBackOff há 226 dias | Remover, é resto de teste |
| 0.4 | 131 atualizações pendentes e reboot pendente no main | Rodar `update-servers.yml`, depois automatizar (ver 5.4) |
| 0.5 | Senha do Wi-Fi em texto puro no git | Trocar a senha, remover o arquivo do histórico, usar `ansible-vault` |
| 0.6 | `install-k3s.yml` corrompido | Remover a linha `vowels = (...)` que quebra o YAML |
| 0.7 | Chave SSH e inventário divergentes | Padronizar em uma chave ed25519 nova, atualizar `hosts.ini` e `key` |
| 0.8 | Fail2ban ausente, ao contrário do que a doc diz | Instalar via playbook ou remover a alegação da doc |
| 0.9 | Documentação com 4 links quebrados e CHANGELOG parado em nov/2025 | Escrever os docs faltantes ou remover os links |
| 0.10 | `kube-worker-db-01` com dois IPs (.105 estático + .107 DHCP) e duas rotas default | Desabilitar o DHCP na interface |

## 2. Fase 1 — Acesso: a VPN padrão ouro (esforço: 1 a 2 fins de semana)

### Escolha da tecnologia

Todas as opções abaixo usam WireGuard como transporte. A diferença está no plano de controle.

| Opção | Identidade e MFA | ACL como código | Funciona sob CGNAT | Custo | Dependência externa |
|---|---|---|---|---|---|
| **Tailscale** (plano gratuito: 3 usuários, 100 dispositivos) | SSO Google/GitHub/Microsoft + MFA | Sim, arquivo de política em git | Sim, travessia de NAT com relays DERP | R$ 0 | Plano de controle da Tailscale |
| **Headscale** (plano de controle self-hosted) | OIDC próprio, ex. Authentik ou Keycloak | Sim, mesma sintaxe de ACL | Sim, com relay próprio ou os públicos | VPS ~R$ 30/mês | Nenhuma, mas você opera |
| **WireGuard puro** (roteador ou host) | Não, só chave por dispositivo | Não, só regras de firewall | **Não**, exige IP público | R$ 0 | Nenhuma |

**Recomendação: Tailscale agora, com Headscale como evolução opcional.** Ele entrega os seis
critérios de padrão ouro sem depender de IP público, e a migração para Headscale depois é quase
transparente, já que o cliente é o mesmo. WireGuard puro só é viável se o seu provedor entregar
IP público, e ainda assim fica dois degraus abaixo em identidade e autorização.

### Desenho proposto

```
Laptop / celular  ──WireGuard──┐
                               ├─→ malha Tailscale (SSO + MFA + ACL)
Subnet router (dns-01) ────────┤     │
Subnet router (db-01, backup) ─┘     ├─→ 192.168.10.0/24 (rede de casa)
                                     └─→ MagicDNS + Pi-hole (split DNS)
```

Passos:

1. Instalar o `tailscaled` nos três nós via Ansible, **fora do Kubernetes**, para que o acesso de
   emergência sobreviva a uma queda do cluster.
2. Anunciar a rota `192.168.10.0/24` em **dois** nós (dns-01 e db-01), para redundância.
3. Definir ACLs em git: por exemplo, o grupo `admin` alcança `tag:homelab:*`, enquanto um
   dispositivo de visita alcança só o Home Assistant.
4. Ligar **Tailscale SSH**: acesso SSH autenticado pela identidade, com gravação de sessão, no
   lugar da chave estática. A porta 2816 passa a aceitar conexões só pela VPN.
5. Split DNS: `*.lab.goncalvesmarques.com` resolve pelo Pi-hole dentro da VPN.
6. Certificados Let's Encrypt via DNS-01 da Cloudflare, aposentando a CA self-signed e os
   avisos de certificado no navegador.
7. Reduzir o Cloudflare Tunnel ao que precisa mesmo ser público (hoje o homolog do
   home-finance e a api-test) e desligar o `warp-routing`.
8. Fechar o firewall: o UFW passa a aceitar SSH e 6443 apenas pela interface da VPN.

Resultado: `kubectl`, Argo CD, Grafana e SSH acessíveis de qualquer lugar, por identidade, sem
nenhuma porta aberta para a internet.

## 3. Fase 2 — Fundação do cluster e dos hosts (esforço: 2 a 3 fins de semana)

| # | Item | Situação hoje | Alvo |
|---|---|---|---|
| 2.1 | Instalação do k3s | Shell imperativo com `curl \| sh` e flags no playbook | `/etc/rancher/k3s/config.yaml` declarativo, versionado, com versão fixada |
| 2.2 | Datastore | Padrão, sem snapshots | etcd com snapshots automáticos e cópia para fora do nó |
| 2.3 | Distribuição de carga | **30 dos 40 pods no main**; db-01 quase ocioso | Taints no control plane, `nodeAffinity` e `topologySpreadConstraints` por workload |
| 2.4 | Limites de recursos | Maioria dos workloads sem requests/limits | Requests e limits em tudo, mais `LimitRange` e `ResourceQuota` por namespace |
| 2.5 | Estabilidade | 22 mil restarts acumulados no main, erros de `flannel subnet.env` no boot | Corrigir ordem de inicialização, investigar OOM e quedas de rede |
| 2.6 | Storage | `local-path`, dados presos ao nó, sem backup | Longhorn (replicação entre nós) ou local-path + Velero; **reconectar os 2 HDDs de 1TB do db-01, que não aparecem no `lsblk`** |
| 2.7 | Ingress | ingress-nginx **aposentado pelo upstream**, exposto via NodePort 80/443 com range alterado para 80-32767 | Migrar para Gateway API (Envoy Gateway ou Traefik v3) e expor com MetalLB em modo L2 |
| 2.8 | Ansible | Playbooks soltos, sem estrutura | Roles, `ansible-lint`, teste com Molecule, inventário com `group_vars` |
| 2.9 | Pi-hole e apt-cacher-ng | Em Docker no dns-01, fora do k8s e fora do git | Decidir: migrar para o cluster (com HA) ou declarar como serviço de host no Ansible |
| 2.10 | Versão do Kubernetes | v1.33.6, perto do fim de suporte | Política de upgrade: n-1, uma janela por trimestre |

## 4. Fase 3 — GitOps de verdade (esforço: 2 fins de semana)

Hoje o Argo CD gerencia 5 Applications, enquanto Argo CD, cert-manager, ingress-nginx,
kube-prometheus-stack e Loki foram instalados à mão com Helm. O cluster **não é reproduzível a
partir do git**, que é o requisito mais básico de um ambiente profissional.

1. **App-of-apps**: uma Application raiz que aponta para `apps/`, e cada componente de
   infraestrutura vira uma Application com o chart e os values versionados.
2. **ApplicationSets** para gerar prod e homolog a partir do mesmo template, eliminando a
   duplicação entre os overlays.
3. **Argo CD Projects + RBAC + SSO**, com login pela identidade da VPN, não pela senha admin.
4. **Secrets**: substituir Sealed Secrets por **External Secrets Operator** lendo do Bitwarden
   (que você já usa) ou de um Vault. Sealed Secrets prende o segredo à chave do cluster, o que
   inviabiliza recuperação de desastre.
5. **Checks em PR**: `kustomize build`, `kubeconform`, `helm template`, mais políticas com
   Conftest ou Kyverno em modo auditoria.
6. **Renovate** para abrir PRs de atualização de charts e imagens automaticamente.
7. **Autopromoção controlada**: homolog sincroniza sozinho, prod exige PR aprovado.

## 5. Fase 4 — Esteira CI/CD profissional (esforço: 2 fins de semana)

As esteiras atuais (`homelab-ci-cd-test` e `hf-transaction-service`) já fazem build, push e
atualização do GitOps, o que é uma base boa. O que falta para virar padrão de mercado:

| # | Lacuna | Alvo |
|---|---|---|
| 4.1 | Tags mutáveis (`:development`, `:latest`) rodando no cluster | Tag imutável por SHA, sempre. `latest` só como apelido |
| 4.2 | Sem SAST | CodeQL ou `golangci-lint` com gate de qualidade |
| 4.3 | Trivy só na imagem, em uma esteira | Trivy em imagem e sistema de arquivos, nas duas, com gate CRITICAL/HIGH |
| 4.4 | Sem SBOM nem assinatura | Syft gerando SBOM + Cosign assinando, com verificação por Kyverno na admissão: **o cluster recusa imagem não assinada** |
| 4.5 | Cobertura de testes não medida | Gate de cobertura mínima e relatório no PR |
| 4.6 | `sed` editando o kustomization do GitOps | `kustomize edit set image`, e commit assinado pelo bot |
| 4.7 | PAT pessoal (`GITOPS_UPDATE_PAT`) | GitHub App com permissão mínima, ou deploy key por repositório |
| 4.8 | `homelab-ci-cd-test` só faz `go build`, sem testes | Padronizar as duas esteiras em reusable workflows |
| 4.9 | Sem ambiente por PR | Ambientes efêmeros por PR com ApplicationSet PR generator |
| 4.10 | Deploy direto, sem estratégia | Argo Rollouts com canary e rollback automático por métrica |
| 4.11 | Runners públicos apenas | Actions Runner Controller no cluster, para jobs que precisam de acesso interno |
| 4.12 | Prod sem proteção | GitHub Environments com aprovação manual para prod |

## 6. Fase 5 — Operação (esforço: contínuo)

1. **Observabilidade**: substituir o Promtail (descontinuado) por **Grafana Alloy**; adicionar
   tracing com Tempo e instrumentação OpenTelemetry nos serviços do home-finance.
2. **Alertas que chegam em você**: Alertmanager notificando por ntfy ou Telegram, com SLOs
   definidos (disponibilidade do ingress, latência do frontend, espaço em disco, certificados
   por vencer) em vez de alertas genéricos.
3. **Backup e DR**: Velero + restic, com destino fora de casa (Backblaze B2 ou Cloudflare R2),
   `pg_dump` agendado do PostgreSQL e **teste de restauração trimestral**. Sem teste de
   restore, não existe backup.
4. **Atualizações**: `unattended-upgrades` já instala, mas ninguém reinicia. Adicionar **kured**
   para reboots coordenados, um nó por vez, em janela definida.
5. **Segurança contínua**: Pod Security Standards em `restricted`, NetworkPolicies com negação
   padrão por namespace (hoje existe uma só), `kube-bench` para o CIS Benchmark, e rotação de
   credenciais.
6. **Runbooks**: um documento por falha provável (nó caiu, disco cheio, certificado vencido,
   Argo fora do ar) com o procedimento de recuperação.

## 7. Fase 6 — Maturidade, opcional

- Control plane em HA com 3 servidores etcd.
- Migração para Talos Linux.
- Cilium no lugar do Flannel, com Hubble para observabilidade de rede e NetworkPolicies L7.
- Crossplane para provisionar recursos externos declarativamente.
- Backstage como portal de serviços, catalogando as aplicações do homelab.

---

## Ordem sugerida

```
Fase 0 (1 dia)  →  Fase 1 VPN (1-2 fds)  →  Fase 2 fundação (2-3 fds)
                                                   ↓
                   Fase 5 operação  ←  Fase 4 CI/CD  ←  Fase 3 GitOps (2 fds)
                        (contínuo)        (2 fds)
```

A fase 1 vem antes da 2 porque, com a VPN pronta, todo o resto do trabalho pode ser feito
remotamente e com segurança. A fase 3 vem antes da 4 porque não adianta ter esteira de entrega
impecável entregando para um cluster que não é reproduzível.

## Decisões pendentes

1. **O provedor entrega IP público ou usa CGNAT?** Só muda a viabilidade do WireGuard puro. A
   recomendação (Tailscale) funciona nos dois casos. Veja o IP WAN no painel do roteador: se
   começar entre `100.64.` e `100.127.`, é CGNAT.
2. **Os 2 HDDs de 1TB do db-01 foram removidos ou estão desconectados?** Definem a estratégia de
   storage da fase 2.
3. **Os servidores ficam ligados 24/7?** O histórico de boots sugere que não, o que muda o
   desenho de HA e a janela de backup.
4. **O que permanece público pela Cloudflare** depois que a VPN estiver de pé?
5. **Há orçamento para uma VPS pequena** (~R$ 30/mês), necessária para Headscale self-hosted e
   útil como destino de backup?
