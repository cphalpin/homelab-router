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
			type = types.attrsOf (types.submodule {
				options = {
					id = mkOption {
						type = types.ints.between 1 4094;
						description = "802.1Q VLAN identifier.";
					};

					subnet = mkOption {
						type = types.strMatching "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+";
						description = "IPv4 CIDR subnet assigned to the VLAN.";
					};

					permittedToAccessVlans = mkOption {
						type = types.listOf types.str;
						default = [ ];
						description = "VLAN interface names hosts on this VLAN may initiate connections to.";
					};

					canSshToRouter = mkOption {
						type = types.bool;
						default = false;
						description = "Whether hosts on this VLAN may make ssh connections to the router.";
					};

					internet = mkOption {
						type = types.bool;
						default = true;
						description = "Whether hosts on this VLAN are allowed outbound internet access.";
					};
				};
			});
			default = { };
			description = "LAN VLANs routed by this host.";
		};

		namedHosts = mkOption {
			type = types.attrsOf (types.submodule {
				options = {
					mac = mkOption {
						type = types.strMatching "[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]";
						description = "MAC address used to identify this host for DHCP.";
					};

					vlan = mkOption {
						type = types.str;
						description = "VLAN interface name this host belongs to.";
					};

					permittedToAccessVlans = mkOption {
						type = types.listOf types.str;
						default = [ ];
						description = "VLAN interface names this host may initiate connections to.";
					};
				};
			});
			default = { };
			description = "Named hosts with DHCP reservations and optional host-specific access rules.";
		};
	};
}
