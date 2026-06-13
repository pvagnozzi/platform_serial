# GitHub Setup Guide

This document describes the setup required to enable the new CI/CD workflows and automatic publishing.

## Required GitHub Secrets

**⚠️ UPDATED: Google OAuth Authentication**

Previously used `PUB_DEV_TOKEN`, but we now use **Google Service Account authentication** for better security and control.

See [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md) for complete setup instructions.

### Quick Reference: Secret Configuration

In GitHub Settings > Secrets and variables > Actions, configure:

- **`GOOGLE_SERVICE_ACCOUNT_JSON`** (required)
  - Value: Complete JSON file from Google Cloud Service Account
  - Purpose: Authenticate with pub.dev using Google OAuth
  - [Setup Instructions](./GOOGLE_OAUTH_SETUP.md)

## Workflows

### 1. Test on PR (`.github/workflows/test-pr.yml`)

**Triggers**:
- Pull requests to `main` or `develop`
- Pushes to `develop`
- Manual trigger via GitHub UI

**Jobs**:
- **Analyze**: Runs `flutter analyze` to check for issues
- **Test**: Runs unit, integration, and E2E tests
- **Build Example**: Builds the example app for web
- **PR Status**: Aggregates results and marks PR as passed/failed

**Status Checks**:
- ✅ All jobs must pass to merge PR
- 🟡 Example build failure is non-blocking (warning only)

### 2. Publish Release to pub.dev (`.github/workflows/publish-release.yml`)

**Triggers**:
- Push to `main` branch (when `pubspec.yaml` is updated)
- Manual trigger via GitHub UI with optional version input

**Jobs**:
- Validates that all tests pass
- Extracts version from `pubspec.yaml`
- Authenticates with Google Cloud using Service Account
- Creates a GitHub Release with tag `v{version}`
- Publishes to pub.dev using Google OAuth
- Logs the results

**Preconditions**:
- `GOOGLE_SERVICE_ACCOUNT_JSON` must be configured
- Service Account must have pub.dev publisher access
- Version in `pubspec.yaml` must be updated before merging to main
- All tests must pass
- See [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md) for complete setup

## Git Flow Integration

The repository uses **Git Flow** with the following structure:

```
main                    (production releases)
 └─→ tag: v{version}
 └─→ trigger: publish-release.yml

develop                 (integration branch)
 ├─→ feature/*          (new features)
 ├─→ release/*          (pre-release)
 └─→ hotfix/*           (critical fixes)
```

See `docs/GITFLOW.md` for detailed workflow documentation.

## Version Management

**GitVersion** is configured in `GitVersion.yml` to:
- Automatically bump versions based on branch
- Generate semantic version tags
- Support pre-release versions (alpha, rc)

### Version Auto-Increment Rules

| Branch | Version Tag | Increment |
|--------|------------|-----------|
| `main` | v{version} | Patch |
| `develop` | v{version}-alpha | Minor |
| `feature/*` | v{version}-alpha.{branchname} | Minor |
| `release/*` | v{version}-rc | Patch |

## Local Setup (Optional)

To install and use GitVersion locally:

```bash
# Using Homebrew (macOS/Linux)
brew install gitversion

# Using Chocolatey (Windows)
choco install gitversion.portable

# Using .NET
dotnet tool install --global GitVersion.Tool
```

View current version:
```bash
gitversion
```

## Troubleshooting

### Workflow fails with "PUB_DEV_TOKEN not found"

**Solution**: Ensure `PUB_DEV_TOKEN` is configured in GitHub Settings > Secrets.

### Release publishes but version doesn't update

**Cause**: `pubspec.yaml` wasn't updated before merging to main.

**Solution**: Ensure version is bumped in `pubspec.yaml` before releasing.

### Test workflow doesn't run on PR

**Cause**: File path filters may exclude your changes.

**Solution**: The workflow triggers on:
- Changes to `lib/**`, `test/**`, `example/**`, platform-specific code
- Changes to `pubspec.yaml`
- Changes to `.github/workflows/test-pr.yml`

### Can't merge PR because checks are pending

**Solution**: Wait for the workflow to complete, or check logs for errors:
- Click "Actions" tab
- Select your PR workflow
- Review job logs

## Next Steps

### Setup (Required Once)

1. ✅ Read [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md)
2. ✅ Create Google Cloud Project and Service Account
3. ✅ Generate JSON credentials
4. ✅ Configure `GOOGLE_SERVICE_ACCOUNT_JSON` in GitHub Secrets
5. ✅ Associate Service Account with pub.dev publisher access

### Release Workflow

1. Update version in `pubspec.yaml`
2. Commit and push to `develop`
3. Create Pull Request to `main`
   - `test-pr.yml` workflow runs automatically
   - ✅ All checks must pass to merge
4. Merge PR to `main`
   - `publish-release.yml` workflow triggers automatically
   - 📦 Package is published to pub.dev
   - 🏷️ GitHub Release is created with tag `v{version}`

---

For more details, see:
- [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md) — Complete Google OAuth setup guide
- [GITFLOW.md](./GITFLOW.md) — Git Flow branching model
- [GitVersion.yml](../GitVersion.yml) — Semantic versioning config
- [.github/workflows/test-pr.yml](../.github/workflows/test-pr.yml) — Test workflow
- [.github/workflows/publish-release.yml](../.github/workflows/publish-release.yml) — Publish workflow
