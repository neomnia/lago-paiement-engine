# 🚨 Résolution du problème Railway - Lago

## ❌ Erreur actuelle

```
✖ Railpack could not determine how to build the app.
⚠ Script start.sh not found
skipping 'Dockerfile' at 'connectors/Dockerfile' as it is not rooted at a valid path
```

## 🔍 Cause du problème

1. **Submodules Git vides** : `api/` et `front/` sont des submodules non initialisés
2. **Pas de Dockerfile à la racine** : Railway cherche à la racine
3. **Structure monorepo** : Plusieurs services dans un seul dépôt

## ✅ Solution IMMÉDIATE

### Option 1 : Utiliser l'image officielle (RAPIDE - Recommandé)

Changez le fichier de configuration Railway pour utiliser `Dockerfile.railway-simple` :

**Dans Railway Dashboard** :
1. Allez dans Settings → Build
2. Build Method : Dockerfile
3. Dockerfile Path : `Dockerfile.railway-simple`
4. Cliquez "Deploy"

**Ou modifiez `railway.toml`** :
```toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile.railway-simple"
```

### Option 2 : Initialiser les submodules

Si vous voulez utiliser le build complet :

1. **Localement** :
```bash
git submodule update --init --recursive
git add api/ front/
git commit -m "Initialize submodules"
git push
```

2. **Dans Railway** :
   - Settings → Build
   - Dockerfile Path : `Dockerfile`

### Option 3 : Fusionner les submodules (solution permanente)

```bash
# Supprimer les submodules
git submodule deinit -f api
git submodule deinit -f front
git rm -f api front
rm -rf .git/modules/api .git/modules/front

# Cloner les repos directement
git clone git@github.com:getlago/lago-api.git api
git clone git@github.com:getlago/lago-front.git front

# Supprimer les .git dans les sous-dossiers
rm -rf api/.git front/.git

# Committer
git add api/ front/ .gitmodules
git commit -m "Convert submodules to regular directories"
git push
```

## 🎯 Configuration Railway minimale

### Variables d'environnement CRITIQUES à définir :

```bash
# Base de données (ajoutez un service PostgreSQL Railway)
DATABASE_URL=${{Postgres.DATABASE_URL}}

# Redis (ajoutez un service Redis Railway)
REDIS_URL=${{Redis.REDIS_URL}}

# Secrets (GÉNÉREZ-LES MAINTENANT)
SECRET_KEY_BASE=<exécutez: openssl rand -hex 64>
LAGO_ENCRYPTION_PRIMARY_KEY=<exécutez: openssl rand -hex 32>
LAGO_ENCRYPTION_DETERMINISTIC_KEY=<exécutez: openssl rand -hex 32>
LAGO_ENCRYPTION_KEY_DERIVATION_SALT=<exécutez: openssl rand -hex 32>

# URLs
LAGO_FRONT_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
LAGO_API_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}/api

# Rails
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
PORT=3000
```

## 🚀 Steps pour déployer MAINTENANT

1. **Dans Railway Dashboard** :
   - Créez un service PostgreSQL
   - Créez un service Redis
   - Notez les URLs de connexion

2. **Dans votre service Lago** :
   - Settings → Variables
   - Ajoutez toutes les variables ci-dessus
   - Générez les secrets avec les commandes OpenSSL

3. **Changez le Dockerfile** :
   - Settings → Build → Dockerfile Path : `Dockerfile.railway-simple`

4. **Redéployez** :
   - Cliquez "Deploy" ou "Redeploy"

## 🧪 Test local avant Railway

```bash
# Option 1 : Test avec Docker Compose (recommandé)
docker compose up

# Option 2 : Test du build Dockerfile
docker build -f Dockerfile.railway-simple -t lago-test .
docker run -p 3000:3000 -e DATABASE_URL=... lago-test

# Option 3 : Test avec Railway CLI
railway up
```

## 🆘 Si ça ne marche toujours pas

### Vérifications :

```bash
# 1. Vérifier que les images officielles existent
docker pull getlago/api:v1.35.0
docker pull getlago/front:v1.35.0

# 2. Vérifier la structure du repo
ls -la
# Devrait afficher api/, front/, Dockerfile, railway.toml

# 3. Vérifier les submodules
git submodule status
# Si vides : suivre Option 3 ci-dessus
```

### Logs Railway :

```bash
# Via CLI
railway logs

# Ou dans Dashboard → Deployments → Cliquer sur le build raté
```

## 📞 Alternative : Contact support Railway

Si rien ne fonctionne :
1. Railway Discord : https://discord.gg/railway
2. Support ticket : help@railway.app
3. Mentionnez : "Monorepo with Git submodules issue"

## ✨ Checklist de résolution

- [ ] Créer service PostgreSQL Railway
- [ ] Créer service Redis Railway  
- [ ] Copier les URLs de connexion
- [ ] Générer les secrets (SECRET_KEY_BASE, etc.)
- [ ] Configurer toutes les variables d'environnement
- [ ] Changer Dockerfile path vers `Dockerfile.railway-simple`
- [ ] Redéployer
- [ ] Vérifier les logs
- [ ] Tester l'URL publique

## 🎉 Une fois déployé

1. Accédez à votre URL Railway
2. Créez le premier utilisateur admin
3. Testez les fonctionnalités de base
4. Configurez le domaine custom (optionnel)

---

**Temps estimé** : 15-30 minutes avec Option 1 (image officielle)
