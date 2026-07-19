{ lib, config, ... }: let
	inherit (lib) join filter;

	vlanInterfaces = map ( { name, ... }: name ) config.router.vlans;

	nftInterfaceSet = interfaces: join ", " (map ( name: ''"${name}"'' ) interfaces);

	trustedVlans = filter ( { trusted, ... }: trusted ) config.router.vlans;

in {
	networking.nftables.enable = true;

	services.openssh.openFirewall = false;

	networking.firewall = {
		enable = true;
		filterForward = true;

		allowedTCPPorts = lib.mkForce [ ];
		allowedUDPPorts = lib.mkForce [ ];

		interfaces = builtins.listToAttrs (map ( { name, trusted, ... }: {
			inherit name;
			value = {
				allowedTCPPorts = [ 53 ] ++ lib.optional trusted 22;
				allowedUDPPorts = [ 53 67 ];
			};
		}) config.router.vlans);

		extraForwardRules = join "\n" (map ( { name, ... }:
			''iifname "${name}" oifname { ${nftInterfaceSet vlanInterfaces} } accept''
		) trustedVlans);
	};
}
