# Git Flow Workflow

This project uses the Git Flow branching model for version control and release management.

## Branch Types

### Main Branches

- **`main`** - Production-ready code. Every commit here is tagged with a semantic version.
  - Automatically creates releases on pub.dev
  - Tag format: `v<major>.<minor>.<patch>`

- **`develop`** - Integration branch for features. Contains the latest development changes.
  - Base branch for feature development
  - Automatically versioned as pre-release (alpha)

### Supporting Branches

#### Feature Branches (`feature/*` or `feature-*`)

Used for new features or enhancements.

```bash
# Create from develop
git checkout -b feature/my-feature develop

# When complete, create a Pull Request to develop
# After code review and approval, merge to develop
```

Example naming:
- `feature/language-flags`
- `feature/dark-theme-support`
- `feature/serial-optimization`

#### Release Branches (`release/*` or `release-*`)

Used to prepare a new production release.

```bash
# Create from develop when ready for release
git checkout -b release/1.2.0 develop

# Only bugfixes, version bumps, and release preparation
# Create a Pull Request to main
# Also merge back to develop
```

Example naming:
- `release/1.0.0`
- `release/1.2.3`

#### Hotfix Branches (`hotfix/*` or `hotfix-*`)

Used to quickly patch production issues.

```bash
# Create from main
git checkout -b hotfix/critical-bug main

# After fix, merge to main and develop
```

Example naming:
- `hotfix/serial-connection-crash`
- `hotfix/memory-leak`

## Semantic Versioning with GitVersion

This project uses **GitVersion** for automatic semantic versioning.

### Version Format

`<major>.<minor>.<patch>[-<prerelease>]`

- **Major**: Breaking changes
- **Minor**: New features (backward compatible)
- **Patch**: Bug fixes

### Auto-Versioning Rules

| Branch | Version Tag | Increment | Example |
|--------|------------|-----------|---------|
| `main` | v{version} | Patch | v1.0.1 |
| `develop` | v{version}-alpha | Minor | v1.1.0-alpha |
| `feature/*` | v{version}-alpha.branchname | Minor | v1.1.0-alpha.my-feature |
| `release/*` | v{version}-rc | Patch | v1.0.0-rc |
| `hotfix/*` | v{version} | Patch | v1.0.1 |

### Viewing Current Version

```bash
# Display current version (requires GitVersion CLI)
gitversion
```

## Pull Request Workflow

### Creating a Pull Request

1. **Create a feature branch** from `develop`
2. **Make your changes** and commit with descriptive messages
3. **Push to remote** and create a PR
4. **Ensure tests pass** (automated via GitHub Actions)
5. **Request code review**
6. **Address feedback** and update the PR
7. **Merge** after approval

### Commit Message Conventions

Use semantic commit messages for clarity:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style changes (no logic change)
- `refactor`: Code refactoring without feature/fix
- `test`: Adding or updating tests
- `chore`: Build process, dependencies, etc.

Examples:
```
feat(localization): add language flags to selector
fix(theme): resolve dark mode toggle persistence
docs(readme): update installation instructions
```

## Release Process

### Creating a Release

1. **Create a release branch** from `develop`
   ```bash
   git checkout -b release/1.0.0 develop
   ```

2. **Bump version** in `pubspec.yaml` and example app
   ```yaml
   version: 1.0.0+1
   ```

3. **Update CHANGELOG.md** with changes

4. **Create a Pull Request** to `main`

5. **After approval**, merge to `main` and `develop`:
   ```bash
   # Tag is created automatically
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin main --tags
   ```

6. **GitHub Actions** automatically publishes to pub.dev

### Publishing to pub.dev

Publishing happens automatically when:
- A release is created (PR merged to `main` with version tag)
- GitHub Actions workflow `publish-release.yml` triggers

Requires:
- `PUB_DEV_TOKEN` repository secret (pub.dev API token)

## Tips & Best Practices

- **Always pull latest** before creating a new branch
- **Keep feature branches short-lived** (max 2-3 weeks)
- **Rebase before merging** to keep history clean
- **Use draft PRs** for work-in-progress
- **Delete branches** after merging
- **Run tests locally** before pushing

## Troubleshooting

### "Develop is behind main"

```bash
git checkout develop
git pull origin develop
git merge main
git push origin develop
```

### "Need to remove accidental commit from main"

```bash
git revert <commit-hash>
git push origin main
```

### "Want to cancel a release"

```bash
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

## References

- [Git Flow Model](https://nvie.com/posts/a-successful-git-branching-model/)
- [Semantic Versioning](https://semver.org/)
- [GitVersion Documentation](https://gitversion.net/)
- [Conventional Commits](https://www.conventionalcommits.org/)
