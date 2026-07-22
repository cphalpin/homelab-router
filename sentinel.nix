{ ... }: {
	imports = [
		./hardware-configuration.nix
		./modules/options.nix
		./modules/networking.nix
		./modules/firewall.nix
		./modules/dnsmasq.nix
	];

	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	networking.hostName = "sentinel";

	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	time.timeZone = "Europe/London";

	services.openssh.enable = true;

	users.users.cph = {
		isNormalUser = true;
		extraGroups = [ "wheel" ];
		openssh.authorizedKeys.keys = [
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgVWROnGReXJ2WVGn8+1VTmzzYQ9gkQM6jTgrnvOkDi cph@tantalum"
		];
	};

	router.wan-interface = "enp1s0";
	router.lan-interface = "enp2s0";

	router.vlans = {
		infrastructure = {
			id = 2;
			subnet = "192.168.1.0/24";
		};
		trusted = {
			id = 3;
			subnet = "192.168.2.0/24";
			permittedToAccessVlans = [
				"infrastructure"
				"services"
			];
			canSshToRouter = true;
		};
		iot = {
			id = 4;
			subnet = "192.168.3.0/24";
		};
		services = {
			id = 5;
			subnet = "192.168.4.0/24";
		};
		guest = {
			id = 6;
			subnet = "192.168.0.0/24";
		};
		users = {
			id = 7;
			subnet = "192.168.5.0/24";
			permittedToAccessVlans = [ "services" ];
		};
	};

	router.namedHosts = {
		crossroads = {
			mac = "a0:2b:b8:0b:95:80";
			vlan = "infrastructure";
		};
		home-assistant = {
			mac = "52:54:73:ce:d2:0a";
			vlan = "services";
			permittedToAccessVlans = [ "iot" ];
		};
	};

	programs.git.enable = true;
	programs.tmux.enable = true;

	system.stateVersion = "26.05";
}
