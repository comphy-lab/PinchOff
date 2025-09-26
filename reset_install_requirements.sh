#!/bin/zsh
# tested on MacOS only. Let us know if you find issues running with Linux by opening an issue. 
# modify using http://basilisk.fr/src/INSTALL 
# ensures that we are always using the latest version of basilisk

# Check if --hard flag is passed
HARD_RESET=false
if [[ "$1" == "--hard" ]]; then
    HARD_RESET=true
fi

# Function to check prerequisites
check_prerequisites() {
    local missing_tools=()
    local found_tools=()

    echo "Checking prerequisites..."
    echo ""

    # Check for make
    if ! command -v make > /dev/null 2>&1; then
        missing_tools+=("make")
    else
        found_tools+=("make")
        echo "\033[0;32m✓ make is installed\033[0m"
    fi

    # Check for darcs
    if ! command -v darcs > /dev/null 2>&1; then
        missing_tools+=("darcs")
    else
        found_tools+=("darcs")
        echo "\033[0;32m✓ darcs is installed\033[0m"
    fi

    # Check for gcc
    if ! command -v gcc > /dev/null 2>&1; then
        missing_tools+=("gcc")
    else
        found_tools+=("gcc")
        echo "\033[0;32m✓ gcc is installed\033[0m"
    fi

    echo ""

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "\033[0;31mError: Missing required tools: ${missing_tools[*]}\033[0m"
        echo ""

        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS installation instructions
            for tool in "${missing_tools[@]}"; do
                case "$tool" in
                    "make")
                        echo "To install make:"
                        echo "  xcode-select --install"
                        echo ""
                        ;;
                    "darcs")
                        echo "To install darcs:"
                        echo "  brew install darcs"
                        echo ""
                        ;;
                    "gcc")
                        echo "To install gcc:"
                        echo "  xcode-select --install"
                        echo ""
                        ;;
                esac
            done
        else
            # Linux installation instructions
            for tool in "${missing_tools[@]}"; do
                case "$tool" in
                    "make")
                        echo "To install make on Linux:"
                        echo "  Ubuntu/Debian: sudo apt-get install build-essential"
                        echo "  RHEL/CentOS: sudo yum groupinstall 'Development Tools'"
                        echo ""
                        ;;
                    "darcs")
                        echo "To install darcs:"
                        echo "  Visit https://darcs.net/ for installation instructions"
                        echo ""
                        ;;
                    "gcc")
                        echo "To install gcc on Linux:"
                        echo "  Ubuntu/Debian: sudo apt-get install build-essential"
                        echo "  RHEL/CentOS: sudo yum groupinstall 'Development Tools'"
                        echo ""
                        ;;
                esac
            done
        fi

        echo "Please install the missing tools and try again."
        exit 1
    else
        echo "\033[0;32m✅ All prerequisites are satisfied!\033[0m"
        echo ""
    fi
}

# Function to install basilisk
install_basilisk() {
    darcs clone http://basilisk.fr/basilisk
    cd basilisk/src

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Using MacOS"
        ln -s config.osx config
    else
        echo "Using Linux"
        ln -s config.gcc config
    fi
    make -k
    make
}

# Check prerequisites first
check_prerequisites

# Remove project config always
rm -rf .project_config

# Check if basilisk needs to be installed
if [[ "$HARD_RESET" == true ]] || [[ ! -d "basilisk" ]]; then
    echo "Installing basilisk..."
    rm -rf basilisk
    install_basilisk
else
    echo "Using existing basilisk installation..."
    cd basilisk/src
fi

# Setup environment variables
echo "export BASILISK=$PWD" >> ../../.project_config
echo "export PATH=\$PATH:\$BASILISK" >> ../../.project_config

source ../../.project_config

# Check if qcc is working properly
echo "\nChecking qcc installation..."
if ! qcc --version > /dev/null 2>&1; then
    echo "\033[0;31mError: qcc is not working properly.\033[0m"
    echo "Please ensure you have Xcode Command Line Tools installed."
    echo "You can install them by running: xcode-select --install"
    echo "For more details, visit: http://basilisk.fr/src/INSTALL"
    exit 1
else
    echo "\033[0;32mqcc is properly installed.\033[0m"
    qcc --version
fi
