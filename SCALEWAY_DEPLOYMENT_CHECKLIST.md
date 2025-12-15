# ✅ Checklist de déploiement Lago sur Scaleway

## 📋 Résumé de l'analyse

Dépôt analysé : `lago-paiement-engine`  
Date : 15 décembre 2025  
Objectif : Déploiement production sur Scaleway

---

## 🏗️ Architecture actuelle

### Composants principaux
- **API Backend** : Rails application (getlago/api:v1.35.0 / v1.27.1)
- **Frontend** : React application (getlago/front:v1.35.0 / v1.27.1)
- **Base de données** : PostgreSQL 15-alpine (production) / 14-alpine (dev)
- **Cache/Queue** : Redis 7-alpine (production) / 6-alpine (dev)
- **Workers Sidekiq** : Multiple workers dédiés
  - Worker principal (concurrence: 20)
  - Events worker (concurrence: 20)
  - Billing worker (concurrence: 5)
  - PDF worker (concurrence: 5)
  - Webhook worker (concurrence: 10)
  - Clock worker (concurrence: 20)
- **PDF Generator** : Gotenberg (lago-gotenberg:8.15)
- **Reverse Proxy** : Traefik v3.3 avec Let's Encrypt
- **Monitoring** : Portainer CE

### Workers additionnels optionnels
- Events processor (Go application)
- Analytics worker
- Kafka (pour event streaming)
- ClickHouse (pour analytics)

---

## ⚠️ Points critiques identifiés

### 🔴 Configuration manquante/à ajuster

#### 1. Variables d'environnement obligatoires

**Sécurité (CRITIQUE)**
```bash
SECRET_KEY_BASE=                    # À générer (64 caractères hex)
LAGO_RSA_PRIVATE_KEY=              # Clé RSA pour JWT
LAGO_ENCRYPTION_PRIMARY_KEY=        # Clé de chiffrement principale
LAGO_ENCRYPTION_DETERMINISTIC_KEY=  # Clé de chiffrement déterministe
LAGO_ENCRYPTION_KEY_DERIVATION_SALT= # Salt pour dérivation de clé
```

**Base de données**
```bash
POSTGRES_DB=lago
POSTGRES_USER=lago
POSTGRES_PASSWORD=                  # À définir (NE PAS laisser 'changeme')
POSTGRES_HOST=db                    # ou IP Scaleway Managed Database
POSTGRES_PORT=5432
```

**Redis**
```bash
REDIS_HOST=redis                    # ou IP Scaleway Managed Redis
REDIS_PORT=6379
REDIS_PASSWORD=                     # À définir pour la sécurité
```

**Domaine et SSL**
```bash
LAGO_DOMAIN=                        # votre-domaine.com
LAGO_ACME_EMAIL=                    # email@domaine.com (pour Let's Encrypt)
LAGO_FRONT_URL=https://votre-domaine.com
LAGO_API_URL=https://votre-domaine.com/api
```

**Portainer (si utilisé)**
```bash
PORTAINER_USER=admin
PORTAINER_PASSWORD=                 # À définir (NE PAS laisser 'changeme')
```

#### 2. Stockage des fichiers

**Option 1 : Scaleway Object Storage (RECOMMANDÉ)**
```bash
LAGO_USE_AWS_S3=true
LAGO_AWS_S3_ACCESS_KEY_ID=         # Access key Scaleway
LAGO_AWS_S3_SECRET_ACCESS_KEY=     # Secret key Scaleway
LAGO_AWS_S3_REGION=fr-par          # ou nl-ams, pl-waw
LAGO_AWS_S3_BUCKET=lago-storage
LAGO_AWS_S3_ENDPOINT=https://s3.fr-par.scw.cloud  # Endpoint Scaleway
```

**Option 2 : Volume local (moins recommandé pour la production)**
- Utiliser un volume Scaleway Block Storage monté

#### 3. Configuration SSL/TLS

**Let's Encrypt (actuellement en mode staging)**
```yaml
# Dans docker-compose.production.yml, ligne 87 :
- "--certificatesresolvers.letsencrypt.acme.caServer=https://acme-staging-v02.api.letsencrypt.org/directory"
```

**⚠️ ACTION REQUISE** : Changer en mode production
```yaml
- "--certificatesresolvers.letsencrypt.acme.caServer=https://acme-v02.api.letsencrypt.org/directory"
# OU supprimer cette ligne pour utiliser le serveur par défaut
```

#### 4. SMTP/Email

```bash
LAGO_FROM_EMAIL=noreply@votre-domaine.com
LAGO_SMTP_ADDRESS=                  # SMTP Scaleway Transactional Email
LAGO_SMTP_PORT=587
LAGO_SMTP_USERNAME=                 # Credentials Scaleway
LAGO_SMTP_PASSWORD=
```

---

## 🎯 Recommandations pour Scaleway

### 1. Infrastructure Scaleway recommandée

#### Option A : Instances + Services managés (RECOMMANDÉ)
- **Compute** : Instance Production Optimized (PRO2-M ou supérieur)
  - 4 vCPU, 8 GB RAM minimum
  - Scaleway Elements SSD
- **Base de données** : Managed Database for PostgreSQL
  - Plan High Availability
  - Version PostgreSQL 15
  - Backup automatique activé
- **Cache** : Managed Database for Redis
  - Plan avec persistance
- **Stockage** : Object Storage (S3-compatible)
  - Bucket dédié avec lifecycle policies
- **Réseau** : 
  - Elastic IP pour l'instance
  - DNS géré avec domaine pointant vers l'IP
  - Private Network pour communication interne

#### Option B : Kubernetes (Scaleway Kapsule)
- Pour haute disponibilité et scaling automatique
- Nécessite adaptation des docker-compose en manifests K8s

### 2. Volumes et persistance

**Volumes Docker à persister**
```yaml
volumes:
  lago_rsa_data:          # Clés RSA - CRITIQUE
  lago_postgres_data:     # Si DB locale (non recommandé)
  lago_redis_data:        # Si Redis local (non recommandé)
  lago_storage_data:      # Documents PDF - utiliser S3 plutôt
  portainer_data:         # Config Portainer
```

**⚠️ Pour Scaleway** : 
- Monter un Block Storage pour les volumes critiques
- Utiliser Object Storage pour `lago_storage_data`
- Utiliser Managed Database → supprimer `lago_postgres_data` et `lago_redis_data`

### 3. Sécurité

#### Firewall Scaleway
```
Règles entrantes :
- Port 443 (HTTPS) : 0.0.0.0/0
- Port 80 (HTTP) : 0.0.0.0/0 (redirection vers 443)
- Port 22 (SSH) : Votre IP uniquement

Règles sortantes :
- Tout autoriser (ou spécifier SMTP, API externes)
```

#### Secrets management
```bash
# Générer les secrets
SECRET_KEY_BASE=$(openssl rand -hex 64)
LAGO_ENCRYPTION_PRIMARY_KEY=$(openssl rand -hex 32)
LAGO_ENCRYPTION_DETERMINISTIC_KEY=$(openssl rand -hex 32)
LAGO_ENCRYPTION_KEY_DERIVATION_SALT=$(openssl rand -hex 32)

# Générer les clés RSA
openssl genrsa -out private.pem 2048
# Convertir en format attendu par Lago
```

#### Base de données
- Connexions SSL obligatoires si Managed Database
- Limiter les connexions au Private Network
- Backups automatiques configurés

### 4. Monitoring et logs

**À configurer**
```bash
# Désactiver analytics Segment si souhaité
LAGO_DISABLE_SEGMENT=true

# Logs
RAILS_LOG_TO_STDOUT=true           # Déjà configuré
```

**Scaleway Cockpit**
- Activer la collecte de logs
- Configurer les alertes sur :
  - CPU > 80%
  - RAM > 85%
  - Disk > 80%
  - Erreurs HTTP 5xx

### 5. Performance

**Workers Sidekiq**
Le fichier production configure déjà des workers dédiés :
- ✅ Events worker (haute priorité)
- ✅ Billing worker
- ✅ PDF worker
- ✅ Webhook worker
- ✅ Clock worker

**Configuration concurrence**
```yaml
# Ajuster selon les ressources Scaleway
SIDEKIQ_CONCURRENCY: 20  # Worker principal
DATABASE_POOL: 20        # Connexions DB
```

**Scaling horizontal**
- Possibilité de scaler les workers indépendamment
- Utiliser Portainer pour ajuster les replicas

---

## 📝 Checklist de déploiement

### Phase 1 : Préparation (avant déploiement)

- [ ] Créer une instance Scaleway (PRO2-M minimum)
- [ ] Provisionner Managed PostgreSQL Database
- [ ] Provisionner Managed Redis
- [ ] Créer un bucket Object Storage
- [ ] Configurer les credentials IAM pour Object Storage
- [ ] Réserver une Elastic IP
- [ ] Configurer le DNS (A record vers Elastic IP)
- [ ] Générer tous les secrets (SECRET_KEY_BASE, clés encryption, etc.)
- [ ] Préparer le fichier `.env` avec toutes les variables
- [ ] Configurer Scaleway Transactional Email (SMTP)

### Phase 2 : Configuration

- [ ] Cloner le repository sur l'instance
- [ ] Installer Docker et Docker Compose
- [ ] Copier `deploy/docker-compose.production.yml` vers `docker-compose.yml`
- [ ] Créer le fichier `.env` avec les variables complètes
- [ ] **MODIFIER** : Changer Let's Encrypt en mode production (ligne 87)
- [ ] Configurer le firewall Scaleway
- [ ] Créer les répertoires pour volumes
- [ ] Configurer les backups automatiques

### Phase 3 : Déploiement initial

- [ ] Lancer les services : `docker compose --profile all up -d`
- [ ] Vérifier les logs : `docker compose logs -f`
- [ ] Attendre que la migration DB soit terminée
- [ ] Vérifier que tous les services sont healthy
- [ ] Tester l'accès HTTPS : `https://votre-domaine.com`
- [ ] Vérifier les certificats SSL

### Phase 4 : Configuration applicative

- [ ] Créer l'organisation initiale (si LAGO_CREATE_ORG=true)
- [ ] Configurer les webhooks si nécessaire
- [ ] Tester l'envoi d'emails
- [ ] Vérifier le stockage S3 (upload de fichiers)
- [ ] Tester la génération de PDF

### Phase 5 : Monitoring et optimisation

- [ ] Configurer Scaleway Cockpit
- [ ] Activer les alertes
- [ ] Configurer les backups PostgreSQL
- [ ] Tester la restauration de backup
- [ ] Documenter la procédure de rollback
- [ ] Configurer log rotation
- [ ] Optimiser les workers selon la charge

---

## 🔧 Commandes utiles

### Démarrage
```bash
# Démarrer tous les services
docker compose --profile all up -d

# Voir les logs
docker compose logs -f

# Voir les logs d'un service spécifique
docker compose logs -f api

# Redémarrer un service
docker compose restart api
```

### Maintenance
```bash
# Mettre à jour les images
docker compose pull
docker compose --profile all up -d

# Voir l'état des services
docker compose ps

# Exécuter une commande dans un container
docker compose exec api rails console

# Backup manuel PostgreSQL (si DB locale)
docker compose exec db pg_dump -U lago lago > backup.sql
```

### Debugging
```bash
# Vérifier la configuration
docker compose config

# Accéder au worker
docker compose exec worker bash

# Vérifier les jobs Sidekiq
docker compose exec api rails runner "puts Sidekiq::Stats.new.inspect"
```

---

## ⚡ Optimisations Scaleway spécifiques

### 1. Utiliser Private Network
```yaml
# Ajouter aux services qui communiquent entre eux
networks:
  - private_network

networks:
  private_network:
    driver: bridge
```

### 2. Health checks Traefik
Ajuster les timeouts pour Scaleway :
```yaml
# Dans les health checks
interval: 10s
timeout: 5s
retries: 5
start_period: 30s
```

### 3. Limits de ressources
```yaml
# Ajouter aux services
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
    reservations:
      cpus: '1'
      memory: 1G
```

---

## 🚨 Points d'attention critiques

1. **Let's Encrypt en staging** : Modifier impérativement pour la production
2. **Mots de passe par défaut** : Tous les `changeme` doivent être changés
3. **Clés de chiffrement** : Doivent être générées et sécurisées (backup externe)
4. **Object Storage** : Obligatoire pour la production (ne pas utiliser volumes locaux)
5. **Database managée** : Fortement recommandé vs PostgreSQL en container
6. **Backup** : Mettre en place une stratégie de backup dès le début
7. **DNS** : S'assurer que le domaine pointe correctement avant le déploiement
8. **Firewall** : Restreindre SSH à votre IP uniquement

---

## 📚 Documentation de référence

- [Documentation Lago](https://doc.getlago.com)
- [Scaleway Object Storage](https://www.scaleway.com/en/docs/storage/object/)
- [Scaleway Managed Databases](https://www.scaleway.com/en/docs/managed-databases/)
- [Traefik v3 Documentation](https://doc.traefik.io/traefik/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)

---

## 🔄 Prochaines étapes recommandées

1. Créer un fichier `.env.scaleway` avec toutes les variables configurées
2. Créer un script de déploiement automatisé Scaleway-spécifique
3. Configurer CI/CD pour automatiser les déploiements
4. Mettre en place monitoring avancé (Grafana + Prometheus)
5. Planifier une stratégie de scaling pour les workers
6. Documenter la procédure de disaster recovery
