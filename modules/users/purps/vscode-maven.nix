{
  pkgs,
}:
# The Maven archetype wizard uses vscode.workspace.fs.copy to copy
# resources/projectTemplate/ from the extension dir into the new project.
# That call preserves file mode, and the Nix store ships the template as
# read-only (dirs 0555, files 0444 — Nix canonicalises all store paths by
# stripping write bits). The wizard then writes pom.xml in place, which
# fails with EACCES on the 0444 file (and earlier on the 0555 dir).
#
# chmod-in-the-derivation can't fix this (Nix re-strips on store import), so
# patch the bundled extension.js to use a recursive copy that creates dirs
# with mode 0755 and files with mode 0644 instead of preserving the
# read-only source mode.
pkgs.vscode-extensions.vscjava.vscode-maven.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    substituteInPlace $out/share/vscode/extensions/vscjava.vscode-maven/dist/extension.js \
      --replace 'yield a.workspace.fs.copy(d,h,{overwrite:!0})' 'yield new Promise((r,j)=>{try{const fs=require("fs"),path=require("path");(function cp(s,t){fs.mkdirSync(t,{recursive:true});fs.chmodSync(t,493);for(const e of fs.readdirSync(s,{withFileTypes:true})){const sp=path.join(s,e.name),tp=path.join(t,e.name);if(e.isDirectory()){cp(sp,tp)}else{fs.copyFileSync(sp,tp);fs.chmodSync(tp,420)}}})(d.fsPath,h.fsPath);r()}catch(e){j(e)}})'
  '';
})
