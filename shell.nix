{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs_24
  ];

  shellHook = ''
    # prompt
    export PS1='$(__git_ps1 "\e[1;32m(%s)\e[0m")\e[1;35m \W\e[0m\e[1;37m   \e[0m'
  '';
}
