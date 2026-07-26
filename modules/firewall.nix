{ lib, config, ... }: let
	inherit (lib) filterAttrs join;
	namedHosts = import ../lib/named-hosts.nix { inherit lib; };

	vlanInterfaces = builtins.attrNames config.router.vlans;
	namedHostNames = builtins.attrNames config.router.namedHosts;
	allocatedNamedHosts = namedHosts.allocate config.router.vlans config.router.namedHosts;
	wireguard = config.router.wireguard;
	wireguardNamedHosts = builtins.filter ( { name, ... }: lib.elem name wireguard.permittedToAccessHosts ) allocatedNamedHosts;

	nftInterfaceSet = interfaces: join ", " (map ( name: ''"${name}"'' ) interfaces);
	namedHostTargetRules = lib.flatten (map ( source:
		map ( target: ''iifname "${source.vlan}" ip saddr ${source.address} ip daddr ${target.address} oifname "${target.vlan}" accept'' )
			(builtins.filter ( { name, ... }: lib.elem name source.permittedToAccessHosts ) allocatedNamedHosts)
	) (builtins.filter ( { permittedToAccessHosts, ... }: permittedToAccessHosts != [ ] ) allocatedNamedHosts));
in {
	networking.nftables.enable = true;

	services.openssh.openFirewall = false;

	assertions = lib.mapAttrsToList ( name: { permittedToAccessVlans, ... }: {
		assertion = lib.all ( target: lib.elem target vlanInterfaces ) permittedToAccessVlans;
		message = "router.vlans entry '${name}' has unknown permittedToAccessVlans target(s): ${join ", " permittedToAccessVlans}";
	}) config.router.vlans
	++
	lib.mapAttrsToList ( name: { vlan, permittedToAccessVlans, permittedToAccessHosts, ... }: {
		assertion =
			lib.elem vlan vlanInterfaces
			&&
			lib.all ( target: lib.elem target vlanInterfaces ) permittedToAccessVlans
			&&
			lib.all ( target: lib.elem target namedHostNames ) permittedToAccessHosts;
		message = "router.namedHosts entry '${name}' must use a known vlan, known permittedToAccessVlans targets, and known permittedToAccessHosts targets.";
	}) config.router.namedHosts
	++
	lib.optional wireguard.enable {
		assertion =
			lib.all ( target: lib.elem target vlanInterfaces ) wireguard.permittedToAccessVlans
			&&
			lib.all ( target: lib.elem target namedHostNames ) wireguard.permittedToAccessHosts;
		message = "router.wireguard has unknown permittedToAccessVlans or permittedToAccessHosts target(s).";
	};

	networking.firewall = {
		enable = true;
		filterForward = true;

		allowedTCPPorts = lib.mkForce [ ];
		allowedUDPPorts = lib.mkForce [ ];

		interfaces = lib.mapAttrs ( _: { canSshToRouter, ... }: {
			allowedTCPPorts = [ 53 ] ++ lib.optional canSshToRouter 22;
			allowedUDPPorts = [ 53 67 ];
		}) config.router.vlans
		// lib.optionalAttrs wireguard.enable {
			"${config.router.wan-interface}".allowedUDPPorts = [ wireguard.listenPort ];
			"${wireguard.interface}" = {
				allowedTCPPorts = [ 53 ] ++ lib.optional wireguard.canSshToRouter 22;
				allowedUDPPorts = [ 53 ];
			};
		};

		extraForwardRules = join "\n" ((lib.mapAttrsToList ( name: { permittedToAccessVlans, ... }:
			''iifname "${name}" oifname { ${nftInterfaceSet permittedToAccessVlans} } accept''
		) (filterAttrs ( _: { permittedToAccessVlans, ... }: permittedToAccessVlans != [] ) config.router.vlans))
		++
		(map ( { vlan, address, permittedToAccessVlans, ... }:
			''iifname "${vlan}" ip saddr ${address} oifname { ${nftInterfaceSet permittedToAccessVlans} } accept''
		) (builtins.filter ( { permittedToAccessVlans, ... }: permittedToAccessVlans != [ ] ) allocatedNamedHosts))
		++
		namedHostTargetRules
		++
		lib.optional (wireguard.enable && wireguard.permittedToAccessVlans != [ ])
			''iifname "${wireguard.interface}" oifname { ${nftInterfaceSet wireguard.permittedToAccessVlans} } accept''
		++
		(map ( { vlan, address, ... }:
			''iifname "${wireguard.interface}" ip daddr ${address} oifname "${vlan}" accept''
		) wireguardNamedHosts));
	};
}
