# NVIDIA GPU: proprietary-open driver, VAAPI, and Proton/GLX env.
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.custom.nvidia.enable = lib.mkEnableOption "NVIDIA GPU drivers and VAAPI env";

  config = lib.mkIf config.custom.nvidia.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      nvidia = {
        modesetting.enable = true;
        open = true;
      };
    };

    services.xserver.videoDrivers = ["nvidia"];

    environment = {
      systemPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-utils
      ];
      sessionVariables = {
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        LIBVA_DRIVER_NAME = "nvidia";
        NVD_BACKEND = "direct";
        PROTON_ENABLE_NVAPI = "1";
      };
    };
  };
}
