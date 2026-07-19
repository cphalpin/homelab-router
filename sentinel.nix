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

	router.vlans = [ {
		id = 2;
		name = "infrastructure";
		subnet = "192.168.1.0/24";
	} {
		id = 3;
		name = "trusted";
		subnet = "192.168.2.0/24";
		trusted = true;
	} {
		id = 4;
		name = "iot";
		subnet = "192.168.3.0/24";
	} {
		id = 5;
		name = "solarassistant";
		subnet = "192.168.4.0/24";
	} {
		id = 6;
		name = "guest";
		subnet = "192.168.0.0/24";
	}];

	programs.git.enable = true;
	programs.tmux.enable = true;

	system.stateVersion = "26.05";
}
