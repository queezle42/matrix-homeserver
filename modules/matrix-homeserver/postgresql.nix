{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.matrix-homeserver;
in {
  config = mkIf (cfg.enable && cfg.defaultDatabase) {
    # postgresql database service
    services.postgresql = {
      enable = true;
      # NOTE: Automatic database has been disabled, so synapse fails with an
      # empty database. This way synapse cannot start when the database is
      # empty, e.g. if accidentally started during a postgres migration.

      # This query has to be executed once to set up the database:
      #initialScript = pkgs.writeText "synapse-init.sql" ''
      #  CREATE USER "matrix-synapse";
      #  CREATE DATABASE "matrix-synapse" WITH
      #    OWNER "matrix-synapse"
      #    TEMPLATE template0
      #    ENCODING 'UTF8'
      #    LC_COLLATE = 'C'
      #    LC_CTYPE = 'C';
      #'';

      settings.listen_addresses = mkForce "";
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
