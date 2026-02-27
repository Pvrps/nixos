{
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.twilight
  ];

  stylix.targets.zen-browser.profileNames = builtins.attrNames config.custom.zen.profiles;

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

    inherit (config.custom.zen) profiles;

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

      ExtensionSettings = config.custom.zen.extensionSettings;
    };
  };
}
