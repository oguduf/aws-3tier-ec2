# AWS 3-Tier Task Manager

A small React, FastAPI, and MySQL application deployed to AWS with Docker, Terraform, and GitHub Actions.

## Architecture

```text
Internet
  -> Application Load Balancer (public subnets)
  -> EC2 Auto Scaling Group (private subnets)
       -> Nginx + React container
       -> FastAPI container
  -> RDS MySQL (private subnets)

Project 2 adds an independent ECS/Fargate ALB and service in the same shared VPC.
It reuses the existing private RDS database and immutable ECR images for this lab.
```

The network and application use separate Terraform state files. The same modules are reused for `dev`, `test`, and `production`; only their variable files change.

## Project layout

```text
app/
  frontend/                 React UI and Nginx image
  backend/                  FastAPI API and tests
deploy/ec2/                 EC2 startup template
infra/
  bootstrap/                Creates the Terraform state bucket
  network/                  Shared VPC, subnets, routes, IGW, and NAT
  application/              ALB, EC2/ASG, ECR, RDS, IAM, and monitoring
  ecs/                      ECS/Fargate ALB, service, task roles, logs, and autoscaling
.github/workflows/
  ci.yml                    Automatic tests and Terraform validation
  security.yml              Security scans on pull requests or manual runs
  bootstrap.yml             State-bucket plan/apply
  network.yml               Network plan/apply/destroy
  infrastructure.yml        Application infrastructure plan/apply/destroy
  app.yml                   Build, scan, push, and deploy containers
  ecs.yml                   ECS/Fargate plan/apply/destroy
```

There are four manual operational workflows. `ci.yml` is separate because it runs automatically for pull requests and pushes to `dev` or `main`.

## Run locally

1. Copy `.env.example` to `.env`.
2. Replace the sample passwords in `.env`.
3. Run `docker compose up --build`.
4. Open `http://localhost:5173`.
5. API documentation is at `http://localhost:8000/docs`.

Do not commit `.env`.

## GitHub setup

Create these repository variables under **Settings -> Secrets and variables -> Actions -> Variables**:

| Variable | Example | Purpose |
| --- | --- | --- |
| `AWS_REGION` | `us-east-2` | Region used by every workflow |
| `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/GitHubActionsRole` | One AWS OIDC deployment role |

`TF_STATE_BUCKET` is created automatically after the bootstrap workflow applies successfully.

Create GitHub environments named `dev`, `test`, and `production`. Add required reviewers to `production` so production jobs pause for approval.

The `dev` environment is HTTP-only for this lab. `test` and `production` require HTTPS and a validated ACM certificate in `AWS_REGION`, provided through `ACM_CERTIFICATE_ARN`. The AWS role trust policy must allow this repository to use GitHub OIDC. Its AWS permissions must cover the resources managed by these Terraform files, ECR image pushes, SSM Parameter Store updates, and Auto Scaling instance refreshes. No AWS access keys are stored in GitHub.

The trust-policy condition should be repository-scoped so it works for the bootstrap job and all three GitHub environments. Replace the account and repository values with yours:

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USER/aws-3tier-ec2:*"
    }
  }
}
```

## First deployment

Run the workflows in this order:

1. **Bootstrap Terraform State** -> `apply` with a globally unique bucket name.
2. **Shared Network Terraform** -> choose an environment -> `apply`.
3. **Application Infrastructure Terraform** -> choose the same environment -> `apply`.
4. **Build and Push Application Images** -> choose the same environment.

The EC2 startup script waits for the first application images if infrastructure is created before the image workflow finishes. The image workflow publishes both the commit SHA and the environment tag, then starts an Auto Scaling instance refresh.

Use `plan` before `apply`. For cleanup, destroy application infrastructure before its network. The shared state bucket is deliberately protected from deletion.

## Environment settings

- `infra/network/environments/*.tfvars` contains each VPC CIDR.
- `infra/application/environments/*.tfvars` contains capacity and RDS Multi-AZ settings.
- Production uses two application instances and Multi-AZ RDS.

## Project 2: ECS on Fargate

Project 2 is isolated from the EC2 deployment: it has its own ECS cluster, Fargate
service, task security group, target group, ALB, autoscaling policy, log group, and
Terraform state key. It reuses the shared VPC, ECR repositories, RDS endpoint, and
RDS secret from Project 1.

Deployment order:

1. Run **Build and Push Application Images** for the environment. This creates the
   normal backend image tag and the ECS-specific frontend image tag.
2. Copy the commit SHA shown by that workflow.
3. Run **ECS Fargate Terraform** with `apply`, the same environment, and that commit
   SHA as `image_tag`.
4. Open the ECS ALB DNS name from Terraform output.

Before the first ECS apply, extend the GitHub OIDC deployment-role policy so
`iam:PassRole` allows the ECS task roles to be passed to `ecs-tasks.amazonaws.com`.
The role also needs the existing ECS, Application Auto Scaling, CloudWatch Logs, KMS,
EC2, ELB, IAM, Secrets Manager, and S3 permissions used by the Terraform stack.

For cleanup, run **ECS Fargate Terraform** with `destroy` before deleting the shared
network or Project 1 application stack.

## CI checks

`CI Checks` runs application tests and Terraform validation. The separate `Security` workflow runs on every pull request and can also be started manually. It includes:

- Gitleaks secret scan
- Checkov Terraform scan
- Trivy code, secret, dependency, and configuration scan
- production container builds and Trivy image vulnerability scans

All security jobs fail the workflow when they find a high- or critical-severity problem, so you can correct issues before deploying.
