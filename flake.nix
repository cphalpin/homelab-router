{
	description = "Home router";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
	};

	outputs = { nixpkgs, ... }: let
		system = "x86_64-linux";
	in {
		nixosConfigurations.sentinel = nixpkgs.lib.nixosSystem {
			inherit system;

			modules = [
				./sentinel.nix
			];
		};
	};
}
