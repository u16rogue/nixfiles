{ config, lib, modulesPath, pkgs, ... }:

{
    imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    boot = {
        kernelModules = [ "kvm-amd" ];

        loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
        };

        initrd = {
            availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
            kernelModules = [ "cryptd" ];
            luks.devices."persist-luks".device = "/dev/disk/by-label/persist-luks";
        };

        swraid = {
            enable = true;
            mdadmConf = "MAILADDR user@example.com";
        };
    };

    fileSystems = {
        "/boot" = {
            device = "/dev/disk/by-label/boot";
            fsType = "vfat";
            options = [ "fmask=0077" "dmask=0077" ];
        };

        "/" = {
            device = "none";
            fsType = "tmpfs";
            options = [ "defaults" "size=2G" "mode=755" ];
            neededForBoot = true;
        };

        "/persist" = {
            depends = [ "/" ];
            neededForBoot = true;
            device = "/dev/disk/by-label/persist";
            fsType = "ext4";
        };

        "/nix" = {
            depends = [ "/persist" ];
            neededForBoot = true;
            device = "/persist/nix";
            fsType = "none";
            options = [ "bind" ];
        };

        "/var/log" = {
            depends = [ "/persist" ];
            neededForBoot = true;
            device = "/persist/var/log";
            fsType = "none";
            options = [ "bind" ];
        };
    };

    environment.persistence."/persist" = {
        enable = true;
        hideMounts = true;

        directories = [
            # System state
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
            "/var/log"

            # Networking
            "/etc/NetworkManager/system-connections"

            # Bluetooth
            "/var/lib/bluetooth"

            # SSH (entire directory for all host keys)
            "/etc/ssh"
        ];

        files = [
            # Critical for systemd/dbus
            # Must be a bind-mount (not symlink) to satisfy ConditionPathIsMountPoint
            "/etc/machine-id"
        ];
    };

    hardware = {
        graphics.enable = true;
        nvidia = {
            modesetting.enable = true;
            open = true;
            package = config.boot.kernelPackages.nvidiaPackages.latest;
        };
        cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };

    networking = {
        hostName = "mistyriver";
        networkmanager.enable = true;
        firewall.enable = true;
    };

    services = {
        pipewire = {
            enable = true;
            pulse.enable = true;
        };
        xserver.videoDrivers = [ "nvidia" ];
        openssh.enable = true;
    };

    environment.systemPackages = [
        pkgs.asusctl
    ];

    time.timeZone = "Asia/Taipei";

    system.stateVersion = "25.11";
}
