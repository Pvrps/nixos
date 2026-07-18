# Common system base for every host: nh, fish, immutable users, disabled
# root password, sops age key location, and the per-host sops file convention.
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
