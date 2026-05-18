# IaC Deploy — Terraform + Ansible + GitHub Actions

Déploiement automatisé d'une application multi-services Docker sur AWS EC2, déclenché par un tag Git sur la branche `main`.

---

## Stack technique

- **Terraform** — provisionne l'infrastructure AWS (EC2, Security Group, Key Pair)
- **Ansible** — configure l'EC2 et déploie l'application via Docker Compose
- **GitHub Actions** — orchestre le pipeline CD au push d'un tag `v*`
- **AWS Academy** — hébergement cloud (us-east-1)

---

## Architecture de l'application

L'application est composée de 5 services Docker :

| Service | Port exposé | Description |
|---|---|---|
| `front-service` | 5000 | Frontend |
| `gateway-service` | 8080 | API Gateway |
| `authentification-service` | 5002 | Service d'authentification |
| `authentification-db` | 5433 | PostgreSQL pour l'auth |
| `product-service` | 5001 | Service produits |
| `product-db` | 5434 | PostgreSQL pour les produits |

---

## Structure du projet

```
.
├── .github/
│   └── workflows/
│       └── cd.yml                  # Pipeline CD GitHub Actions
├── terraform/
│   ├── main.tf                     # Ressources AWS (EC2, SG, Key Pair)
│   ├── variables.tf                # Variables Terraform
│   ├── outputs.tf                  # Outputs (IP publique)
│   └── terraform.tfvars.example   # Exemple de configuration locale
├── ansible/
│   ├── playbook.yml                # Point d'entrée Ansible
│   ├── templates/
│   │   └── .env.j2                 # Template du fichier .env
│   └── roles/
│       ├── docker/
│       │   └── tasks/
│       │       └── main.yml        # Installation de Docker
│       └── app/
│           └── tasks/
│               └── main.yml        # Déploiement de l'application
└── README.md
```

---

## Infrastructure AWS

Terraform crée les ressources suivantes dans le VPC par défaut d'AWS Academy :

- **EC2** — instance `t3.small` Ubuntu 22.04 LTS
- **Security Group** — ports ouverts : 22 (SSH), 5000 (frontend), 8080 (gateway)
- **Key Pair** — clé SSH générée depuis le secret GitHub
- **State Terraform** — stocké dans un bucket S3

---

## Prérequis

### 1. Générer la paire de clés SSH (une seule fois en local)

```bash
ssh-keygen -t ed25519 -C "github-cd-deploy" -f ./iac-deploy -N ""
```

Cela génère deux fichiers :
- `iac-deploy` — clé privée → à mettre dans le secret GitHub `EC2_SSH_PRIVATE_KEY_DEPLOY`
- `iac-deploy.pub` — clé publique → utilisée automatiquement par Terraform

### 2. Créer le bucket S3 (à chaque session AWS Academy)

Depuis le terminal AWS Academy ou AWS CLI configuré :

```bash
aws s3 mb s3://iac-terraform-state-bucket --region us-east-1
```

Ou depuis la console AWS : **S3 → Create bucket → `iac-terraform-state-bucket` → us-east-1**

---

## Secrets GitHub à configurer

Dans **Settings → Secrets and variables → Actions** de votre repository :

### Credentials AWS (à mettre à jour à chaque session AWS Academy)

| Secret | Où le trouver |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS Academy → AWS Details → AWS CLI |
| `AWS_SECRET_ACCESS_KEY` | AWS Academy → AWS Details → AWS CLI |
| `AWS_SESSION_TOKEN` | AWS Academy → AWS Details → AWS CLI |

### Clé SSH

| Secret | Description |
|---|---|
| `EC2_SSH_PRIVATE_KEY_DEPLOY` | Contenu de la clé privée `iac-deploy` générée en local |

### Variables d'application

| Secret | Exemple |
|---|---|
| `AUTH_DB_USER` | `postgres` |
| `AUTH_DB_PASSWORD` | `monmotdepasse` |
| `AUTH_DB_NAME` | `authentication_db` |
| `PRODUCT_DB_USER` | `postgres` |
| `PRODUCT_DB_PASSWORD` | `monmotdepasse` |
| `PRODUCT_DB_NAME` | `product_db` |
| `JWT_SECRET` | `ma-cle-jwt-secrete` |
| `JWT_ISSUER` | `AuthAPI` |
| `JWT_AUDIENCE` | `AuthAPIUsers` |
| `JWT_EXPIRY_MINUTES` | `60` |

---

## Pipeline CD

Le pipeline se déclenche automatiquement sur un push de tag `v*` sur la branche `main`.

### Étapes

```
push tag v*
    │
    ▼
check-branch
Vérifie que le tag est bien sur main
    │
    ▼
terraform
1. Restaure la clé SSH depuis les secrets
2. Configure les credentials AWS
3. Supprime l'ancienne Key Pair si elle existe
4. terraform init → plan → apply
5. Récupère l'IP publique de l'EC2
    │
    ▼
ansible
1. Attend que le port SSH soit disponible
2. Génère l'inventory avec l'IP de l'EC2
3. Joue le playbook :
   - role docker  → installe Docker sur l'EC2
   - role app     → clone le repo, génère le .env, lance docker compose
```

### Déclencher un déploiement

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## Accès à l'application

Après le déploiement, l'IP publique est visible dans :
- Les logs GitHub Actions à la fin du job Terraform
- La console AWS EC2

| Service | URL |
|---|---|
| Frontend | `http://<IP_PUBLIQUE>:5000` |
| Gateway | `http://<IP_PUBLIQUE>:8080` |

---

## Rôles Ansible

### `roles/docker`

Installe et configure Docker sur l'EC2 Ubuntu :

- Met à jour les paquets apt
- Ajoute le dépôt officiel Docker
- Installe `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-compose-plugin`
- Démarre le service Docker
- Ajoute l'utilisateur `ubuntu` au groupe docker
- Installe `git`

### `roles/app`

Déploie l'application :

- Crée le dossier `/opt/iac-app`
- Clone le repository au tag demandé (ou met à jour si déjà cloné)
- Génère le fichier `.env` depuis le template `templates/.env.j2` avec les secrets GitHub
- Lance `docker compose build --pull`
- Lance `docker compose down` puis `docker compose up -d`
- Vérifie que les containers sont healthy

---

## Gestion du fichier .env

Le fichier `.env` n'est jamais commité dans le repository. Le fonctionnement est le suivant :

1. `ansible/templates/.env.j2` est commité — c'est un template avec des variables `{{ }}` vides
2. Les vraies valeurs sont stockées dans les secrets GitHub
3. Au déploiement, Ansible génère le vrai `.env` sur l'EC2 en combinant le template et les secrets
4. Le `.env` final n'existe que sur le serveur

---

## Procédure à chaque nouvelle session AWS Academy

AWS Academy détruit toute l'infrastructure entre les sessions. À chaque reconnexion :

**1. Récupérer les nouveaux credentials AWS**

Aller sur **AWS Academy → AWS Details → AWS CLI** et copier les 3 valeurs.

**2. Mettre à jour les secrets GitHub**

Mettre à jour `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` et `AWS_SESSION_TOKEN` dans GitHub Secrets.

**3. Recréer le bucket S3**

```bash
aws s3 mb s3://iac-terraform-state-bucket --region us-east-1
```

**4. Pousser un tag pour tout recréer**

```bash
git tag v1.0.x
git push origin v1.0.x
```

Terraform recrée automatiquement l'EC2, le Security Group et la Key Pair. Ansible redéploie l'application.

---

## Erreurs fréquentes

### `Permission denied (publickey)` dans Ansible

Vérifier que `ansible_user=ubuntu` est bien défini dans le step "Generate Ansible inventory" du CD (et non `ec2-user` qui est l'utilisateur Amazon Linux).

### `permission denied while trying to connect to the docker API`

L'utilisateur n'a pas encore accès au socket Docker dans la session courante. Les tâches Docker Compose doivent utiliser `become: true` et `become_user: root`.

### `Key Pair already exists`

La Key Pair de la session précédente existe encore sur AWS. Le CD supprime automatiquement l'ancienne Key Pair avant le `terraform apply` :

```bash
aws ec2 delete-key-pair --key-name iac-deploy-key 2>/dev/null || true
```

### State Terraform incohérent

Si vous avez modifié des ressources manuellement depuis la console AWS, le state Terraform peut être désynchronisé. Dans ce cas, supprimez le state dans S3 et relancez un tag pour repartir d'un état propre.
