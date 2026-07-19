{ lib, ... }: let
	inherit (lib) mkOption types;
in {
	options.router = {
		wan-interface = mkOption {
			type = types.str;
			description = "Network interface connected to the WAN.";
		};

		lan-interface = mkOption {
			type = types.str;
			description = "Network interface carrying LAN VLANs.";
		};

		vlans = mkOption {
			type = types.listOf (types.submodule {
				options = {
					id = mkOption {
						type = types.ints.between 1 4094;
						description = "802.1Q VLAN identifier.";
					};

					name = mkOption {
						type = types.strMatching "[A-Za-z0-9_.-]+";
						description = "Interface name for the VLAN.";
					};

					subnet = mkOption {
						type = types.strMatching "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+";
						description = "IPv4 CIDR subnet assigned to the VLAN.";
					};

					trusted = mkOption {
						type = types.bool;
						default = false;
						description = "Whether hosts on this VLAN may initiate connections to other VLANs.";
					};

					internet = mkOption {
						type = types.bool;
						default = true;
						description = "Whether hosts on this VLAN are allowed outbound internet access.";
					};
				};
			});
			default = [ ];
			description = "LAN VLANs routed by this host.";
		};
	};
}
