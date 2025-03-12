#!/bin/bash
#
# Script name: dsm.sh
# Author: Aleksey Mishakov
# Website: https://github.com/amishakov
# Date: 11 March, 2025
# Purpose: Automatic creation of Proxmox VM 8.3+ using Arc Loader for DSM 7+.
#

set -e

# Ask for VMID
read -p "Enter Virtual Machine ID for Synology DSM install: " VMID

# Check if VMID already exists
if qm status $VMID &> /dev/null
then
    read -p "VM $VMID already exists. Do you want to remove it? (y/n) " choice
    case "$choice" in
        y|Y )
            qm stop $VMID
            qm destroy $VMID
            echo "VM $VMID has been removed."
            ;;
        * )
            echo "Please enter a different VMID."
            exit 1
            ;;
    esac
fi

# Check if unzip is installed, install if not
if ! command -v unzip &> /dev/null; then
    echo "unzip could not be found, installing..."
    apt install unzip -y
fi

# Get latest release version from GitHub API
version=$(curl -s https://api.github.com/repos/AuxXxilium/arc/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
newversion=${version:1}
 
# Construct download URL using latest release version
url="https://github.com/AuxXxilium/arc/releases/download/$version/arc-$version-evo.vmdk-dyn.zip"

# Download and extract Arc image
wget $url
image_folder="/var/lib/vz/template/iso/"
unzip "arc-$version-evo.vmdk-dyn.zip" -d $image_folder
rm "arc-$version-evo.vmdk-dyn.zip"

# Create virtual machine
qm create "$VMID" \
 --name DSM7 \
 --memory 4096 \
 --sockets 1 \
 --cores 2 \
 --cpu host \
 --net0 e1000=00:11:32:FE:A9:F1,bridge=vmbr0 \
 --ostype l26 \
 --bios seabios \
 --boot order=sata0

# Import Arc image as boot disk
image="/var/lib/vz/template/iso/arc-dyn.vmdk"
qm importdisk "$VMID" "$image" local --format raw
qm set $VMID --sata0 local:$VMID/vm-$VMID-disk-0.raw

# Start the virtual machine
# qm start "$VMID"
