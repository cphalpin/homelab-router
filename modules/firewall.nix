{ lib, config, ... }: let
	inherit (lib) filterAttrs join;
	namedHosts = import ../lib/named-hosts.nix { inherit lib; };

	vlanInterfaces = builtins.attrNames config.router.vlans;
	allocatedNamedHosts = namedHosts.allocate config.router.vlans config.router.namedHosts;

	nftInterfaceSet = interfaces: join ", " (map ( name: ''"${name}"'' ) interfaces);
in {
	networking.nftables.enable = true;

	services.openssh.openFirewall = false;

	assertions = lib.mapAttrsToList ( name: { permittedToAccessVlans, ... }: {
		assertion = lib.all ( target: lib.elem target vlanInterfaces ) permittedToAccessVlans;
		message = "router.vlans entry '${name}' has unknown permittedToAccessVlans target(s): ${join ", " permittedToAccessVlans}";
	}) config.router.vlans
	++
	lib.mapAttrsToList ( name: { vlan, permittedToAccessVlans, ... }: {
		assertion = lib.elem vlan vlanInterfaces && lib.all ( target: lib.elem target vlanInterfaces ) permittedToAccessVlans;
		message = "router.namedHosts entry '${name}' must use a known vlan and known permittedToAccessVlans targets.";
	}) config.router.namedHosts;

	networking.firewall = {
		enable = true;
		filterForward = true;

		allowedTCPPorts = lib.mkForce [ ];
		allowedUDPPorts = lib.mkForce [ ];

		interfaces = lib.mapAttrs ( _: { canSshToRouter, ... }: {
			allowedTCPPorts = [ 53 ] ++ lib.optional canSshToRouter 22;
			allowedUDPPorts = [ 53 67 ];
		}) config.router.vlans;

		extraForwardRules = join "\n" ((lib.mapAttrsToList ( name: { permittedToAccessVlans, ... }:
			''iifname "${name}" oifname { ${nftInterfaceSet permittedToAccessVlans} } accept''
		) (filterAttrs ( _: { permittedToAccessVlans, ... }: permittedToAccessVlans != [] ) config.router.vlans))
		++
		(map ( { vlan, address, permittedToAccessVlans, ... }:
			''iifname "${vlan}" ip saddr ${address} oifname { ${nftInterfaceSet permittedToAccessVlans} } accept''
		) (builtins.filter ( { permittedToAccessVlans, ... }: permittedToAccessVlans != [ ] ) allocatedNamedHosts)));
	};
}
