# DEVOPS-IAC-STARTER 🚀

Déploiement automatisé multi-client avec **Ansible** et **Terraform** sur Docker en localhost.

---

## Structure du projet

```
DEVOPS-IAC-STARTER/
├── ansible/
│   ├── vars/
│   │   ├── client_a.yml     # Variables Client A
│   │   └── client_b.yml     # Variables Client B
│   ├── inventory.ini        # Définit localhost comme cible
│   └── playbook.yml         # Orchestrateur principal
│
├── terraform/
│   ├── .terraform/          # Provider Docker (auto-généré)
│   ├── states/
│   │   ├── clienta.tfstate  # State isolé Client A
│   │   └── clientb.tfstate  # State isolé Client B
│   ├── main.tf              # Crée les conteneurs Docker
│   ├── variables.tf         # Déclare les variables
│   └── terraform.tfvars     # Valeurs injectées par Ansible
│
├── Authentification/        # Service Auth .NET + PostgreSQL
├── Front/                   # Angular + Nginx
├── Gateway/                 # Spring Cloud Gateway Java
└── Product/                 # Service Product .NET + PostgreSQL
```

---

## Rôle de chaque fichier

### Ansible

| Fichier | Utilité |
|---|---|
| `inventory.ini` | Indique à Ansible de travailler en localhost sans SSH |
| `vars/client_a.yml` | Toutes les variables du Client A (ports, DB, JWT, nom...) |
| `vars/client_b.yml` | Mêmes variables mais pour Client B avec des ports différents |
| `playbook.yml` | Orchestre tout : injecte les variables, build les images, appelle Terraform |

### Terraform

| Fichier | Utilité |
|---|---|
| `main.tf` | Crée les 6 conteneurs Docker par client avec leurs configs |
| `variables.tf` | Déclare toutes les variables que Terraform attend |
| `terraform.tfvars` | Fichier généré par Ansible avec les valeurs du client en cours |
| `states/clienta.tfstate` | Mémorise l'état des ressources Client A |
| `states/clientb.tfstate` | Mémorise l'état des ressources Client B |

---

## Ce que fait le playbook étape par étape

```
1. Injecte les variables dans environment.ts         (Angular)
2. Injecte les variables dans nginx.conf             (Nginx)
3. Injecte les variables dans application.properties (Gateway)
4. Build image Front    → clienta-front:latest
5. Build image Auth     → clienta-auth:latest
6. Build image Gateway  → clienta-gateway:latest
7. Build image Product  → clienta-product:latest
8. Génère terraform.tfvars avec les valeurs du client
9. Terraform init       → télécharge le provider Docker
10. Terraform apply     → crée les 6 conteneurs
11. Vérifie les conteneurs actifs
```

---

## Installation

```bash
# Mise à jour système
sudo apt update && sudo apt upgrade -y

# Ansible
sudo apt install ansible -y
ansible-galaxy collection install community.docker

# Terraform
sudo apt install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y
```

---

## Commandes

### Déploiement

```bash
# Déployer Client A
ansible-playbook ansible/playbook.yml -e @ansible/vars/client_a.yml

# Déployer Client B
ansible-playbook ansible/playbook.yml -e @ansible/vars/client_b.yml
```

### Vérification

```bash
# Voir tous les conteneurs
docker ps | grep client

# Logs d'un service
docker logs clienta-front-service
docker logs clienta-gateway-service
docker logs clienta-auth-service
```

### Nettoyage

```bash
# Détruire un client
cd terraform && terraform destroy -auto-approve \
  -state=states/clienta.tfstate && cd ..

# Supprimer les images
docker rmi clienta-front:latest clienta-auth:latest \
           clienta-gateway:latest clienta-product:latest
```

---

## Ports par client

| Service | Client A | Client B |
|---|---|---|
| Frontend Angular | 8080 | 8180 |
| Gateway Java | 8081 | 8181 |
| Auth DB PostgreSQL | 5433 | 5533 |
| Product Service | 5001 | 5101 |
| Product DB PostgreSQL | 5434 | 5534 |

### Accès navigateur

```
Client A → http://localhost:8080
Client B → http://localhost:8180
```

---

## Ajouter un nouveau client

**1. Créer le fichier vars**
```bash
cp ansible/vars/client_a.yml ansible/vars/client_c.yml
```

**2. Modifier les valeurs dans `client_c.yml`**
```yaml
client_name: "Entreprise C"
client_prefix: "clientc"
front_port: "8280"
gateway_port: "8281"
auth_db_port: "5633"
product_port: "5201"
product_db_port: "5634"
auth_db_password: "clientc_auth_pass"
auth_db_name: "clientc_authentication_db"
product_db_password: "clientc_product_pass"
product_db_name: "clientc_product_db"
jwt_secret: "clientc-secret-change-me-in-production"
```

**3. Déployer**
```bash
ansible-playbook ansible/playbook.yml -e @ansible/vars/client_c.yml
```

---

## Modifier une variable client

Par exemple changer le nom du Client A :

**1. Modifier `ansible/vars/client_a.yml`**
```yaml
client_name: "Nouveau Nom Entreprise A"
```

**2. Redéployer**
```bash
# Détruire l'ancien déploiement
cd terraform && terraform destroy -auto-approve -state=states/clienta.tfstate && cd ..

# Supprimer les anciennes images
docker rmi clienta-front:latest clienta-auth:latest clienta-gateway:latest clienta-product:latest

# Relancer
ansible-playbook ansible/playbook.yml -e @ansible/vars/client_a.yml
```

---

## Modifier le code source

Si tu modifies le code dans `Front/`, `Gateway/`, `Authentification/` ou `Product/` :

```bash
# Supprimer l'image concernée (exemple : Front modifié)
docker rmi clienta-front:latest

# Redéployer — Ansible rebuildera automatiquement
ansible-playbook ansible/playbook.yml -e @ansible/vars/client_a.yml
```

---

## Templates Jinja2

Les fichiers `.j2` sont des templates Ansible qui injectent les variables client avant le build Docker.

| Template | Destination | Variables injectées |
|---|---|---|
| `Front/src/environments/environment.ts.j2` | `environment.ts` | `client_name`, `client_siege`, `front_port` |
| `Front/nginx.conf.j2` | `nginx.conf` | `client_prefix` |
| `Gateway/src/main/resources/application.properties.j2` | `application.properties` | `client_prefix`, `jwt_secret` |
