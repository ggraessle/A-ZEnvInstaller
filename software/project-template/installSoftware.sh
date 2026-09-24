#!/bin/bash

set -e

# ==========================================
# Software Installation
# ==========================================

echo ""
echo "=========================================="
echo "        Software Installation"
echo "=========================================="
echo ""


# ------------------------------------------
# Locate this script
# ------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENV_FILE="$SCRIPT_DIR/environment.yml"

echo "Software directory:"
echo "  $SCRIPT_DIR"

echo ""
echo "Environment file:"
echo "  $ENV_FILE"


# ------------------------------------------
# Check environment.yml
# ------------------------------------------

if [ ! -f "$ENV_FILE" ]; then

    echo ""
    echo "ERROR: environment.yml was not found."
    exit 1

fi


# ------------------------------------------
# Configuration
# ------------------------------------------

CONDA="/home/linuxnerd/miniconda3/bin/conda"


# ------------------------------------------
# Check Miniconda
# ------------------------------------------

echo ""
echo "[1/4] Checking Miniconda..."

if [ ! -x "$CONDA" ]; then

    echo "ERROR: Miniconda was not found."
    echo "The WSL bootstrap must be completed first."
    exit 1

fi

echo "      Miniconda found."


# ------------------------------------------
# Read environment name
# ------------------------------------------

echo ""
echo "[2/4] Reading environment configuration..."

ENVIRONMENT_NAME=$(
    grep '^[[:space:]]*name:' "$ENV_FILE" |
    head -n 1 |
    sed 's/^[[:space:]]*name:[[:space:]]*//'
)

if [ -z "$ENVIRONMENT_NAME" ]; then

    echo "ERROR: Could not determine the Conda environment name."
    echo "Make sure environment.yml contains:"
    echo ""
    echo "    name: project-env"
    exit 1

fi

echo "      Environment: $ENVIRONMENT_NAME"


# ------------------------------------------
# Create environment
# ------------------------------------------

echo ""
echo "[3/4] Checking Conda environment..."

if "$CONDA" env list | awk '{print $1}' | grep -Fxq "$ENVIRONMENT_NAME"; then

    echo "      Environment already exists."

else

    echo "      Environment does not exist."
    echo "      Creating environment..."

    "$CONDA" env create -f "$ENV_FILE"

    echo "      Environment created successfully."

fi


# ------------------------------------------
# Install software
# ------------------------------------------

echo ""
echo "[4/4] Installing software..."

# ==========================================
# SOFTWARE-SPECIFIC INSTALLATION GOES HERE
# ==========================================

echo "      Software installation commands go here."


# ------------------------------------------
# Verification
# ------------------------------------------

echo ""
echo "Verifying installation..."

"$CONDA" run -n "$ENVIRONMENT_NAME" python --version

echo ""
echo "=========================================="
echo "       Software Installation Complete"
echo "=========================================="
echo ""