# PowerShell script pour générer les secrets Railway
# Usage: .\generate-secrets.ps1

Write-Host "🔐 Génération des secrets pour Lago sur Railway" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Fonction pour générer des bytes aléatoires en hex
function Get-RandomHex {
    param([int]$Length)
    $bytes = New-Object byte[] $Length
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($bytes)
    return [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()
}

# Fonction pour générer une clé RSA
function Get-RSAKey {
    try {
        $rsa = [System.Security.Cryptography.RSA]::Create(2048)
        $privateKey = $rsa.ExportRSAPrivateKey()
        $base64 = [Convert]::ToBase64String($privateKey)
        return $base64
    }
    catch {
        Write-Host "⚠️  Impossible de générer la clé RSA avec .NET. Utilisez OpenSSL." -ForegroundColor Yellow
        return "GENERATE_WITH_OPENSSL"
    }
}

Write-Host "📝 Génération des secrets..." -ForegroundColor Green
Write-Host ""

$SECRET_KEY_BASE = Get-RandomHex -Length 64
$ENCRYPTION_PRIMARY = Get-RandomHex -Length 32
$ENCRYPTION_DETERMINISTIC = Get-RandomHex -Length 32
$ENCRYPTION_SALT = Get-RandomHex -Length 32
$RSA_KEY = Get-RSAKey

Write-Host "✅ Secrets générés avec succès !" -ForegroundColor Green
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "📋 COPIEZ CES VARIABLES DANS RAILWAY" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Secrets de sécurité" -ForegroundColor Yellow
Write-Host "SECRET_KEY_BASE=$SECRET_KEY_BASE"
Write-Host ""
Write-Host "LAGO_ENCRYPTION_PRIMARY_KEY=$ENCRYPTION_PRIMARY"
Write-Host ""
Write-Host "LAGO_ENCRYPTION_DETERMINISTIC_KEY=$ENCRYPTION_DETERMINISTIC"
Write-Host ""
Write-Host "LAGO_ENCRYPTION_KEY_DERIVATION_SALT=$ENCRYPTION_SALT"
Write-Host ""
if ($RSA_KEY -eq "GENERATE_WITH_OPENSSL") {
    Write-Host "LAGO_RSA_PRIVATE_KEY=<Générez avec: openssl genrsa 2048 | base64 -w 0>" -ForegroundColor Yellow
} else {
    Write-Host "LAGO_RSA_PRIVATE_KEY=$RSA_KEY"
}
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "📋 VARIABLES RAILWAY ADDITIONNELLES" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Base de données (Railway)" -ForegroundColor Yellow
Write-Host "DATABASE_URL=`${{Postgres.DATABASE_URL}}"
Write-Host ""
Write-Host "# Redis (Railway)" -ForegroundColor Yellow
Write-Host "REDIS_URL=`${{Redis.REDIS_URL}}"
Write-Host ""
Write-Host "# URLs (Railway auto)" -ForegroundColor Yellow
Write-Host "LAGO_FRONT_URL=https://`${{RAILWAY_PUBLIC_DOMAIN}}"
Write-Host "LAGO_API_URL=https://`${{RAILWAY_PUBLIC_DOMAIN}}/api"
Write-Host ""
Write-Host "# Configuration Rails" -ForegroundColor Yellow
Write-Host "RAILS_ENV=production"
Write-Host "RAILS_SERVE_STATIC_FILES=true"
Write-Host "RAILS_LOG_TO_STDOUT=true"
Write-Host "PORT=3000"
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "⚠️  IMPORTANT" -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Ne partagez JAMAIS ces secrets publiquement" -ForegroundColor Red
Write-Host "2. Sauvegardez-les dans un gestionnaire de mots de passe" -ForegroundColor Yellow
Write-Host "3. Utilisez-les uniquement dans Railway Dashboard" -ForegroundColor Yellow
Write-Host "4. Si compromis, régénérez-les immédiatement" -ForegroundColor Red
Write-Host ""

# Sauvegarder dans un fichier
$saveFile = Read-Host "Voulez-vous sauvegarder dans un fichier .env.railway.secrets ? (o/N)"
if ($saveFile -eq 'o' -or $saveFile -eq 'O') {
    $envContent = @"
# ⚠️ NE PAS COMMITTER CE FICHIER - Secrets pour Railway
# Généré le $(Get-Date)

SECRET_KEY_BASE=$SECRET_KEY_BASE
LAGO_ENCRYPTION_PRIMARY_KEY=$ENCRYPTION_PRIMARY
LAGO_ENCRYPTION_DETERMINISTIC_KEY=$ENCRYPTION_DETERMINISTIC
LAGO_ENCRYPTION_KEY_DERIVATION_SALT=$ENCRYPTION_SALT
LAGO_RSA_PRIVATE_KEY=$RSA_KEY

# À compléter :
DATABASE_URL=`${{Postgres.DATABASE_URL}}
REDIS_URL=`${{Redis.REDIS_URL}}
LAGO_FRONT_URL=https://`${{RAILWAY_PUBLIC_DOMAIN}}
LAGO_API_URL=https://`${{RAILWAY_PUBLIC_DOMAIN}}/api
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
PORT=3000
"@
    
    $envContent | Out-File -FilePath ".env.railway.secrets" -Encoding UTF8
    Write-Host "✅ Secrets sauvegardés dans .env.railway.secrets" -ForegroundColor Green
    Write-Host "⚠️  Ajoutez ce fichier à .gitignore !" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Prêt pour Railway !" -ForegroundColor Green
