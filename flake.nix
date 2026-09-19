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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    # v5 rewrite: native C++/Wayland shell (no Qt/Quickshell), config in TOML,
    # plugins in Luau. Not following nixpkgs here is required to hit the
    # noctalia.cachix.org binary cache (see modules/nixos/core.nix); tracking
    # the `cachix` branch instead of `main` guarantees the pinned commit has
    # already been built by upstream CI, per docs.noctalia.dev/noctalia/getting-started/nixos.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    stylix = {
      url = "github:nix-community/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.7.0";

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree = {
      url = "github:vic/import-tree";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xdp-termfilepickers = {
      url = "github:Guekka/xdg-desktop-portal-termfilepickers";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    sls-steam = {
      url = "github:AceSLS/SLSsteam";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned to the last version before a regression broke X11 popup
    # pointer-grabs (Steam context menus closing instantly under niri).
    # Remove once fixed upstream: https://github.com/Supreeeme/xwayland-satellite/issues/468
    nixpkgs-xwayland-satellite-fix.url = "github:nixos/nixpkgs/a5cbcfe954791221bfffe2307f7d1a1bf61a871e";
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
    quadlet-nix,
    sls-steam,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      flake = let
        # Extend nixpkgs lib with our helper library (lib.custom.*), available
        # in every NixOS and home-manager module via the `lib` argument.
        # Pure: helpers that need `pkgs` take it from the module's own args.
        lib = nixpkgs.lib.extend (final: prev: {
          custom = import ./modules/lib {lib = final;};
        });

        mkHost = {
          host,
          users,
        }:
        # The target platform comes from nixpkgs.hostPlatform in each host's
        # _hardware.nix rather than the legacy `system` argument.
          nixpkgs.lib.nixosSystem {
            inherit lib;
            specialArgs = {
              inherit inputs self;
              hostName = host;
            };
            modules = [
              # All shared system modules are auto-imported and option-gated
              # (custom.*); hosts only declare what they enable.
              (import-tree ./modules/nixos)
              ./modules/hosts/${host}
              disko.nixosModules.disko
              sops-nix.nixosModules.sops
              home-manager.nixosModules.home-manager
              nix-flatpak.nixosModules.nix-flatpak
              lanzaboote.nixosModules.lanzaboote
              quadlet-nix.nixosModules.quadlet
              {
                home-manager = {
                  # Reuse the system nixpkgs instance instead of evaluating a
                  # private one per user (inherits allowUnfree from core.nix).
                  # Home-manager modules must not set nixpkgs.* as a result;
                  # see modules/home/stylix.nix for the stylix trade-off.
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "backup";
                  extraSpecialArgs = {inherit inputs self;};
                  sharedModules = [
                    (import-tree ./modules/home)
                    inputs.nix-index-database.homeModules.nix-index
                    inputs.sls-steam.homeModules.sls-steam
                  ];
                  inherit users;
                };
              }
            ];
          };
      in {
        nixosConfigurations.navi = mkHost {
          host = "navi";
          users.purps = import ./modules/users/purps/navi.nix;
        };

        nixosConfigurations.mickey = mkHost {
          host = "mickey";
          users.mike = import ./modules/users/mike;
          users.purps = import ./modules/users/purps/general.nix;
        };

        nixosConfigurations.windwaker = mkHost {
          host = "windwaker";
          users.purps = import ./modules/users/purps/general.nix;
        };

        nixosConfigurations.ciela = mkHost {
          host = "ciela";
          users.inori = import ./modules/users/inori/ciela.nix;
          users.purps = import ./modules/users/purps/general.nix;
        };
      };

      perSystem = {pkgs, ...}: {
        formatter = inputs.treefmt-nix.lib.mkWrapper pkgs {
          projectRootFile = "flake.nix";
          # sops-encrypted secrets are managed by sops, not the formatter.
          settings.global.excludes = ["*_secrets.yaml"];
          programs = {
            alejandra.enable = true;
            statix.enable = true;
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
