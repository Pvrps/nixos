{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.firefox;
in {
  options.custom = {
    programs.firefox = {
      enable = lib.mkEnableOption "Firefox browser";
      profiles = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Firefox browser profiles configuration";
      };
      extensionSettings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Firefox browser extension settings";
      };
      homepage = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Firefox browser homepage URL";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.firefox.profileNames = builtins.attrNames cfg.profiles;

    xdg.mimeApps.defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };

    programs.firefox = {
      enable = true;
      languagePacks = ["en-US"];

      profiles = lib.mapAttrs (name: profile:
        profile
        // {
          settings =
            (profile.settings or {})
            // lib.optionalAttrs (cfg.homepage != null) {
              "browser.startup.page" = 1;
              "browser.startup.homepage" = cfg.homepage;
              "browser.newtab.url" = cfg.homepage;
            };
        })
      cfg.profiles;

      policies = {
        Preferences = {
          "browser.sessionstore.resume_from_crash" = false;
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
