# Azure Playground Cost Dashboard

Dashboard de suivi des coûts Azure pour l'environnement Playground de Devoteam M Cloud.

## Fonctionnalités

- **Suivi Month-to-Date** — Coûts MTD avec comparaison au mois précédent (delta en %)
- **Vue par souscription** — Barres de progression et détail pour chaque souscription Azure (sub-idf-01, sub-lille-01, sub-lyon-01, sub-marseille-01, sub-nantes-01, sub-temp-01)
- **Top 10 Resource Groups** — Classement des groupes de ressources les plus coûteux
- **Thème clair / sombre** — Bascule via un toggle dans la barre de navigation
- **Accès protégé par PIN**

## Architecture

```
├── index.html                          # Dashboard (HTML + JS vanilla)
├── css/styles.css                      # Styles avec variables CSS pour le theming
├── data/costs.json                     # Données de coûts (généré automatiquement)
├── img/devoteam-logo.png               # Logo Devoteam
├── Generate-CostData.ps1               # Script PowerShell de collecte des coûts Azure
├── .github/workflows/Generate-CostData.yml  # GitHub Actions (exécution quotidienne)
└── CNAME                               # Domaine personnalisé GitHub Pages
```

## Flux de données

1. **GitHub Actions** exécute le workflow tous les jours à 6h UTC
2. Le script PowerShell s'authentifie auprès d'Azure via un service principal (OAuth2)
3. Il interroge l'API Cost Management (`v2023-11-01`) pour le mois en cours et le mois précédent
4. Le fichier `data/costs.json` est généré puis commité automatiquement dans le repo
5. Le dashboard charge ce JSON et affiche les données

## Prérequis pour le déploiement

### Secrets GitHub

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | Client ID du service principal |
| `AZURE_CLIENT_SECRET` | Secret du service principal |
| `TENANT_ID` | Tenant ID Azure AD |
| `SUB_IDF_01` | Subscription ID sub-idf-01 |
| `SUB_LILLE_01` | Subscription ID sub-lille-01 |
| `SUB_LYON_01` | Subscription ID sub-lyon-01 |
| `SUB_MARSEILLE_01` | Subscription ID sub-marseille-01 |
| `SUB_NANTES_01` | Subscription ID sub-nantes-01 |
| `SUB_TEMP_01` | Subscription ID sub-temp-01 |

### Hébergement

Le site est servi via **GitHub Pages** avec un domaine personnalisé.

## Stack technique

- **Frontend** — HTML5, CSS3, JavaScript vanilla, police Inter (Google Fonts)
- **Data** — PowerShell 7+, Azure Cost Management REST API
- **CI/CD** — GitHub Actions
- **Hébergement** — GitHub Pages

## Contact

[Thibault Gibard](mailto:thibault.gibard@devoteam.com)
