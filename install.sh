preload() {
    echo "Loading keyboard..."
    # loadkeys uk

    echo "Checking network..."
    if [ "ping -c1 www.google.com" ] ; then
        echo "All good! Time to install!"
    else
        echo "Network unavailable :("
        return
    fi
}

setup_drives() {
    echo "Formatting drives..."
    fdisk /dev/sda
    g
    1
    2048
    +512M
    t
    1
    n
    2

    
    w
    mkfs.fat -F32 /dev/sda1
    mkfs.ext4 /dev/sda2
    mount /dev/sda2 /mnt
    mkdir /mnt/efi
    mount /dev/sda1 /mnt/efi
}

setup_mirrors() {
    echo "Setting up mirrorlist..."
    pacstrap /mnt base linux linux-firmware base-devel nano reflector
    cp /mnt/etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist.bak
    reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
}

setup_filesystem() {
    echo "Generating filesystem..."
    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt
}

setup_details() {
    echo "Configuring locales..."
    ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
    hwclock --systohc
    echo en_GB.UTF-8 UTF-8 >> /etc/locale/gen
    locale-gen
    echo LANG=en_GB.UTF-8 >> /etc/locale.conf
    echo KEYMAP=uk >> /etc/vconsole.conf
    
    echo "Enter your hostname: "
    read HOSTNAME
    echo $HOSTNAME >> /etc/hostname

    echo 
    "127.0.0.1   localhost
    ::1          localhost
    127.0.1.1    $HOSTNAME.localdomain    $HOSTNAME"
    >> /etc/hosts

    echo "Enter your username: "
    read USERNAME
    useradd -m $USERNAME

    echo "Enter your root password: "
    passwd 
    passwd USERNAME
    usermod -aG wheel,audio,video,optical,storage,rfkill USERNAME

    pacman -S sudo
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

    pacman -S grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/efi/ --bootloader-id=Arch
    grub-mkconfig -o /boot/grub/grub.cfg

    pacman -S networkmanager
    systemctl enable NetworkManager
    exit
    shutdown now
}

preload
setup_drives
setup_mirrors
setup_filesystem
setup_details
