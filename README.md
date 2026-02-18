# 🚀 blog-iac

This project manages the **Serverless Infrastructure as Code (IaC)** for the blog. It utilizes Terraform to orchestrate a high-performance, event-driven architecture based on AWS best practices.

## 🛠️ Stack & Services

- **Infrastructure:** Terraform (S3 Backend for State)
- **Identity:** Amazon Cognito (User Pools & Clients)
- **Compute:** AWS Lambda (Node.js 22 - Post-Confirmation Trigger)
- **Database:** Amazon DynamoDB (Single Table Design)
- **Frontend Hosting:** AWS S3 + CloudFront (Static Web Hosting)

## 🏗️ Installation & Setup

### 1. Install Terraform

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### 2. Bootstrap the environment

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

### 🗺️ Infrastructure Architecture

In this version, we removed external dependencies (Neon DB) to favor a fully AWS-native ecosystem. Red nodes indicate the core of the new identity-to-data synchronization flow.

```mermaid
   graph TD
    subgraph External_User [🌐 Internet]
        User["💻 User (Next.js on S3)"]
    end

    subgraph GitHub_Actions [🚀 GitHub Actions Pipeline]
        B["⚙️ Terraform Plan/Apply"]
        S1["📦 S3: Terraform State"] --- B
    end

    subgraph AWS_Cloud [☁️ AWS Cloud - us-east-1]

        subgraph Auth_Identity [🆔 Identity & Trigger]
            I["👥 Cognito User Pool"]
            J["🔑 User Pool Client"]

            I <--> J
        end

        subgraph Compute_Layer [🖥️ Compute]
            L["⚡ Lambda: blog-auth-handler"]
            L_ENV["🔑 Env Vars: TABLE_NAME"]

            I -- "🔥 Trigger: Post-Confirmation" --> L
            L --- L_ENV
        end

        subgraph Storage_Layer [📦 Data Persistence]
            DB["💎 DynamoDB: blog-website-table"]
        end

        subgraph IAM_Control [🛡️ IAM & Permissions]
            Role["📜 Lambda IAM Role"]
            Pol["✅ Policy: DynamoDB:PutItem"]
            Role --- Pol
            L --- Role
        end

    end

    %% Flow Connections
    User -- "1. SignUp / Confirm" --> J
    L -- "2. Sync User Profile" --> DB

    %% Highlighted Changes (RED)
    style I fill:#000,stroke:#ff0000,stroke-width:3px,color:#ff0000
    style L fill:#000,stroke:#ff0000,stroke-width:3px,color:#ff0000
    style DB fill:#000,stroke:#ff0000,stroke-width:3px,color:#ff0000
    style Pol fill:#ffebee,stroke:#ff0000,stroke-width:1px,color:#b71c1c
```

### 📝 Key Infrastructure Notes

Identity-First: Users are only persisted to DynamoDB after successful Cognito confirmation.

No RDS/Secrets Manager: Simplified security model using IAM Roles instead of database credentials.

Node.js 22 Runtime: Optimized Lambda environment with AWS SDK v3 pre-installed.
