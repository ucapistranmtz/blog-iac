# blog-iac

This project is to build the architecture behind a severless blog using Terraform for IAC
the services included in are

- AM Policy
- AWS CDK
- AWS S3

Steps

## Install Terraform

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## Add Autocomplete feature

```
terraform -install-autocomplete
```

# Execute the bootstrap script

```
 chmod +x bootstrap.sh
./bootstrap.sh
```

# Architecture

```mermaid
graph TD
    subgraph External_User [🌐 Internet]
        User["💻 User / Frontend"]
    end

    subgraph GitHub_Actions [🚀 GitHub Actions Pipeline]
        GA_ZIP["📦 Zip Code"] --> GA_S3["📤 S3 Upload (New Version)"]
        GA_S3 --> GA_PUB["🏷️ Publish Lambda Version (PR Title)"]
        GA_PUB --> GA_ALIAS["📍 Update Alias: live"]
    end

    subgraph AWS_Cloud [☁️ AWS Cloud - us-east-1]

        subgraph Gateway_Layer [⛩️ Entry Point]
            GW["🌐 API Gateway: blog-api"]
            ST["📝 Stage: $default"]
            RT["🛣️ Route: /api/auth/{proxy+}"]

            GW --> ST
            ST --> RT
        end

        subgraph Storage_Layer [🪣 Storage & State]
            S1["📦 S3: Terraform State"]
            S3_ART["📦 S3: project-artifacts"]
        end

        subgraph Compute_Layer [🖥️ Compute]
            L_FUNC["📦 Lambda: auth-handler"]
            L_VER["🔢 Lambda Versions (V1, V2, V13...)"]
            L_ALIAS["📍 Alias: live"]

            L_FUNC --- L_VER
            L_VER --- L_ALIAS
            L_ALIAS -- "📖 Reads" --> H["🆔 Env Vars (Neon DB, BetterAuth)"]
        end

        subgraph Auth_Identity [🆔 Identity]
            I["👥 Cognito User Pool"] <--> J["🔑 User Pool Client"]
        end

        RT -- "🔗 Integration (Qualifer: live)" --> L_ALIAS
    end

    subgraph External [🐘 Database]
        K["💎 Neon PostgreSQL"] <--> L_ALIAS
    end

    %% Relaciones de flujo
    User -- "HTTPS Request" --> GW
    GA_S3 -- "Stores Zip" --> S3_ART
    GA_ALIAS -- "Points to latest V" --> L_ALIAS
    L_ALIAS -- "BetterAuth Engine" --> K

    %% Estilo DARK con bordes y letras rojas
    style GW fill:#000,stroke:#ff0000,stroke-width:2px,color:#ff0000
    style ST fill:#000,stroke:#ff0000,stroke-width:2px,color:#ff0000
    style RT fill:#000,stroke:#ff0000,stroke-width:2px,color:#ff0000
    style L_ALIAS fill:#000,stroke:#ff0000,stroke-width:3px,color:#ff0000
    style L_VER fill:#000,stroke:#ff0000,stroke-width:1px,color:#ff0000,stroke-dasharray: 5 5
    style Gateway_Layer fill:#000,stroke:#ff0000,stroke-width:1px,stroke-dasharray: 5 5,color:#ff0000
    style Compute_Layer fill:#000,stroke:#ff0000,stroke-width:1px,color:#ff0000
```
