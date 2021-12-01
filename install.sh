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
    # sed -e 
    # fdisk /dev/sda
    # g
    # 1
    # 2048
    # +512M
    # t
    # 1
    # n
    # 2

    
    # w
    sfdisk /dev/sda/ >> echo "label: gpt
    label-id: 7C60523D-34C9-B149-ADDE-879B6FA897FB
    device: /dev/sda
    unit: sectors
    first-lba: 2048
    last-lba: 976773134
    sector-size: 512

    /dev/sda1 : start=        4096, size=      614400, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=30EC9CAE-A763-5B40-AC64-133EA26D9BC4
    /dev/sda2 : start=      618496, size=   957694630, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=015325DD-FCC0-1A4F-875C-1815D5CC0591
    /dev/sda3 : start=   958313126, size=    18454939, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F, uuid=9F78F90B-3488-774D-8D72-2FCE69CDB967"
    

    mkfs.fat -F32 /dev/sda1
    mkfs.ext4 /dev/sda2
    mkswap /dev/sda3
    swapon /dev/sda3
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
