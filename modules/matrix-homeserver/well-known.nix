{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.matrix-homeserver;
  vhostName = cfg.well-known.nginxVirtualHost;
  vhost = config.services.nginx.virtualHosts.${vhostName};
  commonConfig = ''
    default_type application/json;
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
    add_header 'Access-Control-Allow-Headers' 'X-Requested-With, Content-Type, Authorization';
  '';
  serverWellKnown."m.server" = "${cfg.matrixDomain}:443";
  clientWellKnown = {
    "m.homeserver".base_url = "https://${cfg.matrixDomain}";
  };

in {
  config = mkIf cfg.well-known.enable {
    # Ensure ssl is configured
    assertions = [
      {
        assertion = vhost.forceSSL || vhost.onlySSL || vhost.addSSL;
        message = "No ssl configured for services.nginx.virtualHosts.\"${vhostName}\"";
      }
    ];

    services.nginx.virtualHosts.${vhostName}.locations = {
      "=/.well-known/matrix/server" = {
        extraConfig = commonConfig;
        return = "200 '${builtins.toJSON serverWellKnown}'";
      };
      "=/.well-known/matrix/client" = {
        extraConfig = commonConfig;
        return = "200 '${builtins.toJSON clientWellKnown}'";
      };
    };
  };
}
