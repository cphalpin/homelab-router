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

					permittedToAccessHosts = mkOption {
						type = types.listOf types.str;
						default = [ ];
						description = "Named hosts this host may initiate connections to.";
					};
				};
			});
			default = { };
			description = "Named hosts with DHCP reservations and optional host-specific access rules.";
		};

		wireguard = {
			enable = mkOption {
				type = types.bool;
				default = false;
				description = "Whether to enable WireGuard remote access.";
			};

			interface = mkOption {
				type = types.str;
				default = "wg0";
				description = "WireGuard network interface name.";
			};

			subnet = mkOption {
				type = types.strMatching "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+";
				default = "10.100.0.0/24";
				description = "IPv4 CIDR subnet assigned to WireGuard clients.";
			};

			listenPort = mkOption {
				type = types.port;
				default = 51820;
				description = "UDP port WireGuard listens on.";
			};

			privateKeyFile = mkOption {
				type = types.path;
				default = "/etc/wireguard/wg0.key";
				description = "Path to the WireGuard private key installed out-of-band.";
			};

			permittedToAccessVlans = mkOption {
				type = types.listOf types.str;
				default = [ ];
				description = "VLAN interface names WireGuard clients may initiate connections to.";
			};

			permittedToAccessHosts = mkOption {
				type = types.listOf types.str;
				default = [ ];
				description = "Named hosts WireGuard clients may initiate connections to.";
			};

			canSshToRouter = mkOption {
				type = types.bool;
				default = false;
				description = "Whether WireGuard clients may make ssh connections to the router.";
			};

			internet = mkOption {
				type = types.bool;
				default = false;
				description = "Whether WireGuard clients are allowed outbound internet access through this router.";
			};

			peers = mkOption {
				type = types.attrsOf (types.submodule {
					options = {
						publicKey = mkOption {
							type = types.str;
							description = "WireGuard peer public key.";
						};

						addressOffset = mkOption {
							type = types.ints.positive;
							description = "Host offset in the WireGuard subnet assigned to this peer. For example, 2 in 10.100.0.0/24 becomes 10.100.0.2.";
						};
					};
				});
				default = { };
				description = "WireGuard peers allowed to connect to this router.";
			};
		};

		dynamicDns = {
			domainName = mkOption {
				type = types.nullOr types.str;
				default = null;
				description = "DNS name that should point at this router's public IPv4 address.";
			};
		};
	};
}
