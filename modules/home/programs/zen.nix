{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.zen;
in {
  imports = [
    inputs.zen-browser.homeModules.twilight
  ];

  options.custom.programs.zen = {
    enable = lib.mkEnableOption "Zen browser";
    profileName = lib.mkOption {
      type = lib.types.str;
      default = "Personal";
      description = "Name of the (single) Zen profile.";
    };
    mods = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # Shared household mod set (Zen Mods store UUIDs). Override per-user
      # to diverge.
      default = [
        "a6335949-4465-4b71-926c-4a52d34bc9c0"
        "f7c71d9a-bce2-420f-ae44-a64bd92975ab"
        "c6813222-6571-4ba6-8faf-58f3343324f6"
        "253a3a74-0cc4-47b7-8b82-996a64f030d5"
        "906c6915-5677-48ff-9bfc-096a02a72379"
        "cb15abdb-0514-4e09-8ce5-722cf1f4a20f"
        "803c7895-b39b-458e-84f8-a521f4d7a064"
        "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8"
        "e122b5d9-d385-4bf8-9971-e137809097d0"
        "c8d9e6e6-e702-4e15-8972-3596e57cf398"
        "bd92a9a0-1c00-4187-a66e-94c389fa5a59"
      ];
      description = "Zen mods installed into the profile.";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Extra profile prefs, merged over the shared mod defaults (same keys win).";
    };
    extensions = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      # Shared household extension set; unlisted extensions are blocked.
      # Override wholesale for a different base, or use extraExtensions to add.
      default = {
        "*".installation_mode = "blocked";
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
        "enhancerforyoutube@maximerf.addons.mozilla.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/enhancer-for-youtube/latest.xpi";
          installation_mode = "force_installed";
        };
        "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi";
          installation_mode = "force_installed";
        };
        "izer@camelcamelcamel.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/the-camelizer-price-history-ch/latest.xpi";
          installation_mode = "force_installed";
        };
        "webextension@metamask.io" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ether-metamask/latest.xpi";
          installation_mode = "force_installed";
        };
      };
      description = "Base extension policy set (shared household default).";
    };
    extraExtensions = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Per-user extensions merged on top of the base set.";
    };
    homepage = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Zen browser homepage URL";
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.zen-browser.profileNames = lib.mkIf config.stylix.enable [cfg.profileName];

    xdg.mimeApps.defaultApplications = {
      "text/html" = "zen.desktop";
      "x-scheme-handler/http" = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
      "x-scheme-handler/about" = "zen.desktop";
      "x-scheme-handler/unknown" = "zen.desktop";
    };

    programs.zen-browser = {
      enable = true;
      profiles.${cfg.profileName} = {
        id = 0;
        name = cfg.profileName;
        isDefault = true;
        inherit (cfg) mods;
        settings =
          {
            # Companion prefs for the autoexpand mod in the default mod set.
            "mod.autoexpand.expanded_width" = "250px";
            "mod.autoexpand.animation_duration" = "100ms";
            "mod.autoexpand.animation_delay" = "100ms";
            "mod.autoexpand.collapse_delay" = "100ms";
            "mod.autoexpand.hide_workspace_indicator" = true;
          }
          // cfg.settings
          // {
            # Force Zen to use the XDG desktop portal for file picker dialogs
            # so that xdg-desktop-portal-termfilepickers intercepts them.
            "widget.use-xdg-desktop-portal.file-picker" = 1;
          }
          // lib.optionalAttrs (cfg.homepage != null) {
            "zen.urlbar.replace-newtab" = false;
            "browser.startup.page" = 1;
            "browser.startup.homepage" = cfg.homepage;
            "browser.newtab.url" = cfg.homepage;
          };
      };

      policies = {
        Preferences = {
          "browser.sessionStore.resume_from_crash" = true;
        };

        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisplayBookmarksToolbar = false;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;

        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };

        FirefoxHome = {
          Search = true;
          Pocket = false;
          Snippets = false;
          TopSites = false;
          Highlights = false;
          SponsoredPocket = false;
          SponsoredTopSites = false;
        };

        SearchSuggestEnabled = true;
        DefaultSearchEngine = "Google";

        ExtensionSettings =
          cfg.extensions
          // cfg.extraExtensions
          // lib.optionalAttrs (cfg.homepage != null) {
            "newtaboverride@agenedia.com" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/new-tab-override/latest.xpi";
              installation_mode = "force_installed";
            };
          };
      };
    };
  };
}
