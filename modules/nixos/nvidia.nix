{pkgs, ...}: {
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      open = false;
    };
  };

  services.xserver.videoDrivers = ["nvidia"];

  environment = {
    systemPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-utils
    ];
    sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia";
      PROTON_ENABLE_NVAPI = "1";
    };
  };
}
