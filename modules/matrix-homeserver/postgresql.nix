{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.matrix-homeserver;
in {
  config = mkIf (cfg.enable && cfg.defaultDatabase) {
    # postgresql database service
    services.postgresql = {
      enable = true;
      # NOTE: This query will only executed on a fresh postgresql installation.
      # Manual setup is required when using an existing database.
      initialScript = pkgs.writeText "synapse-init.sql" ''
        CREATE USER "matrix-synapse";
        CREATE DATABASE "matrix-synapse" WITH
          OWNER "matrix-synapse"
          TEMPLATE template0
          ENCODING 'UTF8'
          LC_COLLATE = 'C'
          LC_CTYPE = 'C';
      '';
    };

    # matrix-synapse database configuration
    matrix-homeserver.synapse.settings.database = {
      name = "psycopg2";
      args = {
        user = "matrix-synapse";
        database = "matrix-synapse";
      };
    };
  };
}
