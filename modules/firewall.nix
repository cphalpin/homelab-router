{ lib, config, ... }: let
	inherit (lib) filterAttrs join;

	vlanInterfaces = builtins.attrNames config.router.vlans;

	nftInterfaceSet = interfaces: join ", " (map ( name: ''"${name}"'' ) interfaces);
in {
	networking.nftables.enable = true;

	services.openssh.openFirewall = false;

	assertions = lib.mapAttrsToList ( name: { permittedToAccessVlans, ... }: {
		assertion = lib.all ( target: lib.elem target vlanInterfaces ) permittedToAccessVlans;
		message = "router.vlans entry '${name}' has unknown permittedToAccessVlans target(s): ${join ", " permittedToAccessVlans}";
	}) config.router.vlans;

	networking.firewall = {
		enable = true;
		filterForward = true;

		allowedTCPPorts = lib.mkForce [ ];
		allowedUDPPorts = lib.mkForce [ ];

		interfaces = lib.mapAttrs ( _: { canSshToRouter, ... }: {
			allowedTCPPorts = [ 53 ] ++ lib.optional canSshToRouter 22;
			allowedUDPPorts = [ 53 67 ];
		}) config.router.vlans;

		extraForwardRules = join "\n" (lib.mapAttrsToList ( name: { permittedToAccessVlans, ... }:
			''iifname "${name}" oifname { ${nftInterfaceSet permittedToAccessVlans} } accept''
		) (filterAttrs ( _: { permittedToAccessVlans, ... }: permittedToAccessVlans != [] ) config.router.vlans));
	};
}
