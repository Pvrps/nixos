# rea-vm: isolated microVM for reverse engineering with REA.
#
# The whole agent (OpenCode + Claude Code + the REA MCP server) runs here, so
# hostile analysis targets can only reach this VM: no host secrets, no sudo,
# LAN/internet egress gated by OpenSnitch prompts on the host desktop, and the
# host + tailscale hard-blocked on the host side (modules/nixos/rea-vm).
# Usage and security model: modules/users/purps/REA.md.
#
# Built as nixosConfigurations.rea-vm and run by navi's microvm host module.
{
  config,
  lib,
  pkgs,
  ...
}: let
  net = import ./_network.nix;
  user = "purps";
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = 8;
    # Starts small and returns unused pages to the host (free page reporting).
    mem = 8192;
    balloon = true;

    # sshd over AF_VSOCK only: the host connects without any TCP path to it.
    vsock = {
      cid = net.vsockCid;
      ssh.enable = true;
    };

    interfaces = [
      {
        type = "tap";
        id = net.tap;
        inherit (net) mac;
      }
    ];

    # Own read-only /nix/store image (storeOnDisk) instead of the host store,
    # so the guest can't read the host's closure (config, LAN addresses).
    # Home Manager's activation writes to the store (gc roots), so overlay it
    # with a throwaway writable layer on the tmpfs root.
    writableStoreOverlay = "/nix/.rw-store";
    # One persistent volume; the root filesystem is tmpfs and resets on boot.
    volumes = [
      {
        image = "persist.img";
        mountPoint = "/persist";
        size = 65536; # MiB, sparse
        label = "rea-persist";
      }
    ];

    # ~/rea on the host appears at the same path here. virtiofsd runs as root
    # on the host, so squash every guest uid/gid to purps:users and drop
    # mknod: the guest can't plant root-owned or device files on the host.
    shares = [
      {
        proto = "virtiofs";
        tag = "rea";
        source = "/persist/home/${user}/rea";
        mountPoint = "/home/${user}/rea";
        posixAcl = false;
        extraArgs = [
          "--translate-uid=squash-guest:0:1000:4294967295"
          "--translate-gid=squash-guest:0:100:4294967295"
          "--translate-uid=squash-host:0:1000:4294967295"
          "--translate-gid=squash-host:0:100:4294967295"
          "--modcaps=-mknod:-setfcap"
        ];
      }
    ];

    # Public half of the host launcher's key (generated on the host by
    # rea-vm-ssh-key.service), passed in as a systemd credential.
    credentialFiles."rea-ssh.authorized_keys" = "/persist/microvms/rea/ssh/id_ed25519.pub";
  };

  fileSystems = {
    "/persist".neededForBoot = true;
    "/home/${user}/rea".options = ["nosuid" "nodev"];
  };

  environment = {
    persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/opensnitch" # "allow always" answers
      ];
    };
    # TUI over ssh from whatever terminal the host uses (foot, kitty, ...).
    enableAllTerminfo = true;
    systemPackages = [pkgs.file];
  };

  # One unprivileged account: no sudo, no passwords.
  users = {
    mutableUsers = false;
    # Intentional: nobody has root; purps logs in over ssh with the launcher key.
    allowNoPasswordLogin = true;
    users.root.hashedPassword = "!";
    users.${user} = {
      isNormalUser = true;
      uid = 1000;
      hashedPassword = "!";
    };
  };
  security.sudo.enable = false;

  networking = {
    hostName = "rea-vm";
    useDHCP = false;
    useNetworkd = true;
    enableIPv6 = false;
    inherit (net) nameservers;
    nftables.enable = true;
    # Nothing listens for the network; TV traffic capture uses `adb reverse`
    # over the VM's own outbound adb connection.
    firewall.enable = true;
  };

  services = {
    # sshd is reached over vsock only (systemd's ssh generator); the TCP
    # listener stays on loopback.
    openssh = {
      enable = true;
      openFirewall = false;
      listenAddresses = [
        {
          addr = "127.0.0.1";
          port = 22;
        }
      ];
      hostKeys = [
        {
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [user];
        AllowAgentForwarding = false;
        AllowTcpForwarding = false;
        X11Forwarding = false;
      };
    };

    resolved.enable = false;
    # The kvm clock is enough; avoids an NTP prompt every boot.
    timesyncd.enable = false;

    # Every new outbound destination prompts on the host desktop.
    opensnitch = {
      enable = true;
      settings = {
        Server.Address = "${net.hostAddress}:${toString net.opensnitchPort}";
        # Used whenever the host UI isn't connected (and on prompt timeout,
        # unless changed in the UI's preferences).
        DefaultAction = "deny";
        InterceptUnknown = true;
        ProcMonitorMethod = "ebpf";
        Firewall = "nftables";
      };
      rules = let
        allow = name: operator: {
          inherit name operator;
          enabled = true;
          precedence = true;
          action = "allow";
          duration = "always";
        };
        simple = operand: data: {
          type = "simple";
          inherit operand data;
          sensitive = false;
        };
        regexp = operand: data: {
          type = "regexp";
          inherit operand data;
          sensitive = false;
        };
        all = list: {
          type = "list";
          operand = "list";
          inherit list;
        };
      in {
        "000-localhost" = allow "000-localhost" {
          type = "network";
          operand = "dest.network";
          data = "127.0.0.0/8";
          sensitive = false;
        };
        "001-dns" = allow "001-dns" (all [
          (regexp "dest.ip" "^(${lib.concatMapStringsSep "|" lib.escapeRegex net.nameservers})$")
          (simple "dest.port" "53")
        ]);
        # Only the daemon itself may talk to the UI on the host (stops
        # unprivileged processes from forging/flooding prompts).
        "002-opensnitch-ui" = allow "002-opensnitch-ui" (all [
          (simple "dest.ip" net.hostAddress)
          (simple "dest.port" (toString net.opensnitchPort))
          (simple "process.path" "${config.services.opensnitch.package}/bin/.opensnitchd-wrapped")
        ]);
        # The model provider (Claude subscription); everything else prompts.
        "003-anthropic" = allow "003-anthropic" (
          regexp "dest.host" "^([a-z0-9-]+\\.)*(anthropic\\.com|claude\\.ai|claude\\.com)$"
        );
      };
    };
  };

  systemd = {
    # The launcher's public key arrives as a systemd credential.
    services.rea-ssh-authorized-keys = {
      description = "Install the host launcher's SSH key";
      # Early boot, ahead of the vsock sshd socket (no default deps: those
      # would order it after sockets.target and form a cycle).
      unitConfig.DefaultDependencies = false;
      wantedBy = ["sysinit.target"];
      after = ["local-fs.target"];
      before = ["sysinit.target" "sockets.target" "sshd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ImportCredential = "rea-ssh.authorized_keys";
      };
      script = ''
        install -D -m 0644 "$CREDENTIALS_DIRECTORY/rea-ssh.authorized_keys" /etc/ssh/authorized_keys.d/${user}
      '';
    };

    network.networks."10-uplink" = {
      matchConfig.MACAddress = net.mac;
      address = ["${net.guestAddress}/${toString net.prefixLength}"];
      routes = [{Gateway = net.hostAddress;}];
      networkConfig.LinkLocalAddressing = "no";
    };

    tmpfiles.settings."10-rea-vm"."/persist/etc/ssh".d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
  };

  documentation.enable = false;
  system.stateVersion = "26.05";
}
