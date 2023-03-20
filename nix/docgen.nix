{pkgs, ...}:
pkgs.writeShellApplication {
  name = "docgen";
  runtimeInputs = with pkgs; [
    lemmy-help
  ];
  text = ''
    mkdir -p doc
    lemmy-help lua/neotest-haskell/init.lua > doc/neotest-haskell.txt
  '';
}
