{pkgs, ...}: {
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
      efi.canTouchEfiVariables = true;
    };
    plymouth = {
      enable = true;
      theme = "bgrt"; # Manufacturer logo with a spinner
    };
    consoleLogLevel = 0; # Hide kernel output during boot
    initrd.verbose = false; # Hide initrd output
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
    blacklistedKernelModules = [
      "dccp"
      "sctp"
      "rds"
      "tipc"
      "ax25"
      "netrom"
      "x25"
      "rose"
      "decnet"
      "econet"
      "af_802154"
      "ipx"
      "appletalk"
      "firewire-core"
      "firewire-ohci"
    ];
    kernel.sysctl = {
      "kernel.yama.ptrace_scope" = 1;
      "kernel.kptr_restrict" = 1;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
    };
  };

  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  nix = {
    package = pkgs.lix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = [
        "https://nix-community.cachix.org"
        "https://mic92.cachix.org"
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "mic92.cachix.org-1:vL3/V4C9t6xBFZ8c4hA29EfGaKjXcruzjxj815V/V24="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
  };

  system.stateVersion = "26.05";
}
