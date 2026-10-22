{
  lib,
  config,
  pkgs,
  osConfig,
  ...
}: let
  cfg = config.custom.programs.obs;

  hasNvidia = osConfig.hardware.nvidia.modesetting.enable or false;

  # WORKAROUND: CUDA onnxruntime + Flatpak LD_* hack for obs-backgroundremoval,
  # see WORKAROUNDS.md
  onnxruntime-cuda = pkgs.onnxruntime.override {
    cudaSupport = true;
    inherit (pkgs) cudaPackages;
  };

  obs-backgroundremoval =
    if hasNvidia
    then
      pkgs.obs-studio-plugins.obs-backgroundremoval.override {
        onnxruntime = onnxruntime-cuda;
      }
    else pkgs.obs-studio-plugins.obs-backgroundremoval;

  # Libs for the LD_LIBRARY_PATH / LD_PRELOAD hack above.
  onnxruntimeCudaLibs = with pkgs.cudaPackages; [
    onnxruntime-cuda
    cuda_cudart
    libcublas
    libcurand
    libcufft
    cudnn
    nccl
    cuda_nvrtc.lib
  ];

  cudaLibPath = lib.optionalString hasNvidia (lib.makeLibraryPath onnxruntimeCudaLibs);

  cudaPreload = lib.optionalString hasNvidia (
    lib.concatStringsSep ":" [
      # cuda_nvrtc's .so lives in the "lib" output, not the default dev output
      "${pkgs.cudaPackages.cuda_nvrtc.lib}/lib/libnvrtc.so.12"
      "${onnxruntime-cuda}/lib/libonnxruntime_providers_shared.so"
    ]
  );

  # For plugins distributed as nixpkgs obs-studio-plugins.
  # nixpkgs layout: lib/obs-plugins/<soName>.so, share/obs/obs-plugins/<dataName>/
  # flatpak layout: plugins/<dirName>/bin/64bit/<soName>.so, plugins/<dirName>/data/
  mkPluginNixpkgs = {
    # Directory name OBS scans (must match the .so basename for OBS to load it)
    dirName,
    # Basename of the .so inside lib/obs-plugins/ (and share/obs/obs-plugins/)
    soName ? dirName,
    pkg,
  }: let
    base = ".var/app/com.obsproject.Studio/config/obs-studio/plugins/${dirName}";
  in {
    "${base}/bin/64bit/${soName}.so".source = "${pkg}/lib/obs-plugins/${soName}.so";
    "${base}/data".source = "${pkg}/share/obs/obs-plugins/${soName}";
  };

  pipewireAudioCaptureFiles =
    lib.optionalAttrs cfg.plugins.pipewireAudioCapture.enable
    (mkPluginNixpkgs {
      dirName = "linux-pipewire-audio";
      pkg = pkgs.obs-studio-plugins.obs-pipewire-audio-capture;
    });

  backgroundRemovalFiles =
    lib.optionalAttrs cfg.plugins.backgroundRemoval.enable
    (mkPluginNixpkgs {
      dirName = "obs-backgroundremoval";
      pkg = obs-backgroundremoval;
    });
in {
  options.custom.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio via Flatpak with plugin management";
    plugins = {
      pipewireAudioCapture = {
        enable = lib.mkEnableOption "PipeWire Audio Capture plugin";
      };
      backgroundRemoval = {
        enable = lib.mkEnableOption "Background Removal plugin";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.flatpak.enable;
        message = "custom.programs.obs requires custom.programs.flatpak.enable = true.";
      }
    ];

    custom.programs.flatpak.packages = lib.mkAfter ["com.obsproject.Studio"];

    # Expose CUDA runtime libs to the Flatpak sandbox so onnxruntime can
    # dlopen() libonnxruntime_providers_cuda.so at runtime.
    # LD_PRELOAD ensures libnvrtc and providers_shared are in the global symbol
    # table before onnxruntime attempts to load the CUDA provider.
    home.activation.obsCudaLibs =
      lib.mkIf (hasNvidia && cfg.plugins.backgroundRemoval.enable)
      (lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${pkgs.flatpak}/bin/flatpak override --user \
          --env=LD_LIBRARY_PATH=${cudaLibPath} \
          --env=LD_PRELOAD=${cudaPreload} \
          com.obsproject.Studio
      '');

    home.file = lib.mkMerge [
      pipewireAudioCaptureFiles
      backgroundRemovalFiles
    ];
  };
}
