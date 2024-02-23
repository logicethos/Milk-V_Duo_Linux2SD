#!/bin/bash

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


# Check if an image file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <image-file>"
    exit 1
fi

IMAGE_FILE=$1

# Check if the image file exists
if [ ! -f "$IMAGE_FILE" ]; then
    echo "Image file not found: $IMAGE_FILE"
    exit 1
fi

# Check if the image file is mounted
if mount | grep -q "$IMAGE_FILE"; then
    echo "The image file is mounted! - Exiting."
    exit 1
fi

while true; do
    # Get the list of removable devices and store it in a variable
    DEVICE_LIST=$(lsblk -d -n -p -o NAME,SIZE,RM | awk '$3=="1"{print $1, "("$2")"}')
    DEVICE_LIST_ARRAY=($DEVICE_LIST "rescan" "(rescan devices)")

    # Use whiptail to show a menu to select the SD card, including a rescan option
    SD_CARD_DEVICE=$(whiptail --title "Select SD Card" --menu "Choose the SD Card to use or Rescan" 20 60 10 "${DEVICE_LIST_ARRAY[@]}" 3>&2 2>&1 1>&3)

    # Check if a device was selected
    if [ -z "$SD_CARD_DEVICE" ]; then
        echo "No device selected."
        exit 1
    elif [ "$SD_CARD_DEVICE" = "rescan" ]; then
        continue # Go back to the start of the loop to rescan
    else
        echo "Selected device: $SD_CARD_DEVICE"
        break # Exit loop if a device other than rescan is selected
    fi
done


# Confirm before proceeding
if ! whiptail --yesno "Are you sure you want to write to $SD_CARD_DEVICE?" 10 60; then
    echo "Operation cancelled."
    exit 1
fi

# Unmount the SD card
echo "Unmounting $SD_CARD_DEVICE..."
sudo umount ${SD_CARD_DEVICE}* 2> /dev/null

# Copy the image to the SD card using dd
echo "Copying image to $SD_CARD_DEVICE. This may take a while..."
sudo dd if="$IMAGE_FILE" of="$SD_CARD_DEVICE" bs=4M status=progress conv=fdatasync

echo "Syncing..."
sync
echo "Copy complete."

echo "Expaning rootfs..."
# Identify the last partition
# Get the number of the last partition
PART_NUM=$(sudo parted $SD_CARD_DEVICE -ms print | awk -F: 'END{print $1}')

# Get the start sector of the last partition
START=$(sudo parted $SD_CARD_DEVICE -ms unit s print | awk -F: -v num=$PART_NUM '$1 == num {print $2}' | sed 's/s//')

# Remove the last partition and recreate it using the full space
sudo parted $SD_CARD_DEVICE rm $PART_NUM
sudo parted $SD_CARD_DEVICE --script -- unit s mkpart primary $START 100%

# Inform the OS of partition table changes
sudo partprobe $SD_CARD_DEVICE

#  Resize the filesystem on the last partition
# Ensure the partition path is correct, e.g., /dev/sdx2
sudo resize2fs ${DEV}${PART_NUM}
sync

echo "Partition and filesystem resize completed."

echo "Ejecting the SD card..."
eject $SD_CARD_DEVICE
