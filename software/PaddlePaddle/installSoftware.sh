#!/bin/bash

set -e


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
ENVIRONMENT_NAME="$(printf '%s' "$ENVIRONMENT_NAME" | tr -d '\r\n')"

if [ -z "$ENVIRONMENT_NAME" ]; then

    echo "ERROR: Could not determine the Conda environment name."
    echo "Make sure environment.yml contains:"
    echo ""
    echo "    name: project-env"
    exit 1

fi

echo "      Environment to be created: $ENVIRONMENT_NAME"


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

    echo "      Accepting Anaconda channel Terms of Service..."

    "$CONDA" tos accept --override-channels \
        --channel https://repo.anaconda.com/pkgs/main

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to accept the main channel Terms of Service."
        exit 1
    fi

    "$CONDA" tos accept --override-channels \
        --channel https://repo.anaconda.com/pkgs/r

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to accept the R channel Terms of Service."
        exit 1
    fi

    "$CONDA" env create -f "$ENV_FILE"

    echo "      Environment created successfully."

fi


# ------------------------------------------
# Install software
# ------------------------------------------

echo ""
echo "[4/4] Installing software..."

# Initialize Conda for this Bash session
CONDA_BASE="$(dirname "$(dirname "$CONDA")")"
source "$CONDA_BASE/etc/profile.d/conda.sh" || {
    echo "ERROR: Could not initialize Conda."
    exit 1
}

# Activate by name
conda activate "$ENVIRONMENT_NAME" || {
    echo "ERROR: Failed to activate environment '$ENVIRONMENT_NAME'."
    exit 1
}

# Check whether Git is installed in WSL
if ! command -v git >/dev/null 2>&1; then
    echo "Git not found. Installing Git..."

    sudo apt-get update && sudo apt-get install -y git || {
        echo "ERROR: Failed to install Git."
        exit 1
    }
fi


# --------!!!!!!!!!!!!!!!!!!!!!!!!!!!!----------
# place all bash commands for installation below
# --------!!!!!!!!!!!!!!!!!!!!!!!!!!!!----------

python -m pip install paddlepaddle==2.6.2

mkdir -p "$HOME/software/PaddlePaddle"

git clone https://github.com/PaddlePaddle/PaddleDetection.git "$HOME/software/PaddlePaddle/PaddleDetection"

cd "$HOME/software/PaddlePaddle/PaddleDetection"
python -m pip install -r requirements.txt

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Enter password:  linuxnerd   (when prompted to install libgomp1)"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""
sudo apt-get update -qq
sudo apt-get install -y -qq libgomp1

python setup.py install

#check install
python -c "import ppdet; print('PaddleDetection imported successfully')"



echo ""
echo "=========================================="
echo "       Software Installation Complete"
echo "=========================================="
echo ""