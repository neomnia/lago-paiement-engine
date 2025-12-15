# 🎯 Configuration Railway Dashboard - Guide Visuel

## ⚠️ Problème actuel

Railway utilise **Railpack** au lieu du **Dockerfile** → Build échoue

## ✅ Solution : Configuration manuelle dans Railway Dashboard

### 📍 Étape 1 : Accéder aux paramètres

1. Ouvrez votre projet Railway
2. Cliquez sur votre service "lago" (ou le nom que vous avez donné)
3. Cliquez sur l'onglet **"Settings"**

---

### 📍 Étape 2 : Configurer le Build

Dans la section **"Build"** :

```
┌─────────────────────────────────────────┐
│ Build Settings                          │
├─────────────────────────────────────────┤
│                                         │
│ Builder                                 │
│ ┌─────────────────────────────────┐   │
│ │ Dockerfile                   ▼  │   │ ← SÉLECTIONNEZ "Dockerfile"
│ └─────────────────────────────────┘   │
│                                         │
│ Root Directory                          │
│ ┌─────────────────────────────────┐   │
│ │ /                               │   │ ← Laissez "/"
│ └─────────────────────────────────┘   │
│                                         │
│ Dockerfile Path                         │
│ ┌─────────────────────────────────┐   │
│ │ Dockerfile.railway-simple       │   │ ← IMPORTANT: Écrivez exactement ceci
│ └─────────────────────────────────┘   │
│                                         │
│ Build Command (optional)                │
│ ┌─────────────────────────────────┐   │
│ │                                 │   │ ← Laissez vide
│ └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**⚠️ ATTENTION** : 
- Ne sélectionnez PAS "Nixpacks" ou "Railpack"
- Le Dockerfile Path doit être **exactement** : `Dockerfile.railway-simple`

---

### 📍 Étape 3 : Configurer le Deploy (optionnel)

Dans la section **"Deploy"** :

```
┌─────────────────────────────────────────┐
│ Deploy Settings                         │
├─────────────────────────────────────────┤
│                                         │
│ Custom Start Command (optional)         │
│ ┌─────────────────────────────────┐   │
│ │ ./scripts/start.api.sh          │   │ ← Optionnel (déjà dans Dockerfile)
│ └─────────────────────────────────┘   │
│                                         │
│ Health Check Path                       │
│ ┌─────────────────────────────────┐   │
│ │ /health                         │   │
│ └─────────────────────────────────┘   │
│                                         │
│ Health Check Timeout                    │
│ ┌─────────────────────────────────┐   │
│ │ 300                             │   │
│ └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

---

### 📍 Étape 4 : Sauvegarder et Redéployer

1. Cliquez **"Save"** en bas de la page (si disponible)
2. Retournez à l'onglet **"Deployments"**
3. Cliquez **"Redeploy"** → **"Confirm"**
4. OU cliquez **"New Deployment"**

---

## 🔍 Vérification du Build

Une fois le nouveau déploiement lancé, vérifiez les logs :

```
✅ Bon signe - Vous devriez voir :
   "Building with Dockerfile"
   "FROM getlago/api:v1.35.0"
   "Successfully built"

❌ Mauvais signe - Si vous voyez encore :
   "Railpack 0.15.1"
   "Railpack could not determine..."
   → Retournez à l'étape 2
```

---

## 🎯 Checklist de vérification

Avant de cliquer "Redeploy", vérifiez :

- [ ] Builder = **"Dockerfile"** (pas Nixpacks)
- [ ] Root Directory = **"/"**
- [ ] Dockerfile Path = **"Dockerfile.railway-simple"**
- [ ] Variables d'environnement configurées (DATABASE_URL, REDIS_URL, etc.)
- [ ] Services PostgreSQL et Redis créés et liés

---

## 🆘 Si ça ne marche toujours pas

### Option A : Utiliser directement l'image Docker

Si Railway refuse d'utiliser le Dockerfile :

1. **Settings** → **Build**
2. **Builder** : Sélectionnez **"Image"**
3. **Image** : `getlago/api:v1.35.0`
4. **Custom Start Command** : `./scripts/start.api.sh`

Cela skip complètement le build et utilise l'image pré-construite !

### Option B : Railway CLI

```bash
# Installer Railway CLI
npm i -g @railway/cli

# Se connecter
railway login

# Lier au projet
railway link

# Configurer via CLI
railway variables set DOCKERFILE_PATH=Dockerfile.railway-simple

# Déployer
railway up
```

---

## 📸 Capture d'écran de référence

Voici à quoi devrait ressembler votre configuration :

```
Settings > Build

Builder: [Dockerfile        ▼]
Root Directory: [/                    ]
Dockerfile Path: [Dockerfile.railway-simple]

[Save]
```

---

## ✅ Après le succès du build

Une fois que le build réussit :

1. Vérifiez que l'application démarre : `railway logs`
2. Testez l'URL publique : `https://your-service.railway.app/health`
3. Créez votre premier utilisateur admin
4. Configurez un domaine custom (optionnel)

---

**Temps estimé** : 5 minutes
**Difficulté** : Facile (configuration manuelle)
