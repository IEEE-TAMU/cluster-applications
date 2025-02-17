{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:gigamonster256/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    nixpkgs,
    systems,
    flake-parts,
    git-hooks,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        git-hooks.flakeModule
      ];
      systems = import systems;
      perSystem = {
        config,
        pkgs,
        ...
      }: {
        formatter = pkgs.alejandra;

        pre-commit.settings.hooks = {
          alejandra.enable = true;
          yamlfmt.enable = true;
          yamlfmt.settings.lint-only = false;
          typos.enable = true;
          typos.args = ["--force-exclude"];
        };

        # install the shellHook and packages from git-hooks
        # as well as helpful tools for managing the cluster
        devShells.default = pkgs.mkShellNoCC {
          buildInputs = builtins.attrValues {
            inherit
              (pkgs)
              sops
              openssh
              ssh-to-age
              gnupg
              kubectl
              kubernetes-helm
              ;
          };

          env.KUBECONFIG = "./k3s.yaml";

          shellHook = ''
            if [ ! -f ./k3s.yaml ]; then
              sops -d k3s.enc.yaml > k3s.yaml
              chmod 0600 k3s.yaml
            fi
          '';

          inputsFrom = [
            config.pre-commit.devShell
          ];
        };
      };
    };
}
