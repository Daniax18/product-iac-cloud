# RDS — Bases de données PostgreSQL sur AWS

Documentation complète sur la gestion des bases de données RDS du projet, incluant la connexion via DBeaver, la vérification des containers Docker et les opérations courantes.

---

## Architecture

Les bases de données sont hébergées sur AWS RDS, séparées de l'EC2. Cela garantit que les données survivent indépendamment de l'infrastructure applicative.

```
Internet
    │
    ▼
EC2 (t3.small - Ubuntu)
├── front-service            :5000
├── gateway-service          :8080
├── authentification-service :5002  ──→  RDS iac-app-auth-db     (PostgreSQL 15)
└── product-service          :5001  ──→  RDS iac-app-product-db  (PostgreSQL 15)
```

### Instances RDS

| Identifiant | Base | Instance | Zone |
|---|---|---|---|
| `iac-app-auth-db` | `authentication_db` | db.t3.micro | us-east-1b |
| `iac-app-product-db` | `product_db` | db.t3.micro | us-east-1b |

---

## Sécurité réseau

Le Security Group RDS (`iac-app-rds-sg`) autorise uniquement le port `5432` depuis l'EC2. RDS n'est **pas accessible directement depuis internet** — vous devez passer par un tunnel SSH via l'EC2.

```
Votre machine  ──SSH──→  EC2  ──réseau privé AWS──→  RDS
```

---

## Connexion via DBeaver

### Prérequis

- [DBeaver Community](https://dbeaver.io/download/) installé
- La clé privée SSH `iac-deploy` disponible en local (`~/.ssh/iac-deploy` ou `C:\Users\USER\.ssh\iac-deploy`)
- L'IP publique de l'EC2 (visible dans les logs GitHub Actions ou AWS Console → EC2)
- Les endpoints RDS (visible dans les logs GitHub Actions ou AWS Console → RDS)

---

### Étape 1 — Ouvrir le tunnel SSH

Ouvrez un terminal et lancez la commande suivante. **Laissez ce terminal ouvert** pendant toute votre session.

**Pour la base Auth :**

```bash
# Linux / macOS
ssh -i ~/.ssh/iac-deploy -L 5433:<AUTH_DB_ENDPOINT>:5432 ubuntu@<IP_PUBLIQUE> -N

# Windows (PowerShell)
ssh -i C:\Users\USER\.ssh\iac-deploy -L 5433:<AUTH_DB_ENDPOINT>:5432 ubuntu@<IP_PUBLIQUE> -N
```

**Pour la base Product** (dans un deuxième terminal) :

```bash
# Linux / macOS
ssh -i ~/.ssh/iac-deploy -L 5434:<PRODUCT_DB_ENDPOINT>:5432 ubuntu@<IP_PUBLIQUE> -N

# Windows (PowerShell)
ssh -i C:\Users\USER\.ssh\iac-deploy -L 5434:<PRODUCT_DB_ENDPOINT>:5432 ubuntu@<IP_PUBLIQUE> -N
```

Le `-N` signifie que la commande ne fait qu'ouvrir le tunnel sans lancer de shell — c'est normal qu'il ne se passe rien de visible.

---

### Étape 2 — Configurer DBeaver

**New Connection → PostgreSQL**

**Base Auth :**

| Champ | Valeur |
|---|---|
| Host | `localhost` |
| Port | `5433` |
| Database | `authentication_db` |
| Username | `postgres` |
| Password | valeur de `AUTH_DB_PASSWORD` |

**Base Product :**

| Champ | Valeur |
|---|---|
| Host | `localhost` |
| Port | `5434` |
| Database | `product_db` |
| Username | `postgres` |
| Password | valeur de `PRODUCT_DB_PASSWORD` |

Cliquez **Test Connection** pour vérifier, puis **Finish**.

---

### Trouver les endpoints RDS

**Option 1 — Logs GitHub Actions**

À la fin du job Terraform :

```
auth_db_endpoint    = "iac-app-auth-db.xxxxxxxxx.us-east-1.rds.amazonaws.com"
product_db_endpoint = "iac-app-product-db.xxxxxxxxx.us-east-1.rds.amazonaws.com"
```

**Option 2 — Console AWS**

AWS Console → **RDS → Databases** → cliquez sur l'instance → section **Connectivity & security** → **Endpoint**.

---

## Vérification des containers Docker

### Se connecter à l'EC2

```bash
# Linux / macOS
ssh -i ~/.ssh/iac-deploy ubuntu@<IP_PUBLIQUE>

# Windows (PowerShell)
ssh -i C:\Users\USER\.ssh\iac-deploy ubuntu@<IP_PUBLIQUE>
```

---

### Commandes Docker utiles

**Voir l'état des containers :**

```bash
sudo docker compose -f /opt/iac-app/docker-compose.yml ps
```

Résultat attendu :

```
NAME                        STATUS
iac-app-front-service       Up
iac-app-gateway-service     Up
iac-app-authentification    Up
iac-app-product-service     Up
```

**Voir les logs d'un service :**

```bash
# Logs du service auth (migrations EF Core visibles ici)
sudo docker compose -f /opt/iac-app/docker-compose.yml logs authentification-service

# Logs du service product
sudo docker compose -f /opt/iac-app/docker-compose.yml logs product-service

# Suivre les logs en temps réel
sudo docker compose -f /opt/iac-app/docker-compose.yml logs -f authentification-service
```

**Redémarrer un service :**

```bash
sudo docker compose -f /opt/iac-app/docker-compose.yml restart authentification-service
sudo docker compose -f /opt/iac-app/docker-compose.yml restart product-service
```

**Redémarrer tous les services :**

```bash
sudo docker compose -f /opt/iac-app/docker-compose.yml down
sudo docker compose -f /opt/iac-app/docker-compose.yml up -d
```

**Vérifier les variables d'environnement d'un container :**

```bash
sudo docker compose -f /opt/iac-app/docker-compose.yml exec authentification-service env | grep ConnectionStrings
```

---

## Vérification des migrations EF Core

Les migrations s'exécutent automatiquement au démarrage de chaque service via `db.Database.Migrate()`. Pour vérifier qu'elles ont bien tourné :

**Option 1 — Dans les logs Docker :**

```bash
sudo docker compose -f /opt/iac-app/docker-compose.yml logs authentification-service | grep -i migrat
```

**Option 2 — Dans DBeaver :**

Connectez-vous à la base et vérifiez la table `__EFMigrationsHistory` — elle liste toutes les migrations appliquées.

```sql
SELECT * FROM "__EFMigrationsHistory";
```

**Option 3 — Via psql depuis l'EC2 :**

```bash
# Installer psql
sudo apt install postgresql-client -y

# Connexion à la base Auth
psql -h <AUTH_DB_ENDPOINT> -U postgres -d authentication_db

# Lister les tables
\dt

# Vérifier les migrations
SELECT * FROM "__EFMigrationsHistory";

# Quitter
\q
```


## Procédure à chaque session AWS Academy

RDS est recréé par Terraform à chaque nouvelle session (le state S3 disparaît). Les données sont donc perdues entre les sessions.

1. Mettre à jour les credentials AWS dans GitHub Secrets
2. Pousser un tag → Terraform recrée l'EC2 et les deux instances RDS
3. Les migrations EF Core recréent automatiquement les tables au démarrage des services
4. Mettre à jour les endpoints RDS dans vos tunnels SSH si vous utilisez DBeaver

---

## Dépannage

### Les tables n'existent pas dans DBeaver

Les migrations n'ont pas tourné. Redémarrez les services :

```bash
sudo docker compose -f /opt/iac-app/docker-compose.yml restart authentification-service product-service
```

### Permission denied (publickey) au SSH

La clé `iac-deploy` n'est pas trouvée. Vérifiez le chemin :

```bash
ls ~/.ssh/iac-deploy                      # Linux/macOS
ls C:\Users\USER\.ssh\iac-deploy          # Windows
```

Si elle n'existe pas, regénérez-la et mettez à jour le secret GitHub `EC2_SSH_PRIVATE_KEY_DEPLOY`.

### DBeaver ne se connecte pas

Vérifiez que le tunnel SSH est toujours ouvert dans votre terminal. Si le terminal a été fermé, relancez la commande tunnel.

### Un service est en état Restarting

```bash
sudo docker compose -f /opt/iac-app/docker-compose.yml logs <nom-du-service>
```

Regardez l'erreur dans les logs — c'est souvent un problème de connexion à RDS ou une variable d'environnement manquante.
