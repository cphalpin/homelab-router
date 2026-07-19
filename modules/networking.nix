{ lib, config, ... }: let
	ipv4 = import ../lib/ipv4.nix { inherit lib; };

	internetVlans = lib.filter ( { internet, ... }: internet ) config.router.vlans;
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
		internalInterfaces = map ( { name, ... }: name ) internetVlans;
	};

	systemd.network.netdevs = builtins.listToAttrs ( map ( { id, name, ... }: {
		name = "10-${name}";
		value = {
			netdevConfig = {
				Kind = "vlan";
				Name = name;
			};
			vlanConfig.Id = id;
		};
	}) config.router.vlans );

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
			vlan = map (lib.attrByPath [ "name" ] "") config.router.vlans;
		};
	} // builtins.listToAttrs ( map ( { name, subnet, ... }: {
		name = name;
		value = {
			matchConfig.Name = name;
			networkConfig.LinkLocalAddressing = "ipv4";
			address = [
				"${ipv4.firstAssignable subnet}/${toString (ipv4.parseCidr subnet).prefix}"
			];
		};
	} ) config.router.vlans );
}
