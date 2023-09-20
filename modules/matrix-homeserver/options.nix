inputs@{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.matrix-homeserver;
  settingsFormat = pkgs.formats.json {};
in {

  options.matrix-homeserver = {
    enable = mkEnableOption "matrix-homeserver with synapse and nginx configuration (reverse proxy and element)";

    serverName = mkOption {
      type = types.str;
      example = "example.com";
    };

    matrixDomain = mkOption {
      type = types.str;
      default = "matrix.${cfg.serverName}";
    };

    elementDomain = mkOption {
      type = types.str;
      default = "element.${cfg.serverName}";
    };

    turnRealm = mkOption {
      type = types.str;
      default = "turn.${cfg.serverName}";
    };

    useACMEHost = mkOption {
      type = types.str;
      default = null;
      description = ''
        An entry in 'security.acme.certs' from which certificates will be used.
        The certificate should be valid for 'matrixDomain' and 'elementDomain'.
      '';
    };

    recommendedSettings = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Include recommended synapse settings, tuned for a small VPS instance with a few users (see 'recommended-settings.nix').
      '';
    };

    metrics = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable metrics endpoint on "http://127.0.0.1/_synapse/metrics".
      '';
    };

    defaultDatabase = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Using Postgresql as a database is strongly recommended by synapse.
        It's enabled by default for this module, but can be disabled for manual database setup.
      '';
    };


    synapse = {
      package = mkOption {
        type = types.package;
        default = pkgs.matrix-synapse;
        defaultText = literalExpression "pkgs.matrix-synapse";
        description = ''
          Overridable attribute of the matrix synapse server package to use.
        '';
      };

      settings = mkOption {
        type = settingsFormat.type;
        default = {};
        description = ''
          https://matrix-org.github.io/synapse/latest/usage/configuration/homeserver_sample_config.html
        '';
      };

      configFile = mkOption {
        type = types.path;
        default = settingsFormat.generate "synapse-homeserver.yaml" cfg.synapse.settings;
        defaultText = ''settingsFormat.generate "synapse-homeserver.yaml" config.matrix-homeserver.configuration'';
        description = ''
          Path to the config file. By default generated from matrix-homeserver.settings.
          Setting this option breaks normal usage of the matrix-homeserver module.
        '';
      };

      extraConfigFiles = mkOption {
        type = types.attrsOf types.path;
        default = {};
        example = { secrets = "/path/to/matrix-synapse/secrets.yaml"; };
        description = ''
          Extra config files to include, e.g. as a way to include secrets without
          publishing them to the nix store.
          This is the recommended way to include the 'registration_shared_secret'
          and other secrets.
          Files will be read as root.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/matrix-synapse";
        description = ''
          The directory where matrix-synapse stores its stateful data such as
          certificates, media and uploads.
        '';
      };

      plugins = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression ''
          with config.services.matrix-synapse.package.plugins; [
            matrix-synapse-ldap3
            matrix-synapse-pam
          ];
        '';
        description = ''
          List of additional Matrix plugins to make available.
        '';
      };

      withJemalloc = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to preload jemalloc to reduce memory fragmentation and overall usage.
        '';
      };
    };


    well-known = {
      enable = mkEnableOption ''
        Configure '.well-known/matrix'-location on an existing 'nginx.virtualHost'.
        Can be enabled independently from 'matrix-homeserver.enable' to run the matrix server on another host.
      '';

      nginxVirtualHost = mkOption {
        type = types.str;
        default = cfg.serverName;
      };
    };

    # Configure a TURN server to run on the same host as synapse.
    coturn = {
      enable = mkEnableOption "coturn TURN server";

      useACMEHost = mkOption {
        type = types.str;
        description = ''
          An entry in 'security.acme.certs' from which certificates will be used.
        '';
      };

      authSecretPath = mkOption {
        type = types.path;
        default = "/var/lib/matrix-homeserver/coturn-static-auth-secret";
        description = ''
          File path where the coturn static-auth-secret is stored. The secret will be automatically created.
          Ensure the diretory exists and is not publicly readable when changing the path.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.coturn;
        defaultText = literalExpression "pkgs.coturn";
        description = ''
          Overridable attribute of the coturn package to use.
        '';
      };
    };

    # Heisenbridge IRC bouncer. Has to run un the same host as synapse.
    heisenbridge = {
      enable = mkEnableOption "heisenbridge";

      owner = mkOption {
        type = types.str;
        example = "@someone:example.com";
        description = ''
          MXID of the heisenbridge owner.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.heisenbridge;
        defaultText = literalExpression "pkgs.heisenbridge";
        description = ''
          Overridable attribute of the heisenbridge package to use.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services.matrix-synapse.enable;
        message = "Cannot use services.matrix-synapse.enable and matrix-homeserver.enable at the same time.";
      }
    ];

    matrix-homeserver.synapse.settings = mkMerge [
      (mkIf cfg.recommendedSettings (import ./recommended-settings.nix inputs))
      {
        server_name = cfg.serverName;
      }
    ];
  };
}
