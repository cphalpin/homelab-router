{ lib }: let
	inherit (lib.strings)
		splitString
		toInt;

	inherit (lib)
		genList;

	pow = lib.fix (
		self: base: power:
			if power != 0
			then base * (self base (power - 1))
			else 1
	);

	parseAddr = addr: let
		parts = map toInt (splitString "." addr);
	in
		assert builtins.length parts <= 4;
		parts ++ genList (_: 0) (4 - builtins.length parts);

	addrToInt = addr: let
		p = parseAddr addr;
	in
		builtins.foldl' ( acc: octet:
			assert octet >= 0 && octet <= 255;
			acc * 256 + octet
		) 0 p;

	intToAddr = n:
		assert n >= 0 && n <= 4294967295;
		let
			o0 = n / 16777216;
			r0 = n - o0 * 16777216;
			o1 = r0 / 65536;
			r1 = r0 - o1 * 65536;
			o2 = r1 / 256;
			o3 = r1 - o2 * 256;
		in
			"${toString o0}.${toString o1}.${toString o2}.${toString o3}";

	parseCidr = cidr: let
		parts = splitString "/" cidr;
		prefix = toInt (builtins.elemAt parts 1);
	in
		assert builtins.length parts == 2;
		assert prefix >= 0 && prefix <= 32;
		{
			inherit prefix;
			addr = builtins.elemAt parts 0;
		};

	normalize = subnet:
		if builtins.isString subnet
		then parseCidr subnet
		else subnet;

	hostBits = subnet: 32 - (normalize subnet).prefix;

	hostMask = subnet: let
		bits = hostBits subnet;
	in
		if bits == 0
		then 0
		else pow 2 bits - 1;

	networkInt = subnet: let
		c = normalize subnet;
		ip = addrToInt c.addr;
	in
		ip - (lib.mod ip (pow 2 (hostBits subnet)));

in rec {

	inherit parseCidr;

	networkAddress = subnet: intToAddr (networkInt subnet);

	broadcastAddress = subnet:
		intToAddr (builtins.bitOr (networkInt subnet) (hostMask subnet));

	subnetSize = subnet: pow 2 (hostBits subnet);

	useableAddresses = subnet:
		if (normalize subnet).prefix >= 31
		then subnetSize subnet
		else subnetSize subnet - 2;

	nthAddress = subnet: n:
		assert n >= 0;
		assert n < (subnetSize subnet);
		intToAddr (networkInt subnet + n);

	firstAssignable = subnet:
		if (normalize subnet).prefix >= 31
		then networkAddress subnet
		else nthAddress subnet 1;

	lastAssignable = subnet:
		if (normalize subnet).prefix >= 31
		then broadcastAddress subnet
		else nthAddress subnet (subnetSize subnet - 2);

	contains = subnet: addr: let
		base = networkInt subnet;
		ip = addrToInt addr;
	in
		ip >= base && ip < base + subnetSize subnet;

	offsetOf = subnet: addr:
		assert contains subnet addr;
		addrToInt addr - networkInt subnet;
}
