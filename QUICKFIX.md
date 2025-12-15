# ⚡ FIX RAPIDE - Railway ne trouve pas le Dockerfile

## 🎯 Le problème

Railway utilise **Railpack** au lieu du **Dockerfile** → ça ne marche pas

## ✅ La solution (2 minutes)

### Dans Railway Dashboard :

1. **Allez dans votre service** (cliquez dessus)
2. **Settings** (onglet en haut)
3. **Section "Build"** → Changez :
   
   ```
   Builder:          Dockerfile
   Dockerfile Path:  Dockerfile.railway-simple
   ```

4. **Retournez aux Deployments**
5. **Cliquez "Redeploy"**

C'est tout ! Railway va maintenant utiliser le Dockerfile au lieu de Railpack.

---

## 🔍 Comment savoir si ça marche ?

Dans les logs du build, vous devriez voir :

✅ **BON** :
```
Building with Dockerfile
FROM getlago/api:v1.35.0
```

❌ **MAUVAIS** (si vous voyez encore ça) :
```
Railpack 0.15.1
Railpack could not determine...
```

---

## 📋 Checklist finale

- [ ] Railway Dashboard ouvert
- [ ] Settings → Build
- [ ] Builder = "Dockerfile"
- [ ] Dockerfile Path = "Dockerfile.railway-simple"
- [ ] Redeploy cliqué
- [ ] Logs montrent "Building with Dockerfile"

---

## 🆘 Alternative si ça ne marche pas

Utilisez directement l'image Docker sans build :

**Settings → Build** :
- Builder: **Image**
- Image: `getlago/api:v1.35.0`
- Start Command: `./scripts/start.api.sh`

Ça évite complètement le problème de build !
