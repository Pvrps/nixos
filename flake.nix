{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };

    impermanence.url = "github:nix-community/impermanence";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    millennium = {
      url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree = {
      url = "github:vic/import-tree";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-parts,
    nixpkgs,
    home-manager,
    sops-nix,
    disko,
    nix-flatpak,
    import-tree,
    lanzaboote,
    nix-index-database,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      flake = let
        mkHost = {
          host,
          users,
        }:
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit inputs;};
            modules = [
              ./modules/hosts/${host}
              disko.nixosModules.disko
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
              nix-flatpak.nixosModules.nix-flatpak
              lanzaboote.nixosModules.lanzaboote
              {
                home-manager = {
                  useUserPackages = true;
                  backupFileExtension = "backup";
                  extraSpecialArgs = {inherit inputs;};
                  sharedModules = [
                    (import-tree ./modules/home)
                    inputs.nix-index-database.hmModules.nix-index
                  ];
                  inherit users;
                };
              }
            ];
          };
      in {
        nixosConfigurations.desktop = mkHost {
          host = "desktop";
          users.purps = import ./modules/users/purps/desktop.nix;
        };

        nixosConfigurations.mickey = mkHost {
          host = "mickey";
          users.mike = import ./modules/users/mike;
          users.purps = import ./modules/users/purps/general.nix;
        };
      };

      perSystem = {pkgs, ...}: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            sops
            age
            ssh-to-age
            just
            alejandra
            statix
          ];
        };

        formatter = inputs.treefmt-nix.lib.mkWrapper pkgs {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            shfmt = {
              enable = true;
              indent_size = 2;
            };
            prettier = {
              enable = true;
              includes = ["*.md" "*.yaml" "*.yml" "*.json"];
            };
          };
        };
      };
    };
}
