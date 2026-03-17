{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.fish;
in {
  options.custom.programs.fish.enable = lib.mkEnableOption "Fish shell";

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      shellAliases = config.custom.fish.aliases;
      interactiveShellInit = ''
        set fish_greeting
      '';

      functions = {
        run = ''
          if string match -q "*.AppImage" $argv[1]
            NIXPKGS_ALLOW_UNFREE=1 nix-shell -p appimage-run --run "appimage-run $argv"
          else if string match -q "*.deb" $argv[1]
            set deb_file $argv[1]
            set run_args $argv[2..]
            set tmp_dir (mktemp -d)
            nix-shell -p dpkg --run "dpkg -x \"$deb_file\" \"$tmp_dir\""
            set exe_path (find $tmp_dir/opt $tmp_dir/usr/bin $tmp_dir/usr/share -type f -executable 2>/dev/null | head -n 1)
            if test -n "$exe_path"
              NIXPKGS_ALLOW_UNFREE=1 nix-shell -p steam-run --run "steam-run \"$exe_path\" $run_args"
            else
              echo "Could not find an executable in $deb_file"
            end
            rm -rf $tmp_dir
          else if string match -r -q '\.(tar\.gz|tgz)$' $argv[1]
            set archive_file $argv[1]
            set run_args $argv[2..]
            set tmp_dir (mktemp -d)
            tar -xzf "$archive_file" -C "$tmp_dir"
            # Find the largest executable file to avoid accidentally picking up minor scripts/libraries
            set exe_path (find $tmp_dir -type f -executable -not -name "*.so*" -print0 2>/dev/null | xargs -0 -r ls -S | head -n 1)
            if test -n "$exe_path"
              NIXPKGS_ALLOW_UNFREE=1 nix-shell -p steam-run --run "steam-run \"$exe_path\" $run_args"
            else
              echo "Could not find an executable in $archive_file"
            end
            rm -rf $tmp_dir
          else
            NIXPKGS_ALLOW_UNFREE=1 nix-shell -p steam-run --run "steam-run $argv"
          end
        '';
      };
    };
  };
}
