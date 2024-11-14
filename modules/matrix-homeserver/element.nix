{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.matrix-homeserver;

  elementConfigFile = (pkgs.formats.json {}).generate "element.config.json" elementConfig;

  elementServerConfigFileName = "config.${cfg.elementDomain}.json";

  elementConfigDir = pkgs.linkFarm "element-config-dir" [
    { name = "config.json"; path = elementConfigFile; }
    { name = elementServerConfigFileName; path = elementConfigFile; }
  ];

  elementConfig = {
    default_server_name = cfg.serverName;

    disable_custom_urls = true;
    disable_guests = true;
    disable_3pid_login = true;

    defaultCountryCode = "us";
    showLabsSettings = true;
    show_labs_settings = true;
    enable_presence_by_hs_url = {
      "https://matrix.org" = false;
      "https://matrix-client.matrix.org" = false;
    };
  };
in {
  config = mkIf cfg.enable {
    services.nginx.virtualHosts.${cfg.elementDomain} = {
      onlySSL = true;
      useACMEHost = cfg.useACMEHost;
      root = pkgs.element-web;
      locations = {
        "=/config.json" = {
          root = elementConfigDir;
        };
        "=/${elementServerConfigFileName}" = {
          root = elementConfigDir;
        };
      };
    };
  };
}
