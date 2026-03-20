# Conda Environment Guide
*A Complete Reference for Managing Python Environments on macOS (Apple Silicon) & Linux*

---

## Table of Contents
1. [Installing Miniconda](#1-installing-miniconda)
2. [Initialising Conda & Shell Setup](#2-initialising-conda--shell-setup)
3. [Managing Environments](#3-managing-environments)
4. [Package Installation Strategy: Conda vs pip](#4-package-installation-strategy-conda-vs-pip)
5. [Version Pinning Strategy](#5-version-pinning-strategy)
6. [Locking Environments with conda-lock](#6-locking-environments-with-conda-lock)
7. [Installing Packages](#7-installing-packages)
8. [Maintaining & Updating Environments](#8-maintaining--updating-environments)
9. [Automated Environment Creation Script](#9-automated-environment-creation-script)
10. [Exporting & Importing Environments](#10-exporting--importing-environments)
11. [Sample ML Environment](#11-sample-ml-environment)
12. [Quick Reference Cheat Sheet](#12-quick-reference-cheat-sheet)
---
## 1. Installing and Removing Miniconda

Miniconda is the recommended minimal installer — it includes only Python and conda, so you start lean and install only what your project needs. This keeps environments smaller and faster to resolve than a full Anaconda install.

> ⚠️ **Note:** As of August 15, 2025, Anaconda has stopped building new packages for Intel-based Macs (osx-64). Only Apple Silicon (ARM/osx-arm64) is supported for macOS going forward. If you are still on an Intel Mac, Anaconda recommends migrating to Apple Silicon or switching to Linux using dev containers.

### macOS (Apple Silicon — M1/M2/M3/M4)

```bash
# Create the install directory and download the Apple Silicon installer
mkdir -p ~/miniconda3
curl https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh \
     -o ~/miniconda3/miniconda.sh

# Run the installer (installs to ~/miniconda3 by default)
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3

# Remove the installer script once done
rm ~/miniconda3/miniconda.sh
```

### Linux

```bash
# Create the install directory and download the Linux installer
mkdir -p ~/miniconda3
curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
     -o ~/miniconda3/miniconda.sh

# Run the installer
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3

# Remove the installer script once done
rm ~/miniconda3/miniconda.sh
```

> 💡 The `-b` flag runs the installer in batch/silent mode (accepts licence automatically) and `-u` updates an existing installation if one is found. Shell profiles are **not** modified automatically — run `conda init` after install (see Section 2).

### Verify Installation

```bash
conda --version
conda info
```

### Remove Miniconda (macOS & Linux)

#### Option A — Using the built-in uninstall script (Miniconda v24.11.1 and later)

Miniconda ships with an `uninstall.sh` script that handles removal cleanly:

```bash
# Find your install path
conda info --base

# Run the uninstaller (add sudo if installed to /opt/miniconda3)
~/miniconda3/uninstall.sh

# To also remove caches, config files, and user data in one go:
~/miniconda3/uninstall.sh --remove-caches --remove-config-files user --remove-user-data
```

#### Option B — Manual removal (all versions)

Use this if you installed an older version that does not include `uninstall.sh`:

```bash
# Reverse conda init changes from all shell config files
conda init --reverse --all

# Delete the miniconda3 directory
# Use whichever path matches your installation
rm -rf ~/miniconda3
# or if installed system-wide via .pkg installer:
sudo rm -rf /opt/miniconda3

# Remove config, cache, and tool-specific hidden folders
rm -rf ~/.conda ~/.condarc ~/.continuum
sudo rm -rf ~/.anaconda ~/.ipynb_checkpoints ~/.jupyter \
             ~/.keras ~/.matplotlib ~/.ipython

# Clean up any leftover notebook checkpoints
find . -type d -name ".ipynb_checkpoints" -exec rm -rf {} +

# Verify no checkpoints remain
find . -type d -name ".ipynb_checkpoints"
```

> 💡 After removal, open a new terminal window and confirm `(base)` is gone from your prompt and `conda` returns "command not found".

---

## 2. Initialising Conda & Shell Setup

After installation, conda must be initialised for your shell so that `conda activate` works correctly in all terminal sessions.

### Initialise Conda

```bash
# Initialise conda for your current shell
conda init

# Or explicitly target your shell
conda init zsh    # macOS default (Zsh)
conda init bash   # Linux / Bash users
```

### Reload Your Shell

```bash
# Apply changes without restarting terminal
source ~/.zshrc    # macOS (Zsh)
source ~/.bashrc   # Linux (Bash)
```

### Verify Shell Integration

After reloading, your prompt should show `(base)` to indicate the base conda environment is active.

```bash
# Confirm conda is available
conda --version

# Check which Python is being used
which python
```

### Optional: Disable Auto-Activation of Base

If you prefer conda not to activate the base environment every time you open a terminal:

```bash
conda config --set auto_activate false
```

To re-enable it later:

```bash
conda config --set auto_activate true
```

### Reverse / Undo Shell Initialisation

```bash
# Remove conda hooks from all detected shell config files
conda init --reverse --all
```

---

## 3. Managing Environments

### Create an Environment

```bash
# Create with a specific Python version
conda create --name ENV_NAME python=3.11

# Create from an environment file (preserving name)
conda env create -f ENV_NAME.yml

# Create from environment file with a different name
conda env create -n NEW_NAME --file environment.yml

# Create from a requirements.txt file
conda create --name ENV_NAME python=3.12 --file requirements.txt
```

### Activate & Deactivate

```bash
conda activate ENV_NAME
conda deactivate
```

### List & Remove Environments

```bash
# List all environments
conda env list

# Remove an environment and all its packages
conda remove -n ENV_NAME --all
```

### Clone an Environment

```bash
conda create --name NEW_ENV_NAME --clone EXISTING_ENV_NAME
```

---

## 4. Package Installation Strategy: Conda vs pip

Understanding the difference between conda and pip — and when to use each — is essential for keeping your environments stable and reproducible.

### The Installation Order: Always Follow This Priority

```
1. conda (defaults channel)  →  2. conda-forge  →  3. pip (last resort only)
```

Always try to install from conda channels first. Only fall back to pip when a package is genuinely unavailable through conda.

#### Step 1 — Try the defaults channel first

The `defaults` channel is Anaconda's curated channel. Packages here are tested together and are generally the most stable.

```bash
conda install PACKAGE_NAME -y
```

#### Step 2 — Try conda-forge if not found in defaults

`conda-forge` is a community-maintained channel with a much wider selection of packages, often more up to date than defaults. Many packages (e.g. `jupyterlab-spellchecker`, `py-xgboost`) are only available here.

```bash
conda install -c conda-forge PACKAGE_NAME -y
```

#### Step 3 — Use pip only as a last resort

If a package cannot be found on any conda channel, install it with pip. However, follow the rules below carefully to avoid breaking your environment.

```bash
pip install PACKAGE_NAME
```

> ⚠️ **Once you start using pip in an environment, always run conda installs before pip installs.** Mixing them in the wrong order can cause conflicts that are difficult to resolve.

---

### How Conda and pip Handle Dependencies Differently

This is the most important thing to understand when managing conda environments.

#### Conda — Full Dependency Solver

Conda has a **holistic dependency solver**. When you install a package, conda looks at the entire environment — every package already installed — and resolves a compatible set of versions for all dependencies at once. It will upgrade, downgrade, or hold back packages as needed to keep the whole environment consistent.

```bash
# Conda checks the full environment before installing
conda install scikit-learn -y
# → resolves numpy, scipy, joblib versions that work together with everything else already installed
```

#### pip — No Awareness of the Existing Environment

pip has **no knowledge of packages already installed by conda** (or even other pip packages in some cases). It simply installs the latest version of the requested package and its declared dependencies, without checking whether those versions conflict with anything else in the environment.

This means pip can silently overwrite conda-managed packages with incompatible versions, breaking other things without any warning.

#### The Critical pip Rule: Install Related Packages Together in One Command

Because pip resolves dependencies only within a single invocation, you must install all related packages **in a single `pip install` command**. If you install them one by one in separate commands, pip may install incompatible versions since it cannot see what the previous command just installed.

```bash
# ❌ WRONG — pip resolves each independently, may produce conflicts
pip install package-a
pip install package-b
pip install package-c

# ✅ CORRECT — pip resolves all together in one pass
pip install package-a package-b package-c
```

This is especially important for packages with shared dependencies (e.g. anything that depends on `numpy`, `protobuf`, `pydantic`, or `typing-extensions`).

#### Summary

| | conda | pip |
|---|---|---|
| Knows what's already installed | ✅ Yes — full environment solver | ❌ No — installs in isolation |
| Handles C/Fortran binaries | ✅ Yes | ⚠️ Sometimes (via wheels) |
| Package availability | Curated (defaults + conda-forge) | Vast (all of PyPI) |
| Risk of breaking environment | Low (if used consistently) | Higher (especially when mixed) |
| Best practice | Use first, for most packages | Last resort; batch installs in one line |

---

## 5. Version Pinning Strategy

The goal is to keep environments as flexible as possible while only constraining what actually needs constraining. Over-pinning creates unnecessary dependency conflicts and makes environments harder to update; under-pinning can leave you exposed to breaking changes from unstable packages.

### The Golden Rule: Pin Python, Leave Everything Else Free

When creating an environment, **only pin the Python version**. Let conda resolve the latest compatible versions of all other packages. This gives you the most up-to-date, compatible set of packages with the least friction.

```yaml
# ✅ Recommended starting point — pin Python only
name: MY_ENV
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.11      # ← pin Python to a minor version
  - numpy            # ← no pin, conda picks the latest compatible version
  - pandas
  - scikit-learn
  - matplotlib
```

### Why Not Pin Everything by Default?

Pinning every package to an exact version feels safe but causes real problems:

- **Dependency conflicts** — conda's solver struggles to satisfy dozens of exact-version constraints simultaneously, especially across packages that evolve together (e.g. `numpy`, `scipy`, `pandas`)
- **Stale environments** — pinned environments miss security patches and performance improvements
- **Reduced portability** — exact build hashes are platform-specific and may not exist on a different OS or architecture
- **Maintenance burden** — every package update requires manual version bumps across all environments

### When to Start Pinning a Specific Package

Only add a version pin when you have a concrete reason. Common triggers:

| Situation | Action |
|---|---|
| A package release breaks your code | Pin to the last working version |
| A package is known to be unstable at its latest version | Pin to the last stable release |
| A framework requires a specific dependency version (e.g. TensorFlow + CUDA) | Pin the constrained package |
| You need to reproduce results from a specific experiment | Pin all packages at that point in time |
| A package has a known regression in a specific version | Pin to skip that version using `!=` |

### Pinning Syntax

```yaml
dependencies:
  - python=3.11          # Pin to minor version (3.11.x) — recommended for Python
  - numpy=1.26           # Pin to minor version (1.26.x)
  - pandas=2.2.3         # Pin to exact version
  - scikit-learn>=1.3    # Minimum version — allow anything 1.3 and above
  - tensorflow>=2.14,<3  # Version range — compatible with 2.x, not 3.x
  - protobuf!=3.20.*     # Exclude a known bad version range
```

> 💡 Pinning to a **minor version** (e.g. `numpy=1.26`) is usually the right balance — it allows patch updates (bug fixes, security patches) while preventing major API changes.

### Pinning Python: Minor Version vs Patch Version

Always pin Python to its **minor version** only, not the full patch:

```yaml
# ✅ Recommended — allows patch updates (3.11.1 → 3.11.9)
- python=3.11

# ⚠️ Too tight — blocks patch updates, reduces portability
- python=3.11.4
```

### Practical Workflow

Start free, pin only when something breaks:

```
1. Create environment with only Python pinned
2. Install packages freely — let conda pick versions
3. Test your code
4. If a future update breaks something:
   a. Identify the offending package
   b. Add a version pin for that package only
   c. Leave all other packages free
5. Repeat — keep the number of pins as small as possible
```

### Example: Progressively Pinning a Problem Package

```yaml
# Stage 1 — initial environment, nothing pinned except Python
dependencies:
  - python=3.11
  - tensorflow
  - pandas
  - scikit-learn

# Stage 2 — tensorflow 2.17 introduced a breaking change, pin it
dependencies:
  - python=3.11
  - tensorflow=2.16      # pinned due to breaking API change in 2.17
  - pandas               # still free
  - scikit-learn         # still free

# Stage 3 — pandas 3.0 dropped a function we rely on, pin it too
dependencies:
  - python=3.11
  - tensorflow=2.16      # pinned
  - pandas=2.2           # pinned to 2.x
  - scikit-learn         # still free
```

### Using `conda.pinned` for Environment-Level Pins

For long-lived environments, you can maintain a pinning file that conda always respects, separate from your `environment.yml`:

```bash
# Create a pinned file inside the active environment
# (conda checks this file on every install/update)
echo "numpy 1.26.*" >> $CONDA_PREFIX/conda-meta/pinned
echo "protobuf !=3.20.*" >> $CONDA_PREFIX/conda-meta/pinned
```

This lets you constrain packages without embedding pins in the environment file itself, which is useful when you want the `environment.yml` to stay portable.

---

## 6. Locking Environments with conda-lock

Version pinning (Section 5) controls which packages you *want*. conda-lock takes this a step further — it records the *exact* resolved packages, versions, and build strings for every platform you care about, producing a lockfile that guarantees byte-for-byte reproducible installs every time.

conda-lock is a lightweight library that generates fully reproducible lock files for conda environments by performing a full dependency solve for each target platform. As an added benefit, it acts as an external pre-solve — when installing from a generated lockfile, the conda solver is not invoked at all, making installs significantly faster.

### The Two-File Pattern

The recommended workflow is to maintain two files side by side:

| File | Purpose | Who edits it |
|---|---|---|
| `environment.yml` | Your intent — packages you want, loosely pinned | You, manually |
| `conda-lock.yml` | The full resolved lock — exact versions + build strings for all platforms | Generated by conda-lock, never edited by hand |

Versioned direct dependency files give you easy updates; locked dependency files give you reproducibility. In practice, you want both.

### Installing conda-lock

Install conda-lock into your base environment via conda-forge:

```bash
# Recommended — install into base so it's always available
conda install --channel=conda-forge --name=base conda-lock -y

# Or with pipx for full isolation
pipx install conda-lock
```

### Basic Usage

```bash
# Generate a lock file for macOS Apple Silicon and Linux
conda-lock -f environment.yml -p osx-arm64 -p linux-64

# This produces:
#   conda-osx-arm64.lock
#   conda-linux-64.lock

# Install from the lockfile (skips the solver — fast and exact)
conda create -n MY_ENV --file conda-osx-arm64.lock

# Regenerate the lockfile after updating environment.yml
conda-lock -f environment.yml -p osx-arm64 -p linux-64

# Update a single package in the lockfile without full regeneration
conda-lock update --package numpy
```

### Specifying Target Platforms in environment.yml

You can embed target platforms directly in your `environment.yml` so you don't need to pass `-p` flags every time:

```yaml
name: ML311
channels:
  - pytorch
  - conda-forge
  - defaults
platforms:          # non-standard key, read by conda-lock
  - osx-arm64
  - linux-64
dependencies:
  - python=3.11
  - numpy
  - pandas
  - scikit-learn
```

Then just run:

```bash
conda-lock -f environment.yml
```

---

### When to Use conda-lock

Use conda-lock when **reproducibility across machines or time is critical**:

- **Team projects** — everyone on the team gets the exact same environment, regardless of when they set up their machine
- **CI/CD pipelines** — test runs use the identical package set, not whatever happens to be latest at build time
- **Production deployments** — the environment that was tested is exactly what runs in production
- **Docker containers** — embed the lockfile in the image for fully pinned, fast builds
- **Research and papers** — lock the environment used to produce results so they can be reproduced months or years later
- **After a stable environment is confirmed** — once you've tested your environment and everything works, lock it to freeze that state

### When NOT to Use conda-lock

Skip conda-lock when **flexibility and iteration speed matter more than exact reproducibility**:

- **Personal or exploratory projects** — solo work where you are the only user and frequent package changes are expected
- **Early-stage development** — when you're still discovering which packages you need and rapidly changing the environment
- **Learning and experimentation** — notebooks or scripts where you want the latest packages and don't need to reproduce exact results
- **Simple single-platform setups** — if you only ever work on one machine and never share the environment, the overhead of maintaining a lockfile may not be worth it
- **When `environment.yml` with version pinning is enough** — for many personal projects, a well-pinned `environment.yml` provides sufficient reproducibility without the extra tooling

> 💡 A useful rule of thumb: if someone else needs to run your code and get the same result, use conda-lock. If it's just for yourself and you're still actively developing, a pinned `environment.yml` is usually enough.

### Lockfile Workflow in Practice

```
Development loop:
┌─────────────────────────────────────────────────────┐
│  1. Edit environment.yml (add/change packages)      │
│  2. conda-lock -f environment.yml                   │  ← regenerate lock
│  3. conda create -n MY_ENV --file conda-osx-arm64.lock │
│  4. Test your code                                  │
│  5. Commit both environment.yml AND conda-lock.yml  │  ← commit both
└─────────────────────────────────────────────────────┘

Team / CI setup:
┌─────────────────────────────────────────────────────┐
│  1. Clone the repo                                  │
│  2. conda create -n MY_ENV --file conda-osx-arm64.lock │  ← exact env
│  3. Run code — guaranteed identical environment     │
└─────────────────────────────────────────────────────┘
```

> 💡 Always commit both `environment.yml` and the generated lockfile(s) to version control. The `environment.yml` captures your intent and is easy to update; the lockfile captures the exact resolved state for reproducibility.

---

## 7. Installing Packages

### Jupyter & Notebook Tools

```bash
# JupyterLab with spell checker (via conda-forge)
conda install -c conda-forge jupyterlab jupyterlab-spellchecker ipywidgets -y

# Kernel + widgets for VS Code Jupyter Notebooks
conda install ipykernel ipywidgets -y
# Then install the 'Code Spell Checker' extension in VS Code
```

### Core Data Science Packages

```bash
# Pandas (data manipulation)
conda install pandas -y

# Graphing & interactive plotting
conda install matplotlib seaborn ipympl ipywidgets -y

# Scientific computing (if not installing ML packages)
conda install scipy numpy -y
```

### Machine Learning Packages

```bash
# TensorFlow
conda install tensorflow -y

# PyTorch (with torchvision and torchaudio)
conda install pytorch torchvision torchaudio -c pytorch -y

# Scikit-learn
conda install scikit-learn -y

# XGBoost
conda install -c conda-forge py-xgboost -y
```

---

## 8. Maintaining & Updating Environments

### Manual Update

```bash
# Activate first, then update all packages
conda activate ENV_NAME
conda update --all -y
```

### Automated Bulk Update Script

The `update_conda.sh` script loops through every conda environment, exports a backup before and after updating, then updates all conda packages.

**Usage:**

```bash
bash update_conda.sh

# Backups are saved to: ~/Downloads/conda_backup/
#   ENV_NAME_backup_before_update.yml
#   ENV_NAME_backup_after_update.yml
```

**Full script (`update_conda.sh`):**

```bash
#!/bin/bash

# Ensure the script stops if any command fails
set -e

# Source the conda.sh script to enable conda commands
CONDA_BASE=$(conda info --base)
source "$CONDA_BASE/etc/profile.d/conda.sh"

# Define the backup directory in ~/Downloads/conda_backup
BACKUP_DIR="$HOME/Downloads/conda_backup"
mkdir -p "$BACKUP_DIR"

# Get the list of all conda environments
envs=$(conda env list | awk 'NR>2 && !/^#/ {print $1}')

# Loop through each environment
for env in $envs; do
    echo "Backing up Conda environment before update: $env"
    conda env export -n "$env" > "$BACKUP_DIR/${env}_backup_before_update.yml"

    echo "Updating Conda environment: $env"
    conda activate "$env"

    # Update all Conda packages
    conda update --all -y

    # Ensure pip is installed inside Conda env
    conda install pip -y

    conda deactivate

    echo "Backing up Conda environment after update: $env"
    conda env export -n "$env" > "$BACKUP_DIR/${env}_backup_after_update.yml"
done

echo "All environments backed up (before & after update) and updated."
```

### Clean Up Conda Cache

```bash
# Dry run (see what would be removed)
conda clean -a -d

# Run cleanup (removes unused packages, tarballs, caches)
conda clean -a -y
```

---

## 9. Automated Environment Creation Script

The `condaCreateEnv.sh` script automates creating a new environment with a standard set of packages. Pass the environment name as an argument.

**Usage:**

```bash
bash condaCreateEnv.sh MY_ENV_NAME
```

**Full script (`condaCreateEnv.sh`):**

```bash
#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <environment_name>"
  exit 1
fi

# Assign the first argument to a variable
env_name="$1"

# Create the conda environment with the specified name
conda create --name "$env_name" python=3.11 -y

# Check if the environment was created successfully
if [ $? -eq 0 ]; then
  echo "Environment '$env_name' created successfully."

  # Initialize conda (ensure conda is set up in the current shell session)
  eval "$(conda shell.bash hook)"

  # Activate the environment and install additional packages
  conda activate "$env_name"
  echo "Installing Jupyter tools"
  conda install -c conda-forge jupyterlab jupyterlab-spellchecker -y
  echo "Installing basic packages"
  conda install -y pandas matplotlib seaborn ipympl ipywidgets

  if [ $? -eq 0 ]; then
    echo "Packages installed successfully in '$env_name'."
  else
    echo "Failed to install packages in '$env_name'."
    exit 3
  fi
else
  echo "Failed to create environment '$env_name'."
  exit 2
fi
```

**The script will:**
- Create a new conda environment with Python 3.11
- Install JupyterLab with the spell checker extension (via conda-forge)
- Install pandas, matplotlib, seaborn, ipympl, and ipywidgets

---

## 10. Exporting & Importing Environments

Exporting your environment ensures reproducibility across machines. Always activate the environment before exporting.

### Export Options

| Flag | Description |
|---|---|
| *(no flags)* | Full export with all dependencies and build hashes (exact reproduction) |
| `--no-builds` | Include version numbers but omit build hashes (more portable) |
| `--from-history` | Only list packages you explicitly installed (cleaner, cross-platform) |
| `--from-history --no-builds` | Explicit packages with versions, no build strings (recommended for sharing) |

```bash
# Activate the environment first
conda activate ENV_NAME

# Full export (exact, platform-specific)
conda env export > ENV_NAME.yml

# Export with versions, no build hashes
conda env export --no-builds > ENV_NAME.yml

# Clean export — only what you installed
conda env export --from-history > ENV_NAME.yml

# Clean export with versions, no build strings (recommended for sharing)
conda env export --from-history --no-builds > ENV_NAME.yml

# Restore environment on a new machine
conda env create -f ENV_NAME.yml
```

### Update an Existing Environment from File

```bash
# Update and remove packages not in the file (--prune)
conda env update --file environment.yml --prune
```

---

## 11. Sample ML Environment

The `ml_env.yml` below defines a portable ML environment named **ML311** running Python 3.11. Build hashes and the `prefix` field are omitted so conda resolves the correct builds for your platform (Apple Silicon or Linux) at install time.

**Packages included:**
- JupyterLab with spell checker
- NumPy, Pandas, SciPy
- Matplotlib, Seaborn, ipympl, ipywidgets
- Scikit-learn, XGBoost
- PyTorch (with torchvision and torchaudio)
- TensorFlow
- BeautifulSoup4, lxml, openpyxl for data ingestion

**`ml_env.yml`:**

```yaml
name: ML311
channels:
  - pytorch
  - conda-forge
  - defaults
dependencies:
  - python=3.11
  # Jupyter
  - jupyterlab
  - ipykernel
  - ipywidgets
  - ipympl
  # Core data science
  - numpy
  - pandas
  - scipy
  # Visualisation
  - matplotlib
  - seaborn
  # Machine learning
  - scikit-learn
  - pytorch
  - torchvision
  - torchaudio
  - tensorflow
  - py-xgboost
  # Data ingestion
  - beautifulsoup4
  - lxml
  - openpyxl
  - pip
  - pip:
    - jupyterlab-spellchecker
```

### Create the ML311 Environment

```bash
# Create from the yml file
conda env create -f ml_env.yml

# Activate
conda activate ML311

# Launch VSCode
code .
```

> 💡 Omitting build hashes and the `prefix` field keeps this file cross-platform. Conda will resolve the correct builds for your system (Apple Silicon or Linux) at install time.

---

## 12. Quick Reference Cheat Sheet

| Command | Description |
|---|---|
| `conda create -n NAME python=3.11` | Create new environment with Python 3.11 |
| `conda activate NAME` | Activate environment |
| `conda deactivate` | Deactivate current environment |
| `conda env list` | List all environments |
| `conda remove -n NAME --all` | Delete environment |
| `conda create --clone SRC -n DEST` | Clone environment |
| `conda install PKG -y` | Install a package |
| `conda update --all -y` | Update all packages in active env |
| `conda env export > file.yml` | Export full environment (with build hashes) |
| `conda env export --from-history --no-builds > file.yml` | Export clean (portable) environment |
| `conda env create -f file.yml` | Restore environment from file |
| `conda env update --file file.yml --prune` | Sync environment with file |
| `conda clean -a -y` | Clean package caches |
| `conda info` | Show conda info and active env |
| `conda init zsh` | Initialise conda for Zsh (macOS default) |
| `conda init bash` | Initialise conda for Bash (Linux) |
| `conda init --reverse --all` | Remove conda from all shell configs |
| `conda config --set auto_activate false` | Disable auto-activation of base env |

---

*For more information visit: [docs.conda.io](https://docs.conda.io)*
