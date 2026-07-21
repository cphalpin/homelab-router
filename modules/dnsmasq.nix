{ lib, config, ... }: let
	ipv4 = import ../lib/ipv4.nix { inherit lib; };
	namedHosts = import ../lib/named-hosts.nix { inherit lib; };

	cloudflareDnsAddresses = [
		"1.1.1.2"
		"1.0.0.2"
	];

	gatewayAddress = subnet: ipv4.firstAssignable subnet;
	allocatedNamedHosts = namedHosts.allocate config.router.vlans config.router.namedHosts;
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

			interface = builtins.attrNames config.router.vlans;

			dhcp-range = lib.mapAttrsToList ( name: { subnet, ... }: lib.join "," [
				"set:${name}"
				(ipv4.nthAddress subnet 2)
				(ipv4.lastAssignable subnet)
				"24h"
			]) config.router.vlans;

			dhcp-option = lib.flatten (lib.mapAttrsToList ( name: { subnet, ... }: [
				"tag:${name},option:router,${gatewayAddress subnet}"
				"tag:${name},option:dns-server,${gatewayAddress subnet}"
			]) config.router.vlans);

			dhcp-host = map ( { mac, name, address, ... }: lib.join "," [
				mac
				name
				address
				"infinite"
			]) allocatedNamedHosts;
		};
	};
}
