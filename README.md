# lab1-terraform

Det här projektet sätter upp en virtuell maskin i Google Cloud Platform med hjälp av Terraform. VM:en provisioneras automatiskt med grundläggande säkerhetshärdning, en daglig backup-policy via snapshot-schema, och en GitHub Actions-pipeline som kör lint, säkerhetsskanning, validering, plan och apply.

---

## Kom igång

### Förutsättningar

- Terraform CLI installerat
- GCP-projekt: `chas-devsecops-2026`
- Ett `terraform.tfvars`-fil lokalt (lägg inte i git):

### Kör lokalt

```bash
terraform init
terraform plan
terraform apply
```

---

## Pipeline

CI/CD körs via GitHub Actions på varje push och PR mot `main`.

| Jobb | Vad det gör |
|------|-------------|
| `lint` | Kontrollerar formatering med `terraform fmt` |
| `security` | Kör Trivy IaC-skanning på CRITICAL och HIGH |
| `validate` | Kör `terraform validate` utan GCP-anslutning |
| `plan` | Autentiserar mot GCP och kör `terraform plan` |
| `apply` | Kör `terraform apply` — endast vid push till `main` |

**Screenshot — pipeline som passerar:**

> 

---

## VM i GCP Console

**Screenshot — VM körs i GCP:**

> 

---

## Säkerhetsbeslut

**ufw** — sätter upp en enkel host-baserad brandvägg direkt på VM:en. Defaultregeln blockar all inkommande trafik utom SSH, vilket minimerar attackytan utan att behöva konfigurera något i GCP:s nätverk.

**fail2ban** — övervakar misslyckade inloggningsförsök och bannar IP-adresser automatiskt efter ett antal försök. Skyddar mot brute force mot SSH.

**unattended-upgrades** — installerar säkerhetsuppdateringar automatiskt. Minskar risken för att VM:en ligger oskyddad vid kända sårbarheter utan att man aktivt behöver hålla koll.

**Snapshot-policy** — daglig backup kl. 03:00 med 7 dagars retention. Snapshots behålls även om källdisken raderas (`KEEP_AUTO_SNAPSHOTS`), vilket ger en rimlig recovery-möjlighet utan extra kostnad.

**terraform.tfvars i .gitignore** — projektspecifika värden och potentiellt känslig konfiguration hamnar aldrig i versionshanteringen.
