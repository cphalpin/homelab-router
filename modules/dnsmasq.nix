{ lib, config, ... }: let
	ipv4 = import ../lib/ipv4.nix { inherit lib; };

	cloudflareDnsAddresses = [
		"1.1.1.2"
		"1.0.0.2"
	];

	gatewayAddress = subnet: ipv4.firstAssignable subnet;
in {
	services.dnsmasq = {
		enable = true;

		settings = {
			domain-needed = true;
			bogus-priv = true;
			dhcp-authoritative = true;
			bind-dynamic = true;

			domain = "home";
			expand-hosts = true;
			local = "/home/";

			no-resolv = true;

			server = cloudflareDnsAddresses;

			interface = map ( { name, ... }: name ) config.router.vlans;

			dhcp-range = map ( { name, subnet, ... }: lib.join "," [
				"set:${name}"
				(ipv4.nthAddress subnet 2)
				(ipv4.lastAssignable subnet)
				"24h"
			]) config.router.vlans;

			dhcp-option = lib.flatten (map ( { name, subnet, ... }: [
				"tag:${name},option:router,${gatewayAddress subnet}"
				"tag:${name},option:dns-server,${gatewayAddress subnet}"
			]) config.router.vlans);
		};
	};
}
