{ pkgs, ... }:

{
  systemd.user.services.copilot-api = {
    Unit = {
      Description = "Copilot API (Local OpenAI Proxy)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Environment = [
        "PORT=8080"
        "HOST=127.0.0.1"
        "npm_config_yes=true"
        "npm_config_cache=%h/.npm"
      ];
      
      ExecStart = ''
        ${pkgs.nix}/bin/nix-shell -I nixpkgs=${pkgs.path} -p nodejs --run "npx -y copilot-api@latest start";
      '';
      
      Restart = "always";
      RestartSec = "10";
      
      NoNewPrivileges = true;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
