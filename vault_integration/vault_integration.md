# Vault Integration


The workflow includes:

* Creating an AWS EC2 instance with Ubuntu
* Installing HashiCorp Vault
* Running Vault in development mode
* Enabling AppRole authentication
* Creating a Vault policy
* Creating an AppRole
* Generating a Role ID and Secret ID
* Authenticating using AppRole
* Storing secrets using the KV secrets engine
* Configuring Terraform to read secrets from Vault

> **Note:** The Vault development server used in this project is intended only for learning and testing. It is not suitable for production use.

---

# 1. Create an AWS EC2 Instance with Ubuntu

To create an AWS EC2 instance with Ubuntu, you can use the AWS Management Console or AWS CLI.

Using the AWS Management Console:

1. Go to the AWS Management Console.
2. Navigate to **EC2**.
3. Click **Launch Instance**.
4. Select an appropriate **Ubuntu Server LTS AMI**.
5. Select the instance type.
6. Configure the networking and storage settings.
7. Configure a security group.
8. Allow SSH access on port `22`.
9. Allow Vault access on port `8200` if Vault needs to be accessed remotely.
10. Launch the instance.

Make sure the EC2 instance has internet access so that Vault can be downloaded from the HashiCorp repository.

---

# 2. Install Vault on the EC2 Instance

Connect to the EC2 instance using SSH.

## Install GPG

```bash
sudo apt update
sudo apt install -y gpg
```

## Download the HashiCorp signing key

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

## Verify the key fingerprint

```bash
gpg --no-default-keyring \
  --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  --fingerprint
```

## Add the HashiCorp repository

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

## Update package information

```bash
sudo apt update
```

## Install Vault

```bash
sudo apt install -y vault
```

Verify the installation:

```bash
vault version
```

---

# 3. Start Vault

For this learning project, Vault can be started in development mode:

```bash
vault server -dev -dev-listen-address="0.0.0.0:8200"
```

Vault will display a **root token** when it starts.

Save the token temporarily for this learning environment.

> **Important:** Development mode uses temporary/in-memory storage and is not suitable for production.

In another terminal, set the Vault address:

```bash
export VAULT_ADDR='http://127.0.0.1:8200'
```

If accessing Vault from another machine, use the EC2 public IP:

```bash
export VAULT_ADDR='http://<EC2-PUBLIC-IP>:8200'
```

Set the development root token:

```bash
export VAULT_TOKEN="<DEV_ROOT_TOKEN>"
```

Verify that Vault is running:

```bash
vault status
```

---

# 4. Enable the AppRole Authentication Method

AppRole is designed primarily for applications and machines to authenticate with Vault.

Enable AppRole:

```bash
vault auth enable approle
```

Verify the enabled authentication methods:

```bash
vault auth list
```

You should see:

```text
approle/
```

---

# 5. Enable the KV Secrets Engine

For this example, use the KV version 2 secrets engine.

Enable it at the `secret` path:

```bash
vault secrets enable -path=secret kv-v2
```

Verify:

```bash
vault secrets list
```

You should see:

```text
secret/
```

---

# 6. Store a Secret in Vault

Create a sample application secret:

```bash
vault kv put secret/myapp \
  username="admin" \
  password="mypassword123"
```

Read the secret:

```bash
vault kv get secret/myapp
```

The secret is stored in the KV v2 secrets engine.

The logical secret path is:

```text
secret/myapp
```

Internally, KV v2 uses paths such as:

```text
secret/data/myapp
secret/metadata/myapp
```

---

# 7. Create a Vault Policy

Create a policy that allows the Terraform AppRole to read the application secret.

Create a file named:

```text
terraform-policy.hcl
```

Add:

```hcl
path "secret/data/myapp" {
  capabilities = ["read"]
}
```

This follows the principle of least privilege because Terraform only needs permission to read this specific secret.

Write the policy to Vault:

```bash
vault policy write terraform terraform-policy.hcl
```

Verify the policy:

```bash
vault policy read terraform
```

The policy means:

```text
Terraform AppRole
       |
       | read
       ↓
secret/data/myapp
```

---

# 8. Create the AppRole

Create an AppRole named `terraform`.

HashiCorp recommends batch tokens for machine-based AppRole authentication.

```bash
vault write auth/approle/role/terraform \
  token_type=batch \
  secret_id_ttl=10m \
  token_ttl=20m \
  token_max_ttl=30m \
  secret_id_num_uses=40 \
  token_policies=terraform
```

The important parameters are:

* `token_type=batch` → Uses batch tokens for machine authentication.
* `secret_id_ttl=10m` → Secret IDs expire after 10 minutes.
* `token_ttl=20m` → Generated tokens have a 20-minute TTL.
* `token_max_ttl=30m` → Maximum token lifetime is 30 minutes.
* `secret_id_num_uses=40` → A Secret ID can be used up to 40 times.
* `token_policies=terraform` → Tokens generated from this AppRole receive the `terraform` policy.

AppRole requires a Role ID and, by default, a Secret ID for authentication.

---

# 9. Generate the Role ID

Retrieve the Role ID for the `terraform` AppRole:

```bash
vault read auth/approle/role/terraform/role-id
```

The response contains:

```text
role_id
```

Save the Role ID.

The Role ID identifies the AppRole.

```text
Role ID
   ↓
Identifies the Terraform AppRole
```

---

# 10. Generate the Secret ID

Generate a Secret ID:

```bash
vault write -f auth/approle/role/terraform/secret-id
```

The response contains:

```text
secret_id
secret_id_accessor
secret_id_ttl
secret_id_num_uses
```

The Secret ID is a credential and must be kept secret.

Do not commit the Secret ID to GitHub.

---

# 11. Authenticate Using AppRole

Use the Role ID and Secret ID to authenticate.

```bash
vault write auth/approle/login \
  role_id="<ROLE_ID>" \
  secret_id="<SECRET_ID>"
```

Vault returns a token.

The important value is:

```text
token
```

This token contains the policies assigned to the AppRole.

The authentication flow is:

```text
Role ID + Secret ID
        |
        ↓
   AppRole Login
        |
        ↓
    Vault Token
        |
        ↓
Terraform Policy
        |
        ↓
Read Allowed Secrets
```

Vault's AppRole login endpoint uses `role_id` and `secret_id` to issue the Vault token.

---

# 12. Test the AppRole Token

Export the generated token:

```bash
export VAULT_TOKEN="<APPROLE_TOKEN>"
```

Test access to the secret:

```bash
vault kv get secret/myapp
```

The AppRole should be able to read the secret.

Try accessing a path that is not allowed by the policy:

```bash
vault kv get secret/another-secret
```

This should fail because the policy only allows:

```text
secret/data/myapp
```

This demonstrates how Vault policies control access.

---

# 13. Configure Terraform to Use Vault

Terraform can use the HashiCorp Vault provider to retrieve secrets from Vault.

Add the Vault provider to your Terraform configuration:

```hcl
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}
```

Initialize Terraform:

```bash
terraform init
```

---

# 14. Configure the Vault Provider

For a learning environment, the Vault address can be specified using the environment variable:

```bash
export VAULT_ADDR="http://<EC2-PUBLIC-IP>:8200"
```

The Vault provider can then authenticate using the AppRole credentials.

For example:

```hcl
provider "vault" {
  address = var.vault_address

  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.vault_role_id
      secret_id = var.vault_secret_id
    }
  }
}
```

Define the variables:

```hcl
variable "vault_address" {
  type = string
}

variable "vault_role_id" {
  type      = string
  sensitive = true
}

variable "vault_secret_id" {
  type      = string
  sensitive = true
}
```

Example `terraform.tfvars`:

```hcl
vault_address   = "http://<EC2-PUBLIC-IP>:8200"
vault_role_id   = "<ROLE_ID>"
vault_secret_id = "<SECRET_ID>"
```

> **Important:** Do not commit `terraform.tfvars` if it contains a real Secret ID or other credentials. Add it to `.gitignore`.

The current Vault Terraform provider supports AppRole authentication through its AppRole login functionality.

---

# 15. Read the Secret Using Terraform

Use the `vault_kv_secret_v2` data source:

```hcl
data "vault_kv_secret_v2" "myapp" {
  mount = "secret"
  name  = "myapp"
}
```

The secret values can then be accessed using:

```hcl
data.vault_kv_secret_v2.myapp.data["username"]
```

and:

```hcl
data.vault_kv_secret_v2.myapp.data["password"]
```

For example:

```hcl
output "username" {
  value = data.vault_kv_secret_v2.myapp.data["username"]
}
```

Avoid outputting passwords or other sensitive values unless necessary.

---

# 16. Complete Authentication Flow

The complete workflow is:

```text
                         AWS EC2
                            |
                            ↓
                    HashiCorp Vault
                            |
              ┌─────────────┴─────────────┐
              |                           |
        AppRole Auth                 KV Secrets
              |                           |
       Role ID + Secret ID          secret/myapp
              |                           |
              ↓                           |
       Vault Authentication              |
              |                           |
              ↓                           |
         Vault Token                     |
              |                           |
              └──────────────┬────────────┘
                             ↓
                          Terraform
                             |
                             ↓
                     Read Vault Secret
```

---

# 17. Important Security Considerations

This project is intended for learning.

For a production environment:

* Do not use Vault development mode.
* Do not expose Vault port `8200` to the entire internet.
* Do not commit Role IDs, Secret IDs, tokens, or passwords to Git.
* Follow the principle of least privilege when creating policies.
* Use proper Vault storage and initialization/unsealing procedures.
* Use TLS/HTTPS for Vault communication.
* Consider response wrapping when distributing Secret IDs.
* Use short-lived credentials where appropriate.
* Protect Terraform state because secrets retrieved by Terraform can potentially appear in state depending on how they are used.
* Avoid storing secrets directly in `terraform.tfvars`.

---

# 18. Important Vault Concepts

### Authentication

Answers:

```text
"Who are you?"
```

Examples:

* Token
* AppRole
* AWS IAM
* Kubernetes
* Username/password

### Policies

Answer:

```text
"What are you allowed to do?"
```

Example:

```hcl
path "secret/data/myapp" {
  capabilities = ["read"]
}
```

### Secrets Engines

Answer:

```text
"How are secrets stored or generated?"
```

Examples:

* KV
* Database
* AWS
* PKI
* Transit

---

# 19. Key Takeaways

```text
Authentication
      ↓
Identifies the application
      ↓
Policy
      ↓
Determines what the application can access
      ↓
Secrets Engine
      ↓
Stores or generates secrets
```

For this project:

```text
AppRole
   ↓
terraform AppRole
   ↓
terraform policy
   ↓
secret/data/myapp
   ↓
Terraform
```

The main purpose of this integration is to avoid hard-coding sensitive credentials directly into Terraform configuration or application code and instead retrieve them securely from HashiCorp Vault.
