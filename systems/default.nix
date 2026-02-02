{
  inputs,
  self,
  ...
}:
{
  imports = [ inputs.easy-hosts.flakeModule ];

  easy-hosts = {
    perClass = class: {
      modules = [
        "${self}/modules/${class}/default.nix"
        "${self}/modules/shared/default.nix"
        "${self}/modules/shared/home.nix"
      ];
    };

    hosts = {
      desktop = {
        arch = "x86_64";
        class = "nixos";
      };
    };
  };
}
