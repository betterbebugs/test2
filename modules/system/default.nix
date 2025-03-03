{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
in {
  imports = [
    ./security.nix
    ./nix.nix
    ./roles.nix
  ];

  options.opt.system = {
    username = mkOption {
      type = types.str;
      default = "scoop";
    };
  };

  config = {
    users.users.${config.opt.system.username} = {
      isNormalUser = true;
      extraGroups = ["wheel"];
    };

    # Until this isn't fixed with flakes https://github.com/NixOS/nixpkgs/issues/171054
    programs.command-not-found.enable = false;

    i18n.defaultLocale = "en_US.UTF-8";
    system.stateVersion = "23.11";
  };
}