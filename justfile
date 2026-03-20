project_name := "conda_Intro"

# Returns 'uv' if the command is installed, otherwise 'conda'
env_type := `[ -n "$CONDA_PREFIX" ] && echo "conda" || echo "uv"`

# Capture current date (YYYY-MM-DD)
date := `date +%Y-%m-%d`

# Default: List commands
default:
    @echo "Detecting {{ env_type }} environment"
    @if [ "{{env_type}}" = "uv" ]; then \
        @echo"This project only works on conda environment"; \
        exit 1; \
    fi
    @just --list

# Setup the environment
setup:
    @echo "🚀 Using {{env_type}} environment..."
    @echo "Please use command conda env create -f with the environment.yml file"
    pre-commit install --hook-type pre-commit --hook-type pre-push;

## Start of development commands

# Check environment health
health:
    @echo "🩺 Checking {{env_type}} environment health..."
    conda doctor;

# Export environment environment
condax:
    @echo "🩺 Exporting {{env_type}} environment to environment_{{date}}.yml..."
    conda env export --from-history --no-build > environment_{{date}}.yml

# Pre-commit hooks - Use this to run precommit first before committing
precommit:
    @echo "🔍  ({{env_type}}) Running pre-commit..."
    pre-commit run --all-files; \



# Remove build, cache, and coverage artifacts
clean:
    @echo "🧹 Cleaning up project..."
    rm -rf .pytest_cache
    rm -rf .coverage
    rm -rf htmlcov
    rm -rf .mypy_cache
    rm -rf .ruff_cache
    rm -rf .hypothesis
    find . -type d -name "__pycache__" -exec rm -rf {} +
    @echo "✨ Cleaned!"

# Run all checks
run: health clean
