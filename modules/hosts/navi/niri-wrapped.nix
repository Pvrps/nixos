# niri with a patched niri-session script.
#
# Upstream niri-session runs a bare `systemctl --user import-environment`,
# which systemd deprecated years ago and warns about on the TTY at every
# login ("calling import environment without a list of variable names is
# deprecated"). Import an explicit list instead; the login-shell environment
# is already visible to the user manager anyway via environment.d
# (home.sessionVariables) and pam_env (environment.sessionVariables).
# Drop this once upstream fixes it: https://github.com/niri-wm/niri/issues/254
{
  niri,
  symlinkJoin,
}:
symlinkJoin {
  pname = "${niri.pname}-wrapped";
  inherit (niri) version;

  # passthru.providedSessions must be preserved so the wrapped package stays
  # compatible with services.displayManager.sessionPackages.
  passthru =
    niri.passthru
    // {
      unwrapped = niri;
    };

  # Include every output (out + doc) so nothing is lost versus the unwrapped
  # package being in environment.systemPackages.
  paths = map (o: niri.${o}) niri.outputs;

  postBuild = ''
    rm $out/bin/niri-session
    cp -p ${niri}/bin/niri-session $out/bin/niri-session
    patch -p2 $out/bin/niri-session < ${./niri-session-no-import-env.patch}
  '';
}
