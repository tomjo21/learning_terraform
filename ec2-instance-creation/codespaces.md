# Using GitHub Codespaces with Terraform

## Overview

GitHub Codespaces provides a cloud-hosted development environment that you can configure with all the tools needed for Terraform development — no local installation required. By using a **dev container**, you can ensure that Terraform, the AWS CLI, and any other dependencies are automatically installed and consistent for everyone working on the project.

## Steps

### 1. Fork the Repository

Fork the repository containing your Terraform project to your own GitHub account. This gives you a copy you can freely modify without affecting the original project.

- Navigate to the repository on GitHub.
- Click **Fork** in the top-right corner.
- Select your account/organization as the destination.

### 2. Create a Codespace on the Appropriate Branch

- Go to your forked repository.
- Click the **Code** button, then select the **Codespaces** tab.
- Choose the branch you want to work on (e.g., `main` or a feature branch).
- Click **Create codespace on [branch name]**.

This will spin up a cloud-based VS Code environment connected to your repository.

### 3. Add Dev Container Configuration Files

Dev containers are configured using a `.devcontainer` folder in your repository, typically containing:

- `devcontainer.json` — defines the container settings, extensions, and features.
- `Dockerfile` (optional) — for custom container images.

Example `.devcontainer/devcontainer.json` for Terraform + AWS:

```json
{
  "name": "Terraform AWS Dev Environment",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/terraform:1": {
      "version": "latest"
    },
    "ghcr.io/devcontainers/features/aws-cli:1": {
      "version": "latest"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "hashicorp.terraform",
        "amazonwebservices.aws-toolkit-vscode"
      ]
    }
  },
  "postCreateCommand": "terraform -version && aws --version"
}
```

**Key elements:**
- `features` — installs Terraform and the AWS CLI using pre-built Dev Container Features.
- `customizations.vscode.extensions` — automatically installs the Terraform and AWS Toolkit extensions in VS Code.
- `postCreateCommand` — runs a command after the container is built, useful for verification.

### 4. Configure AWS Credentials

Since Codespaces runs in the cloud, you'll need to provide AWS credentials securely:

- **Recommended:** Store credentials as **Codespaces secrets**:
  1. Go to your GitHub repository (or account) settings.
  2. Navigate to **Secrets and variables > Codespaces**.
  3. Add secrets such as `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
  4. These will be automatically available as environment variables inside your Codespace.

- Alternatively, run `aws configure` manually inside the Codespace terminal (not recommended for shared/public repos).

### 5. Rebuild the Container

If you add or modify the `.devcontainer` configuration after the Codespace is already running, you need to rebuild it for changes to take effect:

- Open the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`).
- Run **Codespaces: Rebuild Container**.

This reprocesses the `devcontainer.json` file and reinstalls any specified features/extensions.

### 6. Verify Terraform and AWS Are Installed

Open a terminal inside the Codespace and run:

```bash
terraform -version
aws --version
```

You should see version output for both tools, confirming they were installed correctly by the dev container.

You can also verify AWS credentials are working:

```bash
aws sts get-caller-identity
```

This should return your AWS account ID, user ID, and ARN if credentials are configured correctly.

## Using Terraform Inside the Codespace

Once your environment is verified, you can work with Terraform as usual:

```bash
terraform init
terraform plan
terraform apply
```

## Tips

- Commit your `.devcontainer` folder to the repository so every collaborator gets the same environment automatically.
- Use Codespaces secrets rather than hardcoding AWS credentials in files.
- Consider adding a `.gitignore` entry for `.terraform/` and `*.tfstate` files to avoid committing sensitive state data.
- You can customize the base image or add more `features` (e.g., Docker-in-Docker, Kubernetes CLI) depending on your project's needs.

## Summary

| Step | Action |
|------|--------|
| 1 | Fork the repository |
| 2 | Create a Codespace on the desired branch |
| 3 | Add `.devcontainer` config files for Terraform and AWS |
| 4 | Configure AWS credentials via Codespaces secrets |
| 5 | Rebuild the container to apply changes |
| 6 | Verify Terraform and AWS CLI are installed |