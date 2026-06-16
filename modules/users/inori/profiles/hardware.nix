{
  home.persistence."/persist".directories = [
    ".cache/nvidia"
    ".cache/mesa_shader_cache"
    ".cache/radv_builtin_shaders"
  ];

  custom = {
    scripts.micsave = {
      enable = true;
      presetGitPath = "/persist/etc/nixos/modules/users/inori/files/blue_yeti.json";
    };

    programs = {
      easyeffects = {
        enable = true;
        preset = "blue_yeti";
        presetSource = "/persist/etc/nixos/modules/users/inori/files/blue_yeti.json";
      };
      openrgb.enable = true;
    };
  };
}
