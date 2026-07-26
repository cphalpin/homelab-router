{ lib }: let
	ipv4 = import ./ipv4.nix { inherit lib; };
in {
	allocate = subnet: peers: lib.mapAttrsToList ( name: peer: let
		address = ipv4.nthAddress subnet peer.addressOffset;
	in
		assert peer.addressOffset > 1;
		peer // {
			inherit name address;
			allowedIPs = [ "${address}/32" ];
			persistentKeepalive = 25;
		}
	) peers;
}
