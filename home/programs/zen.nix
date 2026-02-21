{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.twilight
  ];

  stylix.targets.zen-browser.profileNames = ["Personal"];

  xdg.mimeApps.defaultApplications = {
    "text/html" = "zen.desktop";
    "x-scheme-handler/http" = "zen.desktop";
    "x-scheme-handler/https" = "zen.desktop";
    "x-scheme-handler/about" = "zen.desktop";
    "x-scheme-handler/unknown" = "zen.desktop";
  };

  programs.zen-browser = {
    enable = true;
    suppressXdgMigrationWarning = true;
    languagePacks = ["en-US"];

    profiles.Personal = {
      id = 0;
      name = "Personal";
      isDefault = true;

      mods = [
        "a6335949-4465-4b71-926c-4a52d34bc9c0" # Better Find Bar
        "f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better Unloaded Tabs
        "c6813222-6571-4ba6-8faf-58f3343324f6" # Disable Rounded Corners
        "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
        "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
        "cb15abdb-0514-4e09-8ce5-722cf1f4a20f" # Hide Extension Name
        "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
        "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
        "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
        "c8d9e6e6-e702-4e15-8972-3596e57cf398" # Zen Back Forward
      ];
    };

    policies = {
      Preferences = {
        "browser.startup.page" = 3;
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

      ExtensionSettings = {
        "*" = {
          installation_mode = "blocked";
        };
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
        "moz-addon-prod@7tv.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/7tv-extension/latest.xpi";
          installation_mode = "force_installed";
        };
        "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
}
