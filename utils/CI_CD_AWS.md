# Guide CI/CD AWS EC2

Objectif : un `push` sur `develop` lance la CI puis redéploie automatiquement l'application sur l'instance EC2.

## 1. Principe retenu

- **CI** : GitHub Actions compile le front Angular, teste le gateway Spring Boot, build les services .NET et valide `docker-compose.yml`
- **CD** : si la CI passe, GitHub Actions ouvre une connexion SSH vers l'EC2 et exécute le script [`scripts/deploy-ec2.sh`](../scripts/deploy-ec2.sh)
- **Déploiement EC2** : le script se place dans le repo cloné sur l'instance, récupère la branche `develop`, puis lance `docker compose up -d --build --remove-orphans`

Cette approche colle bien à votre lab actuel : on garde le même serveur EC2 et les mêmes commandes Docker, mais elles sont déclenchées automatiquement après chaque push.

## 2. Préparer l'instance EC2

Suivre d'abord le guide manuel existant : [`utils/Manual_deploy_AWS.md`](./Manual_deploy_AWS.md)

Une fois Docker, Git et Buildx installés sur l'instance :

```bash
git clone https://github.com/<votre-org-ou-user>/product-iac-cloud.git
cd product-iac-cloud
git checkout develop
cp .env.example .env
```

Puis compléter le fichier `.env` avec vos vraies valeurs :

```bash
nano .env
```

Premier démarrage manuel recommandé pour valider le serveur :

```bash
docker compose up -d --build
docker compose ps
```

## 3. Secrets GitHub à créer

Dans GitHub : `Settings -> Secrets and variables -> Actions`

Créer ces secrets de repository :

- `EC2_HOST` : IP publique ou DNS public de l'instance
- `EC2_USER` : utilisateur SSH, souvent `ubuntu`
- `EC2_SSH_PRIVATE_KEY` : contenu complet de la clé privée SSH utilisée pour se connecter
- `EC2_DEPLOY_PATH` : chemin absolu du repo sur l'instance, par exemple `/home/ubuntu/product-iac-cloud`

Option utile mais non obligatoire :

- créer un environnement GitHub nommé `develop` pour visualiser les déploiements

## 4. Workflow ajouté au repo

Le workflow est dans [`.github/workflows/ci-cd-develop.yml`](../.github/workflows/ci-cd-develop.yml)

Déclencheurs :

- `push` sur `develop`
- lancement manuel via `workflow_dispatch`

Étapes CI :

- build du front `Front`
- test Maven du `Gateway`
- build .NET de `Authentification`
- build .NET de `Product`
- validation du fichier `docker-compose.yml`

Étape CD :

- connexion SSH à l'EC2
- exécution du script de déploiement

## 5. Script de déploiement

Le script est dans [`scripts/deploy-ec2.sh`](../scripts/deploy-ec2.sh)

Il fait :

```bash
git fetch origin develop
git checkout develop
git pull --ff-only origin develop
docker compose up -d --build --remove-orphans
docker image prune -f
docker compose ps
```

Le script échoue volontairement si :

- le chemin de déploiement n'existe pas
- le repo n'est pas cloné sur l'instance
- le fichier `.env` n'existe pas encore

## 6. Test bout en bout

1. pousser les changements sur `develop`
2. ouvrir l'onglet `Actions` sur GitHub
3. vérifier que le job `Build and validate` passe
4. vérifier que le job `Deploy to AWS EC2` passe
5. ouvrir `http://<IP_EC2>:8080`

## 7. Si vous refaites le lab

Comme vous avez déjà sauvegardé vos commandes, vous pourrez simplement :

1. recréer l'EC2
2. réinstaller Docker/Git/Buildx
3. recloner le repo
4. remettre le `.env`
5. reconfigurer les secrets GitHub avec la nouvelle IP et la clé SSH

Après ça, un simple changement poussé sur `develop` relancera tout automatiquement.
