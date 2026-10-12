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
        # Use the newest available driver branch (production or new_feature).
        branch = "latest";
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

      # Work around an NVIDIA driver bug where VRAM freed by a GL-based
      # Wayland compositor isn't released back to the pool (should stay
      # ~100MiB; without this it climbs toward ~1GiB over a session). Left
      # unmitigated this leads to GPU clients (e.g. Zen's WebRender) failing
      # to allocate new EGL surfaces mid-session, producing visible rendering
      # corruption until restart. Applied to niri and mango (scenefx/GLES).
      # https://github.com/NVIDIA/egl-wayland/issues/126#issuecomment-2379945259
      etc = lib.mkIf (config.programs.niri.enable || config.programs.mango.enable) {
        "nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text = builtins.toJSON {
          rules =
            map (proc: {
              pattern = {
                feature = "procname";
                matches = proc;
              };
              profile = "Limit Free Buffer Pool On Wayland Compositors";
            })
            (lib.optional config.programs.niri.enable "niri"
              ++ lib.optional config.programs.mango.enable "mango");
          profiles = [
            {
              name = "Limit Free Buffer Pool On Wayland Compositors";
              settings = [
                {
                  key = "GLVidHeapReuseRatio";
                  value = 0;
                }
              ];
            }
          ];
        };
      };
    };
  };
}
