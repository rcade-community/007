{
  description = "007 dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }: {
    fixed-labs.rift.x86_64-linux =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux; in {
        packages = with pkgs; [ godot_4 ripgrep jq ];
      };
  };
}
