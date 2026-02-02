{ pkgs, inputs, ... }:
{
  imports = [
    inputs.zen-browser.homeModules.twilight
  ];

  programs.zen-browser = {
    enable = true;

    policies = {
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

      Preferences = {
        "browser.search.suggest.enabled" = true;
        "browser.urlbar.suggest.searches" = true;
        "browser.urlbar.showSearchSuggestionsFirst" = true;

        "ui.systemUsesDarkTheme" = 1;
        "zen.theme.dark" = true;
        "layout.css.prefers-color-scheme.content-override" = 0;

        "zen.view.compact-mode" = true;
        "zen.view.compact.hide-toolbar" = false;
        "zen.view.compact.hide-sidebar" = false;
      };

      ExtensionSettings = {
        "*" = {
          installation_mode = "blocked";
        };
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          pinned = true;
        };
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
          pinned = false;
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
          pinned = true;
        };
        "enhancerforyoutube@maximerf.addons.mozilla.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/enhancer-for-youtube/latest.xpi";
          installation_mode = "force_installed";
          pinned = false;
        };
      };
    };   
  };
}
