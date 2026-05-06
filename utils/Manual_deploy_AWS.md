# Guide de déploiement Docker sur AWS EC2
*Ubuntu + Docker + Docker Compose + Application multi-services*

---

## 1. Création de l'instance EC2

### 1.1 Paramètres recommandés

| Paramètre | Valeur recommandée |
|-----------|-------------------|
| OS / AMI | Ubuntu Server 22.04 LTS (HVM) |
| Type d'instance | **t3.small** (2 vCPU, 2 GB RAM) minimum |
| Stockage | 20 GB gp2 minimum |
| Security Group | SSH (22), HTTP (80), ports applicatifs |
| Clé SSH | Créer ou utiliser une paire existante (.ppk pour PuTTY) |

> `t2.micro` (1 GB RAM) est insuffisant pour builder plusieurs services simultanément. Utiliser **t3.small** minimum.

---

## 2. Connexion via PuTTY

- Ouvrir PuTTY
- Host Name : `ubuntu@<IP_PUBLIQUE_EC2>`
- Connection > SSH > Auth > Credentials : charger le fichier `.ppk`
- Cliquer Open

---

## 3. Installation de tmux

tmux permet de garder les commandes actives même si PuTTY se déconnecte.

```bash
sudo apt update
sudo apt install -y tmux
tmux new -s install
```

> Si PuTTY se déconnecte, reconnectez-vous et tapez : `tmux attach -t install`

---

## 4. Installation de Docker

### 4.1 Prérequis

```bash
sudo apt install -y ca-certificates curl gnupg
```

### 4.2 Clé GPG officielle Docker

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

### 4.3 Dépôt officiel Docker

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 4.4 Installation

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
sudo chmod 666 /var/run/docker.sock
```

### 4.5 Installation de Docker Buildx

Les versions récentes de docker compose exigent Buildx pour builder les images. Sans lui, le build s'arrête.

Vérifier l'architecture d'abord :

```bash
uname -m
```

**Pour x86_64 :**
```bash
mkdir -p ~/.docker/cli-plugins
curl -SL https://github.com/docker/buildx/releases/download/v0.17.0/buildx-v0.17.0.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx
```

**Pour aarch64 (ARM / Graviton) :**
```bash
mkdir -p ~/.docker/cli-plugins
curl -SL https://github.com/docker/buildx/releases/download/v0.17.0/buildx-v0.17.0.linux-arm64 -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx
```

### 4.6 Vérification

```bash
docker --version
docker compose version
docker buildx version
```

---

## 5. Cloner le repo et déployer

```bash
git clone https://github.com/Daniax18/devops-iac-starter.git
cd devops-iac-starter
git checkout develop
# create .env necessary from .env.example format
nano .env
docker compose up --build
```

> Le premier build peut prendre 10-20 minutes (téléchargement des images, compilation Java / dotnet / npm).

---

## 6. Vérifier les containers

```bash
docker compose ps
```

Repérer les ports exposés dans la colonne `PORTS`, exemple : `0.0.0.0:8080->80/tcp`

---

## 7. Ouvrir les ports dans AWS

1. Console AWS > EC2 > ton instance > onglet **Security**
2. Cliquer sur le **Security Group**
3. **Inbound rules** > **Edit inbound rules**
4. Add rule : `Custom TCP` + port applicatif + Source `0.0.0.0/0`
5. **Save rules**

> 💡 Les règles s'appliquent en temps réel, pas besoin de redémarrer l'instance.

---

## 8. Accéder à l'application

```bash
curl ifconfig.me
```

Ouvrir dans le navigateur : `http://<IP_PUBLIQUE>:8080`

---

## 9. Connexion à PostgreSQL avec DBeaver

### 9.1 Avec les ports PostgreSQL dans docker-compose.yml

```yaml
authentification-db:
  ports:
    - "5433:5432"

product-db:
  ports:
    - "5434:5432"
```

### 9.2 Ouvrir les ports dans AWS Security Group

- Port `5433` → `authentication_db`
- Port `5434` → `product_db`
- Source : `0.0.0.0/0`

### 9.3 Paramètres DBeaver

| Base | Host | Port | Database | Username | Password |
|------|------|------|----------|----------|----------|
| Auth | `<IP_EC2>` | 5433 | authentication_db | postgres | postgres |
| Product | `<IP_EC2>` | 5434 | product_db | postgres | postgres |

---

## 10. Commandes utiles

| Commande | Description |
|----------|-------------|
| `docker compose ps` | Voir les containers et ports |
| `docker compose up -d --build` | Builder et démarrer en arrière-plan |
| `docker compose down` | Arrêter tous les containers |
| `docker compose logs -f` | Voir les logs en temps réel |
| `docker system prune -f` | Nettoyer les images/containers inutilisés |
| `tmux attach -t install` | Reprendre la session tmux |
| `curl ifconfig.me` | Obtenir l'IP publique de l'instance |

