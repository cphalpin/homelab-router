{ lib, config, ... }: let
	dynamicDns = config.router.dynamicDns;
	enabled = dynamicDns.domainName != null;
in {
	services.cloudflare-dyndns = {
		enable = enabled;
		domains = lib.optional enabled dynamicDns.domainName;
		apiTokenFile = "/etc/cloudflare-dyndns/api-token";
		frequency = "*:0/5";
		ipv4 = true;
		ipv6 = false;
		proxied = false;
	};
}
