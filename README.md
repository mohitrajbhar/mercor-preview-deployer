# Mercor Preview Deployer

[![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-623CE4?logo=terraform)](https://terraform.io)
[![Container](https://img.shields.io/badge/Container-ECS-FF9900?logo=amazon-aws)](https://aws.amazon.com/ecs/)
[![Database](https://img.shields.io/badge/Database-MongoDB-47A248?logo=mongodb)](https://mongodb.com)
[![Framework](https://img.shields.io/badge/Framework-Django-092E20?logo=django)](https://djangoproject.com)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)

> **Production-like preview environments for every Pull Request with isolated databases and SSL-enabled URLs**

Mercor Preview Deployer automatically creates isolated preview environments for each Pull Request, featuring dedicated ECS deployments and MongoDB databases. Built with Infrastructure as Code (Terraform) and integrated with GitHub Actions for seamless CI/CD automation.

## 🎯 Features

- **Production Parity**: ECS cluster deployments matching production architecture
- **🔒 SSL Enabled**: Automatic HTTPS with wildcard certificates (`pr-X.preview-url.trial.mercor.com`)
- **🗄️ Isolated Databases**: Dedicated MongoDB instance per PR for safe DDL testing
- **📦 Infrastructure as Code**: Complete Terraform automation with state management
- **⚡ Fast Deployments**: 3-5 minute environment provisioning
- **💰 Cost Optimized**: 93% cost reduction vs traditional VPC-per-PR approach
- **🔄 Auto Cleanup**: Automatic resource destruction on PR close/merge
- **📊 Monitoring**: Comprehensive health checks and observability

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                 Shared Infrastructure                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 Shared ALB                          │   │
│  │        *.preview-url.trial.mercor.com               │   │
│  └─────────────────┬───────────────────────────────────┘   │
│                    │                                       │
│  ┌─────────────────▼───────────────────────────────────┐   │
│  │               ECS Cluster                           │   │
│  │                                                     │   │
│  │ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │   │
│  │ │PR-1 │ │PR-2 │ │PR-5 │ │PR-12│ │PR-25│ │PR-N │   │   │
│  │ │Env  │ │Env  │ │Env  │ │Env  │ │Env  │ │Env  │   │   │
│  │ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

Each PR environment includes:
- **Django Application**: HTTP server on port 8000
- **MongoDB Database**: Isolated database (`mercor_pr_X`)
- **SSL Certificate**: Automatic HTTPS termination
- **Health Monitoring**: Real-time status dashboard

## Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- GitHub repository with Actions enabled
- Domain name configured in Route53
- Terraform >= 1.0
- Docker for local development

### 1. Initial Setup

```bash
# Clone the repository
git clone https://github.com/mercor/mercor-preview-deployer.git
cd mercor-preview-deployer

# Configure AWS credentials
aws configure

# Initialize shared infrastructure
cd infrastructure/terraform/environments/shared
terraform init
terraform plan
terraform apply
```

### 2. GitHub Actions Configuration

Add these secrets to your GitHub repository:

```bash
# Required Secrets
AWS_ACCESS_KEY_ID       # AWS access key for GitHub Actions
AWS_SECRET_ACCESS_KEY   # AWS secret key for GitHub Actions
AWS_REGION              # AWS region (e.g., us-east-1)
ECR_REPOSITORY          # ECR repository URI
DOMAIN_NAME             # Your domain (e.g., preview-url.trial.mercor.com)
```

### 3. Create Your First Preview Environment

```bash
# Create a new feature branch
git checkout -b feature/awesome-feature

# Make your changes
echo "# My awesome feature" >> README.md
git add . && git commit -m "Add awesome feature"

# Push and create PR
git push origin feature/awesome-feature
# Create PR via GitHub UI

# Your environment will be available at:
# https://pr-X.preview-url.trial.mercor.com
```

## 📁 Project Structure

```
mercor-preview-deployer/
├── .github/workflows/          # GitHub Actions workflows
│   ├── deploy-shared.yml      # Shared infrastructure deployment
│   ├── deploy-pr.yml          # PR environment creation
│   ├── update-pr.yml          # PR environment updates
│   ├── destroy-pr.yml         # PR environment cleanup
│   └── cleanup.yml            # Automated maintenance
├── django_app/                # Django application source
│   ├── api/                   # API application
│   ├── mercor_app/           # Django project settings
│   ├── templates/            # HTML templates
│   ├── Dockerfile            # Container configuration
│   ├── requirements.txt      # Python dependencies
│   └── manage.py             # Django management script
├── infrastructure/           # Terraform Infrastructure as Code
│   └── terraform/
│       ├── modules/         # Reusable Terraform modules
│       │   ├── vpc/         # VPC and networking
│       │   ├── ecs-cluster/ # ECS cluster configuration
│       │   ├── shared-alb/  # Application Load Balancer
│       │   ├── pr-services/ # PR environment services
│       │   └── acm-certificate/ # SSL certificate management
│       └── environments/    # Environment-specific configurations
│           ├── shared/      # Shared infrastructure
│           └── pr/          # PR environment template
└── docs/                   # Documentation
```

## Workflows

### Automatic Workflows

| Workflow | Trigger | Purpose | Duration |
|----------|---------|---------|----------|
| **Deploy PR** | PR opened/updated | Create/update preview environment | 8-10 min |
| **Destroy PR** | PR closed/merged | Remove preview environment | 4-5 min |
| **Cleanup** | Weekly 12 AM UTC Sunday | Remove stale environments | 5-10 min |

### Manual Workflows

| Workflow | Purpose | Usage |
|----------|---------|-------|
| **Deploy Shared** | Setup shared infrastructure | One-time setup |
| **Update PR** | Force update specific PR | Debugging/maintenance |

## Environment URLs

Each PR gets a unique URL following this pattern:

```
https://pr-{PR_NUMBER}.preview-url.trial.mercor.com
```

Example:
- `https://pr-456.preview-url.trial.mercor.com/health/` - Health check for PR #456

## Monitoring & Health Checks

### Health Check Dashboard

Each environment provides a comprehensive health check at `/health/`:

```bash
# JSON API
curl https://pr-123.preview-url.trial.mercor.com/health/?format=json

# Beautiful HTML dashboard
open https://pr-123.preview-url.trial.mercor.com/health/
```

## 💰 Cost Analysis

### Cost Comparison

| Approach | Cost per PR | Concurrent PRs | Monthly Cost |
|----------|------------|----------------|--------------|
| **VPC-per-PR** | $53.60 | 5 PRs | $268 |
| **Shared Infrastructure** | $4.00 | 20 PRs | $128 |
| **Savings** | **93%** | **4x capacity** | **52% reduction** |

### Cost Breakdown

**Shared Costs (One-time):**
- Application Load Balancer: $16.20/month
- NAT Gateway: $32.40/month
- EFS Storage: $3.00/month

**Per-PR Costs:**
- ECS Tasks: $3.00/month
- Data Transfer: $1.00/month

## 🛠️ Local Development

### Run Locally

```bash
# Start local environment
cd django_app
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows

# Install dependencies
pip install -r requirements.txt

# Start MongoDB (Docker)
docker run -d --name mongodb -p 27017:27017 mongo:5.0

# Configure environment
export MONGODB_HOST=localhost
export MONGODB_PORT=27017
export MONGODB_DATABASE=mercor_dev
export DEBUG=True

# Run Django
python manage.py runserver
```

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `MONGODB_HOST` | MongoDB hostname | `localhost` | |
| `MONGODB_PORT` | MongoDB port | `27017` | |
| `MONGODB_DATABASE` | Database name | `mercor_dev` | |
| `DEBUG` | Django debug mode | `False` | |
| `PR_NUMBER` | PR number for environment | `unknown` | |

## 🚨 Troubleshooting

### Common Issues

#### Environment Not Accessible

```bash
# Check ALB target group health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names django-pr-123 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

# Check ECS service status
aws ecs describe-services \
  --cluster mercor-shared-cluster \
  --services django-pr-123 mongodb-pr-123
```

#### Database Connection Issues

```bash
# Check MongoDB logs
aws logs get-log-events \
  --log-group-name /ecs/mongodb-pr-123 \
  --log-stream-name $(aws logs describe-log-streams \
    --log-group-name /ecs/mongodb-pr-123 \
    --order-by LastEventTime \
    --descending \
    --max-items 1 \
    --query 'logStreams[0].logStreamName' \
    --output text)
```

#### Terraform State Issues

```bash
# Refresh Terraform state
cd infrastructure/terraform/environments/pr
terraform refresh \
  -var="pr_number=123" \
  -var="django_image=mercor/django:pr-123"

# Force unlock if state is locked
terraform force-unlock LOCK_ID
```

### Debug Commands

```bash
# Get all PR environments
aws ecs list-services --cluster mercor-shared-cluster | grep django-pr

# Check resource costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# View workflow runs
gh run list --workflow=deploy-pr.yml
```

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes and test locally**
4. **Create Pull Request** (auto-deploys preview environment)
5. **Review and test** using your preview URL
6. **Merge when approved** (auto-cleanup)

### Code Standards

- **Terraform**: Follow [Terraform best practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- **Python**: PEP 8 compliance with Black formatting
- **Docker**: Multi-stage builds with minimal base images
- **Documentation**: Update README for significant changes

## 📋 Roadmap

### Phase 1: Core Features ✅
- [x] Shared infrastructure with ECS
- [x] Isolated MongoDB per PR
- [x] SSL certificate automation
- [x] GitHub Actions integration
- [x] Cost optimization

### Phase 2: Enhanced Features 🚧
- [ ] Auto-scaling based on traffic
- [ ] Database migration automation
- [ ] Custom domain support
- [ ] Blue-green deployments
- [ ] Performance monitoring

### Phase 3: Advanced Features 📋
- [ ] Multi-region deployment
- [ ] Integration testing suite
- [ ] Security scanning
- [ ] Backup and restore
- [ ] Cost alerting

## 📞 Support

### Getting Help

- **Documentation**: Check this README and `/docs` folder
- **Issues**: [Create GitHub Issue](https://github.com/mercor/mercor-preview-deployer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/mercor/mercor-preview-deployer/discussions)
- **Slack**: `#preview-environments` channel

### Emergency Contacts

- **Infrastructure Issues**: DevOps team
- **Application Issues**: Development team
- **Cost Concerns**: FinOps team

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **AWS ECS Team** for container orchestration platform
- **Terraform Team** for Infrastructure as Code tooling
- **GitHub Actions** for CI/CD automation
- **MongoDB Team** for the database platform
- **Django Community** for the web framework

---
