#!/bin/bash

SPATH=$(dirname "$(realpath "$0")")
cd $SPATH

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    # Not running as root, prompt for root password and rerun the script
    echo "This script needs to run with root privileges."
    sudo "$0" "$@"
    exit $?
fi


# Check if whiptail is installed
if ! command -v whiptail &> /dev/null; then
    echo "whiptail is not installed."

    # Check if apt is available
    if command -v apt &> /dev/null; then
        echo "Attempting to install whiptail using apt..."
        apt update && apt install -y whiptail

        # Verify if whiptail installed successfully
        if command -v whiptail &> /dev/null; then
            echo "whiptail installed successfully."
        else
            echo "Failed to install whiptail."
            exit 1
        fi
    else
        echo "apt is not available on this system. Cannot install whiptail automatically."
        exit 1
    fi
else
    echo "whiptail is already installed."
fi


find_directories_with_env() {
    local IFS=$'\n' # Change the Internal Field Separator to handle directory names with spaces
    directories=($(find . -type f -name 'ENV' -exec dirname {} \; | sed 's|^\./||' | sort -u))
}

# Generate the whiptail arguments list from the directories
generate_whiptail_args() {
    whiptail_args=()
    for dir in "${directories[@]}"; do
        whiptail_args+=("$dir" "")
    done
}

# Display the directories in a whiptail dialog
select_directory() {
    find_directories_with_env
    generate_whiptail_args

    if [ ${#whiptail_args[@]} -eq 0 ]; then
        echo "No directories containing a file named 'ENV' were found."
        exit 1
    fi

    CHOICE=$(whiptail --title "Select Build" --menu "Choose Build:" 20 60 10 "${whiptail_args[@]}" 3>&1 1>&2 2>&3)

    if [ $? -eq 0 ]; then
        echo "You selected: $CHOICE"
    else
        echo "No selection made or dialog was cancelled."
        exit 1
    fi
}

select_directory

ROOTPW=$(whiptail --title "Password Prompt" --inputbox "Please root password for your new image:" 8 39 3>&1 1>&2 2>&3)

if [ -z "$ROOTPW" ]; then
    echo "User cancelled the password prompt."
    exit 0
fi


source $CHOICE/ENV

docker build $CHOICE -t duo

if [ -d "out" ]; then
  rm -R --force out/*
fi
mkdir -p out

docker run -it --rm --privileged -e BOARD=$BOARD -e CONFIG=$CONFIG -e ROOTPW=$ROOTPW  -v $SPATH/$CHOICE:/build -v $SPATH/out:/duo-buildroot-sdk/install duo bash /build/build.sh


if [[ ! -d "out" ]]; then
    echo "No image found."
    exit 1
fi    

# Find the first .img file within subdirectories of "out"
IMAGE=$(find out -type f -name "*.img" | head -n 1)
    
if [[ -z "$IMAGE" ]]; then
    echo "No image found."
    exit 1
fi


if whiptail --title "Make SD Card" --yesno "Do you want to make an SD card with image:\n$IMAGE" 20 60; then
    source writeToSD.sh $IMAGE
fi
