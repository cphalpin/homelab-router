{ lib, config, ... }: let
	inherit (lib) join filter;

	vlanInterfaces = map ( { name, ... }: name ) config.router.vlans;

	nftInterfaceSet = interfaces: join ", " (map ( name: ''"${name}"'' ) interfaces);
in {
	networking.nftables.enable = true;

	services.openssh.openFirewall = false;

	assertions = map ( { name, permittedToAccessVlans, ... }: {
		assertion = lib.all ( target: lib.elem target vlanInterfaces ) permittedToAccessVlans;
		message = "router.vlans entry '${name}' has unknown permittedToAccessVlans target(s): ${join ", " permittedToAccessVlans}";
	}) config.router.vlans;

	networking.firewall = {
		enable = true;
		filterForward = true;

		allowedTCPPorts = lib.mkForce [ ];
		allowedUDPPorts = lib.mkForce [ ];

		interfaces = builtins.listToAttrs (map ( { name, canSshToRouter, ... }: {
			inherit name;
			value = {
				allowedTCPPorts = [ 53 ] ++ lib.optional canSshToRouter 22;
				allowedUDPPorts = [ 53 67 ];
			};
		}) config.router.vlans);

		extraForwardRules = join "\n" (map (
			{ name, permittedToAccessVlans, ... }:
				''iifname "${name}" oifname { ${nftInterfaceSet permittedToAccessVlans} } accept''
		) (filter ( { permittedToAccessVlans, ... }: permittedToAccessVlans != [ ] ) config.router.vlans));
	};
}
