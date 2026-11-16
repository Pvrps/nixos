# `rea-case`: case-folder tool shared by the host launcher (modules/nixos/rea-vm)
# and the agent inside rea-vm. Underscore prefix: skipped by import-tree.
{
  writeShellApplication,
  coreutils,
  findutils,
  gnused,
  file,
  jq,
}:
writeShellApplication {
  name = "rea-case";
  runtimeInputs = [coreutils findutils gnused file jq];
  text = builtins.readFile ./case.sh;
}
