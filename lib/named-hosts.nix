{ lib }: let
	ipv4 = import ./ipv4.nix { inherit lib; };
in {
	allocate = vlans: namedHosts: let
		hostNames = builtins.attrNames namedHosts;
		hostsInVlan = vlan: builtins.filter ( name: (builtins.getAttr name namedHosts).vlan == vlan ) hostNames;
		allocateHost = vlan: subnet: index: let
			name = builtins.elemAt (hostsInVlan vlan) index;
			host = builtins.getAttr name namedHosts;
		in host // {
			inherit name;
			address = ipv4.nthAddress subnet (10 + index);
		};
		allocateVlan = vlan: { subnet, ... }: let
			names = hostsInVlan vlan;
		in builtins.genList (allocateHost vlan subnet) (builtins.length names);
	in lib.flatten (lib.mapAttrsToList allocateVlan vlans);
}
