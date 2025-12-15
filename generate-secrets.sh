#!/bin/bash
# Script pour générer tous les secrets nécessaires pour Railway
# Usage: chmod +x generate-secrets.sh && ./generate-secrets.sh

echo "🔐 Génération des secrets pour Lago sur Railway"
echo "================================================"
echo ""

# Vérifier que openssl est installé
if ! command -v openssl &> /dev/null; then
    echo "❌ OpenSSL n'est pas installé. Installez-le d'abord."
    exit 1
fi

echo "✅ OpenSSL trouvé"
echo ""

# Générer les secrets
echo "📝 Génération des secrets..."
echo ""

SECRET_KEY_BASE=$(openssl rand -hex 64)
ENCRYPTION_PRIMARY=$(openssl rand -hex 32)
ENCRYPTION_DETERMINISTIC=$(openssl rand -hex 32)
ENCRYPTION_SALT=$(openssl rand -hex 32)

# Générer les clés RSA
echo "🔑 Génération des clés RSA..."
PRIVATE_KEY=$(openssl genrsa 2048 2>/dev/null | base64 -w 0 2>/dev/null || openssl genrsa 2048 2>/dev/null | base64)

echo "✅ Secrets générés avec succès !"
echo ""
echo "========================================="
echo "📋 COPIEZ CES VARIABLES DANS RAILWAY"
echo "========================================="
echo ""
echo "# Secrets de sécurité"
echo "SECRET_KEY_BASE=$SECRET_KEY_BASE"
echo ""
echo "LAGO_ENCRYPTION_PRIMARY_KEY=$ENCRYPTION_PRIMARY"
echo ""
echo "LAGO_ENCRYPTION_DETERMINISTIC_KEY=$ENCRYPTION_DETERMINISTIC"
echo ""
echo "LAGO_ENCRYPTION_KEY_DERIVATION_SALT=$ENCRYPTION_SALT"
echo ""
echo "LAGO_RSA_PRIVATE_KEY=$PRIVATE_KEY"
echo ""
echo "========================================="
echo "📋 VARIABLES RAILWAY ADDITIONNELLES"
echo "========================================="
echo ""
echo "# Base de données (Railway)"
echo "DATABASE_URL=\${{Postgres.DATABASE_URL}}"
echo ""
echo "# Redis (Railway)"
echo "REDIS_URL=\${{Redis.REDIS_URL}}"
echo ""
echo "# URLs (Railway auto)"
echo "LAGO_FRONT_URL=https://\${{RAILWAY_PUBLIC_DOMAIN}}"
echo "LAGO_API_URL=https://\${{RAILWAY_PUBLIC_DOMAIN}}/api"
echo ""
echo "# Configuration Rails"
echo "RAILS_ENV=production"
echo "RAILS_SERVE_STATIC_FILES=true"
echo "RAILS_LOG_TO_STDOUT=true"
echo "PORT=3000"
echo ""
echo "# Optionnel - SMTP (Scaleway, SendGrid, etc.)"
echo "# LAGO_FROM_EMAIL=noreply@votre-domaine.com"
echo "# LAGO_SMTP_ADDRESS=smtp.exemple.com"
echo "# LAGO_SMTP_PORT=587"
echo "# LAGO_SMTP_USERNAME=votre-username"
echo "# LAGO_SMTP_PASSWORD=votre-password"
echo ""
echo "# Optionnel - Stockage S3 (Scaleway Object Storage, AWS S3, etc.)"
echo "# LAGO_USE_AWS_S3=true"
echo "# LAGO_AWS_S3_ACCESS_KEY_ID=votre-access-key"
echo "# LAGO_AWS_S3_SECRET_ACCESS_KEY=votre-secret-key"
echo "# LAGO_AWS_S3_REGION=fr-par"
echo "# LAGO_AWS_S3_BUCKET=lago-storage"
echo "# LAGO_AWS_S3_ENDPOINT=https://s3.fr-par.scw.cloud"
echo ""
echo "========================================="
echo "⚠️  IMPORTANT"
echo "========================================="
echo ""
echo "1. Ne partagez JAMAIS ces secrets publiquement"
echo "2. Sauvegardez-les dans un gestionnaire de mots de passe"
echo "3. Utilisez-les uniquement dans Railway Dashboard"
echo "4. Si compromis, régénérez-les immédiatement"
echo ""
echo "✅ Configuration terminée !"
echo ""

# Optionnel : Sauvegarder dans un fichier .env (non commité)
if [ "$1" = "--save" ]; then
    ENV_FILE=".env.railway.secrets"
    echo "💾 Sauvegarde dans $ENV_FILE..."
    cat > $ENV_FILE << EOF
# ⚠️ NE PAS COMMITTER CE FICHIER - Secrets pour Railway
# Généré le $(date)

SECRET_KEY_BASE=$SECRET_KEY_BASE
LAGO_ENCRYPTION_PRIMARY_KEY=$ENCRYPTION_PRIMARY
LAGO_ENCRYPTION_DETERMINISTIC_KEY=$ENCRYPTION_DETERMINISTIC
LAGO_ENCRYPTION_KEY_DERIVATION_SALT=$ENCRYPTION_SALT
LAGO_RSA_PRIVATE_KEY=$PRIVATE_KEY

# À compléter :
DATABASE_URL=\${{Postgres.DATABASE_URL}}
REDIS_URL=\${{Redis.REDIS_URL}}
LAGO_FRONT_URL=https://\${{RAILWAY_PUBLIC_DOMAIN}}
LAGO_API_URL=https://\${{RAILWAY_PUBLIC_DOMAIN}}/api
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
PORT=3000
EOF
    echo "✅ Secrets sauvegardés dans $ENV_FILE"
    echo "⚠️  Ajoutez ce fichier à .gitignore !"
    echo ""
fi

echo "🎉 Prêt pour Railway !"
