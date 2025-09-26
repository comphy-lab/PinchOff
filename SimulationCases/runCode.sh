#!/bin/bash

# Check if .project_config exists
if [ ! -f ../.project_config ]; then
    echo "Error: .project_config not found!"
    echo "Please run the installation script first:"
    echo "  cd .. && ./reset_install_requirements.sh"
    exit 1
fi

source ../.project_config
echo "BASILISK: $BASILISK"

# Check if qcc is available
if ! command -v qcc &> /dev/null; then
    echo "Error: qcc command not found!"
    echo "Please run the installation script first:"
    echo "  cd .. && ./reset_install_requirements.sh"
    exit 1
fi

# Parse command-line arguments
VIEW_MODE=false
FILE_NAME=""

for arg in "$@"; do
    case $arg in
        --view)
            VIEW_MODE=true
            ;;
        *)
            if [[ -z "$FILE_NAME" && "$arg" != "--view" ]]; then
                FILE_NAME="$arg"
            fi
            ;;
    esac
done

# Set default filename if not provided
FILE_NAME=${FILE_NAME:-plateau}

mkdir -p $FILE_NAME

# Conditional compilation based on mode
if [ "$VIEW_MODE" = true ]; then
    # Visualization mode - no MPI, with OpenGL libraries
    qcc -O2 -Wall -disable-dimensions -I$PWD/src-local -I$PWD/../src-local $FILE_NAME.c -o $FILE_NAME/$FILE_NAME -L$BASILISK/gl -lglutils -lfb_tiny -lm
else
    # MPI mode - existing compilation
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        CC99='mpicc -std=c99' qcc -Wall -O2 -D_MPI=1 -disable-dimensions -I$PWD/src-local -I$PWD/../src-local $FILE_NAME.c -o $FILE_NAME/$FILE_NAME -lm
    else
        # Linux
        CC99='mpicc -std=c99 -D_GNU_SOURCE=1' qcc -Wall -O2 -D_MPI=1 -disable-dimensions -I$PWD/src-local -I$PWD/../src-local $FILE_NAME.c -o $FILE_NAME/$FILE_NAME -lm
    fi
fi

cd $FILE_NAME

# Conditional execution based on mode
if [ "$VIEW_MODE" = true ]; then
    # Direct execution for visualization
    ./$FILE_NAME
else
    # MPI execution
    mpirun -np 4 ./$FILE_NAME
fi

cd ..
