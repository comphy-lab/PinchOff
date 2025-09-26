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

FILE_NAME=${1:-arrestedCoalescence} # pass from command line, default to droplet_shear

mkdir -p $FILE_NAME

# Detect platform and set appropriate compiler flags
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CC99='mpicc -std=c99' qcc -Wall -O2 -D_MPI=1 -disable-dimensions -I$PWD/src-local -I$PWD/../src-local $FILE_NAME.c -o $FILE_NAME/$FILE_NAME -lm
else
    # Linux
    CC99='mpicc -std=c99 -D_GNU_SOURCE=1' qcc -Wall -O2 -D_MPI=1 -disable-dimensions -I$PWD/src-local -I$PWD/../src-local $FILE_NAME.c -o $FILE_NAME/$FILE_NAME -lm
fi
cd $FILE_NAME
mpirun -np 4 ./$FILE_NAME
cd ..
