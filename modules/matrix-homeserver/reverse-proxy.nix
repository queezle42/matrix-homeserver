{ config, lib, ... }:
with lib;

let
  cfg = config.matrix-homeserver;
  proxyLocationConfig = {
    # Add required headers, but only if recommendedProxySettings is disabled
    extraConfig = mkMerge [
      (mkIf (!config.services.nginx.recommendedProxySettings) ''
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
      '')
      # 50M is the current synapse default, update if that changes
      "client_max_body_size ${cfg.settings.max_upload_size or "50M"};"
    ];
    proxyPass = "http://127.0.0.1:8008";
  };
in {
  config = mkIf cfg.enable {
    # local matrix-synapse listener
    matrix-homeserver.synapse.settings = {
      enable_metrics = true;
      listeners = [
        {
          port = 8008;
          tls = false;
          type = "http";
          x_forwarded = true;
          # TODO switch to unix socket
          bind_addresses = ["127.0.0.1"];
          resources = [
            {
              # Metrics are availabe locally on "/_synapse/metrics" but are not
              # added to the reverse proxy
              names = ["client" "federation"];
              compress = false;
            }
          ];
        }
      ];
    };

    # nginx proxy
    services.nginx.virtualHosts.${cfg.matrixDomain} = {
      forceSSL = true;
      useACMEHost = cfg.useACMEHost;

      locations."/".extraConfig = "return 302 'https://${cfg.elementDomain}/';";
      locations."/_matrix" = proxyLocationConfig;
      locations."/_synapse/client" = proxyLocationConfig;
    };
  };
}
