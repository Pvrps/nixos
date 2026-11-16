# Host side of the rea-vm reverse-engineering microVM (guest config:
# modules/hosts/rea-vm, usage: modules/users/purps/REA.md).
#
# Provides: the microvm host with rea-vm declared (started on demand, not at
# boot), its tap network + NAT, hard firewall isolation (from this host, the
# rest of the LAN except the home subnet, tailscale), the OpenSnitch prompt UI,
# the ~/rea share, the live report and the
# `rea` launcher.
{
  config,
  lib,
  pkgs,
  inputs,
  self,
  ...
}: let
  cfg = config.custom.reaVm;
  net = import ../../hosts/rea-vm/_network.nix;
  name = "rea";
  unit = "microvm@${name}.service";
  stateDir = "/persist/microvms";
  vmDir = "${stateDir}/${name}";
  keyDir = "${vmDir}/ssh";
  home = config.users.users.${cfg.user}.home;
  shareSource = "/persist${home}/rea";
  port = toString net.opensnitchPort;
  reportPort = 8471;
  ext = cfg.externalInterface;

  caseTool = pkgs.callPackage ../../home/programs/development/rea/_case.nix {};

  # Live, read-only report of ~/rea; content is untrusted, see the script.
  report = pkgs.writers.writePython3Bin "rea-report" {
    libraries = [pkgs.python3Packages.markdown-it-py];
    flakeIgnore = ["E501" "W503" "E731"];
  } (builtins.readFile ./report/rea_report.py);

  launcher = pkgs.writeShellApplication {
    name = "rea";
    runtimeInputs = with pkgs; [openssh coreutils gnused jq systemd util-linux xdg-utils caseTool];
    runtimeEnv = {
      REA_REPORT_URL = "http://localhost:${toString reportPort}/";
      REA_UNIT = unit;
      REA_RESET_UNIT = "rea-vm-reset.service";
      REA_SSH_KEY = "${keyDir}/id_ed25519";
      REA_SSH_PROXY = "${config.systemd.package}/lib/systemd/systemd-ssh-proxy";
      REA_VSOCK_CID = toString net.vsockCid;
      REA_SHARE = "${home}/rea";
      REA_SHARE_SOURCE = shareSource;
      # Same filesystem as the share source (atomic rename), outside the share.
      REA_STAGING = "/persist${home}/.rea-staging";
      REA_STATE_DIR = vmDir;
    };
    text = builtins.readFile ./launcher.sh;
  };

  privateRanges = ["10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" "100.64.0.0/10" "169.254.0.0/16" "224.0.0.0/4" "240.0.0.0/4"];

  # iptables rules for the VM. raw/PREROUTING and mangle/FORWARD run before
  # the filter table, where tailscale (ts-forward) and NixOS add their own
  # ACCEPTs, so nothing later can reopen what is dropped here. The script is
  # idempotent and nothing is removed on firewall stop: a failed reload
  # keeps the VM isolated (fail closed).
  firewallStart = ''
    # --- rea-vm: traffic from the VM to this host ---------------------------
    iptables -w -t raw -N rea-vm-pre 2>/dev/null || true
    iptables -w -t raw -F rea-vm-pre
    iptables -w -t raw -D PREROUTING -i ${net.tap} -j rea-vm-pre 2>/dev/null || true
    iptables -w -t raw -I PREROUTING -i ${net.tap} -j rea-vm-pre
    iptables -w -t raw -A rea-vm-pre ! -s ${net.guestAddress} -j DROP
    # Only the OpenSnitch UI, only on the tap address
    iptables -w -t raw -A rea-vm-pre -d ${net.hostAddress} -p tcp --dport ${port} -j RETURN
    iptables -w -t raw -A rea-vm-pre -m addrtype --dst-type LOCAL -j DROP
    iptables -w -t raw -A rea-vm-pre -m addrtype --dst-type BROADCAST -j DROP

    # --- rea-vm: forwarded traffic -----------------------------------------
    iptables -w -t mangle -N rea-vm-fwd 2>/dev/null || true
    iptables -w -t mangle -F rea-vm-fwd
    iptables -w -t mangle -D FORWARD -j rea-vm-fwd 2>/dev/null || true
    iptables -w -t mangle -I FORWARD -j rea-vm-fwd
    # Out: only via the LAN uplink (no tailscale routes, no other links)
    iptables -w -t mangle -A rea-vm-fwd -i ${net.tap} ! -o ${ext} -j DROP
    ${lib.concatMapStrings (ip: ''
        iptables -w -t mangle -A rea-vm-fwd -i ${net.tap} -d ${ip} -j DROP
      '')
      cfg.lanBlocked}
    ${lib.concatMapStrings (r: ''
        iptables -w -t mangle -A rea-vm-fwd -i ${net.tap} -d ${r} -j RETURN
      '')
      cfg.lanAllowed}
    ${lib.concatMapStrings (r: ''
        iptables -w -t mangle -A rea-vm-fwd -i ${net.tap} -d ${r} -j DROP
      '')
      privateRanges}
    # In: only replies, only from the uplink
    iptables -w -t mangle -A rea-vm-fwd -o ${net.tap} ! -i ${ext} -j DROP
    iptables -w -t mangle -A rea-vm-fwd -o ${net.tap} -m conntrack ! --ctstate ESTABLISHED,RELATED -j DROP

    # --- No IPv6 for the VM at all -------------------------------------------
    ip6tables -w -t raw -D PREROUTING -i ${net.tap} -j DROP 2>/dev/null || true
    ip6tables -w -t raw -I PREROUTING -i ${net.tap} -j DROP
    ip6tables -w -t mangle -D FORWARD -o ${net.tap} -j DROP 2>/dev/null || true
    ip6tables -w -t mangle -I FORWARD -o ${net.tap} -j DROP

    # --- Second layer on INPUT (nixos-fw is rebuilt on every start) -----------
    iptables -w -I nixos-fw 1 -i ${net.tap} -j nixos-fw-log-refuse
    iptables -w -I nixos-fw 1 -i ${net.tap} -d ${net.hostAddress} -p tcp --dport ${port} -j nixos-fw-accept
    iptables -w -I nixos-fw 1 -i ${net.tap} -m conntrack --ctstate ESTABLISHED,RELATED -j nixos-fw-accept
  '';
in {
  imports = [inputs.microvm.nixosModules.host];

  options.custom.reaVm = {
    enable = lib.mkEnableOption "the rea-vm reverse-engineering microVM and its `rea` launcher";
    user = lib.mkOption {
      type = lib.types.str;
      default = "purps";
      description = "Desktop user allowed to start/stop the VM and get its network prompts";
    };
    externalInterface = lib.mkOption {
      type = lib.types.str;
      example = "eno1";
      description = "LAN uplink; the VM's only way out (NAT)";
    };
    lanAllowed = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["10.0.20.0/24"];
      description = ''
        LAN subnets/addresses the VM may reach (e.g. the IoT network with the
        TV, for adb), still behind per-connection OpenSnitch prompts. Every
        other private range, this host and tailscale stay blocked. Empty =
        no LAN access at all.
      '';
    };
    lanBlocked = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["10.0.20.1"];
      description = "Addresses inside lanAllowed the VM may never reach (e.g. the router's interface on that subnet)";
    };
  };

  config = lib.mkMerge [
    # The host module is imported on every host (import-tree); only rea-vm
    # hosts actually run it.
    {microvm.host.enable = lib.mkDefault cfg.enable;}

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !config.networking.nftables.enable;
          message = "custom.reaVm: firewall rules are written for the iptables backend";
        }
      ];

      microvm = {
        inherit stateDir;
        vms.${name} = {
          evaluatedConfig = self.nixosConfigurations.rea-vm;
          # Started by the launcher; a rebuild doesn't kill a running session.
          autostart = false;
          restartIfChanged = false;
        };
      };

      systemd = {
        services = {
          # The launcher's key; the public half reaches the guest as a
          # credential. Runs (idempotently) on every VM start - no
          # RemainAfterExit - so a rebuild's changes always apply; soft
          # dependency + no restart on rebuild, so a switch never restarts a
          # running VM through it.
          rea-vm-ssh-key = {
            description = "Generate the rea launcher SSH key";
            before = [unit];
            wantedBy = [unit];
            restartIfChanged = false;
            path = [pkgs.openssh];
            serviceConfig.Type = "oneshot";
            script = ''
              # Earlier location (directly in the microvm state dir)
              if [ -d ${stateDir}/rea-ssh ] && [ ! -e ${keyDir} ]; then
                mv ${stateDir}/rea-ssh ${keyDir}
              fi
              install -d -m 0755 ${keyDir}
              if [ ! -f ${keyDir}/id_ed25519 ]; then
                ssh-keygen -q -t ed25519 -N "" -C rea-launcher -f ${keyDir}/id_ed25519
              fi
              chown ${cfg.user}: ${keyDir}/id_ed25519
              chmod 0600 ${keyDir}/id_ed25519
              chmod 0644 ${keyDir}/id_ed25519.pub
            '';
          };

          # `rea reset`: wipe the VM's disk (logins, sessions, answers).
          rea-vm-reset = {
            description = "Wipe rea-vm's persistent disk";
            conflicts = [unit];
            after = [unit];
            serviceConfig.Type = "oneshot";
            script = ''
              rm -f ${vmDir}/persist.img
            '';
          };

          # Host end of the tap (created by microvm-tap-interfaces@rea).
          # (~/rea itself is a plain persisted folder: home.persistence in
          # modules/users/purps/navi.nix, ownership via tmpfiles below.)
          "microvm-tap-interfaces@${name}".serviceConfig.ExecStartPost = [
            "${pkgs.iproute2}/bin/ip addr replace ${net.hostAddress}/${toString net.prefixLength} dev ${net.tap}"
            "${pkgs.iproute2}/bin/ip link set ${net.tap} up"
          ];
        };

        # The share: owned by the user. Sorts before microvm's 10-microvm
        # rule, which would otherwise create it as microvm:kvm.
        tmpfiles.settings."05-rea-vm" = {
          ${shareSource}.d = {
            inherit (cfg) user;
            group = "users";
            mode = "0700";
          };
        };

        # Live report at http://localhost:8471. Started by `rea`.
        user.services.rea-report = {
          description = "Live REA case report";
          unitConfig.ConditionUser = cfg.user;
          serviceConfig = {
            ExecStart = "${report}/bin/rea-report --root ${shareSource} --static ${./report/static} --port ${toString reportPort}";
            Restart = "on-failure";
            RestartSec = 2;
            NoNewPrivileges = true;
            LockPersonality = true;
            RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
            SystemCallArchitectures = "native";
          };
        };

        # OpenSnitch prompts for the guest's connections. Started by `rea`.
        user.services.rea-opensnitch-ui = {
          description = "OpenSnitch prompts for rea-vm network connections";
          partOf = ["graphical-session.target"];
          after = ["graphical-session.target"];
          unitConfig.ConditionUser = cfg.user;
          serviceConfig = {
            ExecStart = "${pkgs.opensnitch-ui}/bin/opensnitch-ui --socket ${net.hostAddress}:${port}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };

      networking = {
        networkmanager.unmanaged = ["interface-name:${net.tap}"];

        nat = {
          enable = true;
          internalInterfaces = [net.tap];
          externalInterface = ext;
        };

        firewall.extraCommands = firewallStart;
      };

      # Let the user start/stop/reset the VM without sudo.
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.user == "${cfg.user}") {
            var unit = action.lookup("unit");
            var verb = action.lookup("verb");
            if (unit == "${unit}" &&
                (verb == "start" || verb == "stop" || verb == "restart")) {
              return polkit.Result.YES;
            }
            if (unit == "rea-vm-reset.service" && verb == "start") {
              return polkit.Result.YES;
            }
          }
        });
      '';

      environment.systemPackages = [launcher];
    })
  ];
}
