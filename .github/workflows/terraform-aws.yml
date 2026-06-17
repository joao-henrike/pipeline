name: "Terraform AWS CI/CD"

on:
  push:
    branches: [ main ]
    paths: [ 'aws/**' ]

jobs:
  terraform:
    name: "Deploy Infraestrutura Fase 1"
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./aws

    steps:
      - name: Checkout do Repositorio
        uses: actions/checkout@v3

      - name: Configurar Credenciais AWS via Secrets
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
          aws-region: us-east-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Apply
        run: terraform apply -auto-approve
