{ lib, config, ... }: let
	ipv4 = import ../lib/ipv4.nix { inherit lib; };
	wireguardPeers = import ../lib/wireguard-peers.nix { inherit lib; };

	internetVlans = lib.filterAttrs ( _: { internet, ... }: internet ) config.router.vlans;
	wireguard = config.router.wireguard;
	allocatedWireguardPeers = wireguardPeers.allocate wireguard.subnet wireguard.peers;
	wireguardAddress = "${ipv4.firstAssignable wireguard.subnet}/${toString (ipv4.parseCidr wireguard.subnet).prefix}";
	internetInterfaces = (builtins.attrNames internetVlans) ++ lib.optional (wireguard.enable && wireguard.internet) wireguard.interface;
in {
	networking.useNetworkd = true;

	systemd.network.enable = true;

	# Set up proper interal IPv6 support
	networking.enableIPv6 = true;
	networking.useDHCP = false;

	boot.kernel.sysctl = {
		"net.ipv4.ip_forward" = 1;
		"net.ipv6.conf.all.forwarding" = 0;
		"net.ipv6.conf.default.forwarding" = 0;
	};

	networking.nat = {
		enable = true;
		externalInterface = config.router.wan-interface;
		internalInterfaces = internetInterfaces;
	};

	networking.wireguard.interfaces = lib.optionalAttrs wireguard.enable {
		"${wireguard.interface}" = {
			ips = [ wireguardAddress ];
			listenPort = wireguard.listenPort;
			privateKeyFile = wireguard.privateKeyFile;
			peers = map ( peer: lib.filterAttrs ( name: value: ! lib.elem name [ "name" "address" "addressOffset" ] && value != null ) peer ) allocatedWireguardPeers;
		};
	};

	systemd.network.netdevs = lib.mapAttrs' ( name: { id, ... }:
		lib.nameValuePair "10-${name}" {
			netdevConfig = {
				Kind = "vlan";
				Name = name;
			};
			vlanConfig.Id = id;
		}
	) config.router.vlans;

	systemd.network.networks = {
		wan = {
			matchConfig.Name = config.router.wan-interface;
			networkConfig = {
				DHCP = "yes";
				IPv6AcceptRA = true;
			};
		};
		lan = {
			matchConfig.Name = config.router.lan-interface;
			networkConfig.LinkLocalAddressing = "ipv4";
			vlan = builtins.attrNames config.router.vlans;
		};
	} // lib.mapAttrs ( name: { subnet, ... }: {
			matchConfig.Name = name;
			networkConfig.LinkLocalAddressing = "ipv4";
			address = [
				"${ipv4.firstAssignable subnet}/${toString (ipv4.parseCidr subnet).prefix}"
			];
	} ) config.router.vlans;
}
