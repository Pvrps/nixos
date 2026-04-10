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

  options.custom = {
    programs.zen = {
      enable = lib.mkEnableOption "Zen browser";
      profiles = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Zen browser profiles configuration";
      };
      extensionSettings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Zen browser extension settings";
      };
      homepage = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Zen browser homepage URL";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.zen-browser.profileNames = builtins.attrNames cfg.profiles;

    xdg.mimeApps.defaultApplications = {
      "text/html" = "zen.desktop";
      "x-scheme-handler/http" = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
      "x-scheme-handler/about" = "zen.desktop";
      "x-scheme-handler/unknown" = "zen.desktop";
    };

    programs.zen-browser = {
      enable = true;
      languagePacks = ["en-US"];

      profiles = lib.mapAttrs (name: profile:
        profile
        // {
          settings =
            (profile.settings or {})
            // lib.optionalAttrs (cfg.homepage != null) {
              "zen.urlbar.replace-newtab" = false;
              "browser.startup.page" = 1;
              "browser.startup.homepage" = cfg.homepage;
              "browser.newtab.url" = cfg.homepage;
            };
        })
      cfg.profiles;

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
          cfg.extensionSettings
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
