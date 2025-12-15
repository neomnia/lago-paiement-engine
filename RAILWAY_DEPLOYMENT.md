# 🚂 Guide de déploiement Railway pour Lago

## ⚠️ Problème identifié

Railway Railpack ne peut pas construire automatiquement ce projet car :
1. **Git Submodules** : Les dossiers `api/` et `front/` sont des submodules Git vides
2. **Structure monorepo** : Plusieurs services dans le même dépôt
3. **Pas de configuration Railway** à la racine

## ✅ Solutions implémentées

### Fichiers créés :

1. **`Dockerfile`** (racine) - Copie du Dockerfile principal
2. **`railway.toml`** - Configuration Railway (format TOML)
3. **`railway.json`** - Configuration Railway (format JSON)

## 🔧 Actions requises AVANT le déploiement

### 1. Initialiser les Git Submodules

Le projet utilise des submodules pour `api` et `front`. Railway doit pouvoir les cloner :

```bash
# En local, pour tester
git submodule update --init --recursive
```

**Sur Railway** : Configurez les variables d'environnement pour les submodules :
- Railway détecte automatiquement `.gitmodules` mais peut nécessiter des clés SSH

### 2. Configurer Railway pour les submodules

Dans le dashboard Railway, sous "Settings" → "Build" :
- Activez "Use Git Submodules" si disponible
- OU ajoutez une commande de build personnalisée :

```bash
git submodule update --init --recursive && docker build -f Dockerfile .
```

## 🎯 Configuration Railway recommandée

### Architecture multi-services

Railway supporte le déploiement de plusieurs services depuis le même dépôt. Je recommande de créer **plusieurs services Railway** :

#### Service 1 : API + Frontend (application principale)
```toml
# railway.toml (déjà créé)
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"
```

**Variables d'environnement requises** :
```bash
# Base de données (créez un service PostgreSQL Railway)
DATABASE_URL=${{Postgres.DATABASE_URL}}

# Redis (créez un service Redis Railway)  
REDIS_URL=${{Redis.REDIS_URL}}

# Secrets (à générer)
SECRET_KEY_BASE=<générer avec: openssl rand -hex 64>
LAGO_RSA_PRIVATE_KEY=<générer clé RSA>
LAGO_ENCRYPTION_PRIMARY_KEY=<openssl rand -hex 32>
LAGO_ENCRYPTION_DETERMINISTIC_KEY=<openssl rand -hex 32>
LAGO_ENCRYPTION_KEY_DERIVATION_SALT=<openssl rand -hex 32>

# URLs
LAGO_FRONT_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
LAGO_API_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}/api

# Configuration
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
LAGO_DISABLE_SIGNUP=false
```

#### Service 2 : Events Processor (optionnel - Go)
```json
{
  "build": {
    "builder": "dockerfile",
    "dockerfilePath": "events-processor/Dockerfile"
  }
}
```

### Services Railway à créer

1. **PostgreSQL** : Base de données managée Railway
   - Taille : Standard ou Pro
   - Version : PostgreSQL 15+

2. **Redis** : Cache managé Railway
   - Taille : Standard

3. **Application Lago** : Service principal
   - Builder : Dockerfile
   - Port : 80 (exposé automatiquement)

4. **Events Processor** (optionnel)
   - Builder : Dockerfile events-processor
   - Port : Selon configuration

## 🚨 Problèmes potentiels et solutions

### Problème 1 : Submodules vides

**Symptôme** :
```
COPY ./api ./api
# Erreur: source not found
```

**Solution** :
- Vérifier que Railway clone les submodules
- Alternative : Forker et merger les submodules dans le repo principal

### Problème 2 : Build timeout

Railway a un timeout de build. Si le build est trop long :

**Solution** :
```toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
healthcheckTimeout = 600  # 10 minutes
```

### Problème 3 : Mémoire insuffisante

Le build nécessite beaucoup de RAM (front build + Ruby gems + Rust).

**Solution** :
- Utiliser un plan Railway avec plus de RAM (Pro ou Team)
- Ou simplifier le build en utilisant des images pré-construites

### Problème 4 : Multi-stage build trop complexe

**Solution alternative** : Utiliser les images Docker Hub officielles :

```dockerfile
# Dockerfile simplifié pour Railway
FROM getlago/api:v1.35.0

# Configuration Railway
ENV PORT=3000
EXPOSE 3000

CMD ["./scripts/start.api.sh"]
```

## 🎯 Configuration Railway step-by-step

### Étape 1 : Créer le projet Railway

```bash
# Installer Railway CLI
npm i -g @railway/cli

# Se connecter
railway login

# Créer un projet
railway init
```

### Étape 2 : Ajouter PostgreSQL

Dans Railway Dashboard :
1. Cliquer "New" → "Database" → "PostgreSQL"
2. Copier `DATABASE_URL`
3. L'utiliser dans les variables d'environnement

### Étape 3 : Ajouter Redis

1. Cliquer "New" → "Database" → "Redis"
2. Copier `REDIS_URL`

### Étape 4 : Configurer le service principal

1. "New" → "GitHub Repo" → Sélectionner votre repo
2. Settings → Variables → Ajouter toutes les variables d'environnement
3. Settings → Build :
   - Builder : Dockerfile
   - Dockerfile Path : `Dockerfile`
   - Enable Git Submodules : ✅

### Étape 5 : Générer les secrets

```bash
# SECRET_KEY_BASE
openssl rand -hex 64

# Clés de chiffrement
openssl rand -hex 32

# Clé RSA (format base64)
openssl genrsa 2048 | base64 -w 0
```

### Étape 6 : Déployer

```bash
railway up
```

## 📊 Monitoring

Railway fournit :
- Logs en temps réel
- Métriques (CPU, RAM, Network)
- Alertes

Accès : Dashboard Railway → Votre service → "Observability"

## 💰 Coûts estimés Railway

Pour Lago en production :

| Service | Plan | RAM | Prix/mois (USD) |
|---------|------|-----|-----------------|
| Lago App | Pro | 8GB | ~$20 |
| PostgreSQL | Standard | 2GB | ~$10 |
| Redis | Standard | 512MB | ~$5 |
| **Total** | | | **~$35-40** |

## 🔄 Alternative : Utiliser les images Docker Hub

Si les submodules posent problème, créez ce Dockerfile simple :

```dockerfile
# Dockerfile.railway - Build simplifié avec images officielles
FROM getlago/api:v1.35.0 AS api
FROM getlago/front:v1.35.0 AS front

# Image finale avec nginx comme reverse proxy
FROM nginx:alpine

# Copier le frontend
COPY --from=front /usr/share/nginx/html /usr/share/nginx/html

# Configuration nginx pour proxy vers API
COPY nginx-railway.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
```

Ceci évite le problème des submodules mais nécessite de gérer API et Front séparément.

## 🆘 Support

Si le problème persiste :
1. Vérifier les logs Railway : `railway logs`
2. Tester le build localement : `docker build -f Dockerfile .`
3. Consulter la doc Railway : https://docs.railway.app
4. Support Railway : https://railway.app/help

## 📝 Checklist finale

- [ ] Submodules initialisés
- [ ] `Dockerfile` à la racine
- [ ] `railway.toml` ou `railway.json` configuré
- [ ] Service PostgreSQL créé
- [ ] Service Redis créé
- [ ] Toutes les variables d'environnement définies
- [ ] Secrets générés et configurés
- [ ] Domaine configuré (optionnel)
- [ ] Build testé localement
- [ ] Déployé sur Railway

---

**Note importante** : Le problème actuel vient des submodules Git vides (`api/` et `front/`). Railway doit pouvoir les cloner automatiquement ou vous devez les merger dans le repo principal.
