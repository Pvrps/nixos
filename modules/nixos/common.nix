# Common system base, injected into every host by mkHost (see flake.nix).
# Holds settings that were previously copy-pasted into each host's
# default.nix / users.nix: nh, fish, immutable users, disabled root password,
# the sops age key location, and the per-host default sops file convention.
{
  lib,
  hostName,
  ...
}: {
  networking.hostName = hostName;

  programs.nh.enable = true;
  programs.fish.enable = true;

  users.mutableUsers = false;
  users.users.root.hashedPassword = lib.mkDefault "!";

  sops = {
    age.keyFile = lib.mkDefault "/persist/system/sops/age/keys.txt";
    defaultSopsFile = lib.mkDefault ../hosts/${hostName}/_secrets.yaml;
  };
}
