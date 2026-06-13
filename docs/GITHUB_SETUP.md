# GitHub Setup Guide

This document describes the setup required to enable the new CI/CD workflows and automatic publishing.

## Required GitHub Secrets

Configure the following secrets in your GitHub repository settings:

### Settings > Secrets and variables > Actions

#### 1. `PUB_DEV_TOKEN`

**Purpose**: Authenticate with pub.dev API to publish releases automatically.

**Steps**:
1. Go to https://pub.dev/account
2. Create an API token under "Account Settings"
3. Copy the token value
4. In GitHub:
   - Navigate to Settings > Secrets and variables > Actions
   - Click "New repository secret"
   - Name: `PUB_DEV_TOKEN`
   - Value: Paste the pub.dev API token
   - Click "Add secret"

**Note**: This token should be kept private and never committed to the repository.

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
- Push to `main` branch
- Manual trigger via GitHub UI with optional version input

**Jobs**:
- Validates that all tests pass
- Extracts version from `pubspec.yaml`
- Creates a GitHub Release with tag `v{version}`
- Publishes to pub.dev using the API token
- Comments on the PR/issue with status

**Preconditions**:
- `PUB_DEV_TOKEN` must be configured
- Version in `pubspec.yaml` must be updated before merging to main
- All tests must pass

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

1. ✅ Commit these files to the repository
2. ✅ Configure `PUB_DEV_TOKEN` in GitHub Settings
3. ✅ Create your first feature branch from `develop`
4. ✅ Open a PR to `develop` to test the workflow
5. ✅ Merge to `main` and watch the auto-publish workflow

---

For more details, see:
- [docs/GITFLOW.md](../GITFLOW.md)
- [GitVersion.yml](../GitVersion.yml)
- [.github/workflows/test-pr.yml](../workflows/test-pr.yml)
- [.github/workflows/publish-release.yml](../workflows/publish-release.yml)
