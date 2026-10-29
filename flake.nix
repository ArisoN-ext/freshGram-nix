{
  nixConfig = {
    extra-substituters = [ "https://freshgram-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "freshgram-nix.cachix.org-1:ecq4K1oaPvsfhbdVsaU8lp6jpCzGID3obEWF2wpfqZE="
    ];
  };

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.kdePackages.callPackage ./default.nix {
            tg_owt = pkgs.telegram-desktop.unwrapped.tg_owt;
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          package = self.packages.${system}.default;
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ package.unwrapped ];
            packages = with pkgs; [
              ccache
              git
            ];
            shellHook = ''
              export CMAKE_GENERATOR=Ninja
            '';
          };
        }
      );
    };
}
