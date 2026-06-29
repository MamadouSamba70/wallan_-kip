# Règles de Contribution — Projet WALLAN

## 🌿 Gestion des Branches

Chaque développeur travaille sur sa propre branche. **Ne jamais committer directement sur `main`.**

### Nommage des branches

```
feature/[dev]-[nom-module]
fix/[dev]-[description-bug]
docs/[dev]-[description]
```

### Exemples
```
feature/mamadou-samba-auth-backend
feature/fatima-patients-api
feature/hady-biometric-data
feature/alpha-alerts-notifications
feature/hadjiratou-auth-frontend
fix/fatima-patient-crud-bug
docs/mamadou-samba-api-documentation
```

---

## ✅ Convention de Commits

Format : `[type](module): description courte`

### Types de commits
| Type | Usage |
|------|-------|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `docs` | Documentation uniquement |
| `style` | Mise en forme (pas de changement logique) |
| `refactor` | Refactoring du code |
| `test` | Ajout de tests |
| `chore` | Mise à jour dépendances, configs |

### Exemples de commits
```
feat(accounts): ajouter endpoint d'inscription JWT
fix(patients): corriger la validation du numéro de téléphone
docs(api): documenter les endpoints d'alertes
test(biometrics): ajouter tests unitaires réception mesures
feat(flutter-auth): implémenter LoginScreen avec validation
```

---

## 📋 Pull Requests

1. **Créer une PR** depuis votre branche vers `develop`
2. **Titre clair** : ex. `[Fatima] Module patients - API CRUD complète`
3. **Description** : ce qui a été fait, comment tester
4. **Revue obligatoire** : au moins 1 autre développeur doit approuver
5. **Pas de merge** si des tests échouent

### Template PR
```markdown
## Description
Bref résumé des changements effectués.

## Module(s) modifié(s)
- [ ] accounts
- [ ] patients
- [ ] autre...

## Comment tester
1. Étape 1
2. Étape 2

## Checklist
- [ ] Tests passent
- [ ] Code documenté
- [ ] Pas de conflits avec `develop`
```

---

## 🏗️ Structure des Branches

```
main          ← Code stable, validé (merge après sprint)
  └── develop ← Branche d'intégration principale
        ├── feature/mamadou-samba-auth-backend
        ├── feature/mamadou-samba-admin-backend
        ├── feature/fatima-patients-backend
        ├── feature/fatima-care-management
        ├── feature/fatima-patient-frontend
        ├── feature/fatima-doctor-frontend
        ├── feature/hady-devices-backend
        ├── feature/hady-biometrics-backend
        ├── feature/hady-device-frontend
        ├── feature/hady-biometrics-frontend
        ├── feature/alpha-alerts-backend
        ├── feature/alpha-notifications-backend
        ├── feature/alpha-statistics-backend
        ├── feature/alpha-alerts-frontend
        ├── feature/alpha-relative-frontend
        ├── feature/hadjiratou-auth-frontend
        ├── feature/hadjiratou-admin-frontend
        └── feature/hadjiratou-database
```

---

## 🔐 Règles de Sécurité

- **Ne jamais committer** de fichiers `.env` ou secrets
- **Ne jamais committer** de mots de passe, clés API, tokens
- Le fichier `.env.example` contient uniquement les noms des variables (sans valeurs)
- Utiliser `.gitignore` correctement

---

## 📞 Communication

- **Réunions** : 2 fois par semaine via Google Meet
- **Questions urgentes** : Groupe WhatsApp Wallan
- **Blocages** : Signaler au chef de projet sous 24h
- **Compte-rendu** : Partagé après chaque réunion
