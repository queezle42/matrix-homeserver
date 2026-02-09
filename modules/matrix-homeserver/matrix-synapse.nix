{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.matrix-homeserver;
  extraConfigFileArgs = concatStringsSep " " (mapAttrsToList (name: _path: "--config-path \${CREDENTIALS_DIRECTORY}/${name}.yaml") cfg.synapse.extraConfigFiles);

in {
  config = mkIf cfg.enable {
    matrix-homeserver.synapse.settings = {
      pid_file = mkDefault "/run/matrix-synapse.pid";
      signing_key_path = mkDefault "${cfg.synapse.dataDir}/${cfg.serverName}.signing.key";
      media_store_path = mkDefault "${cfg.synapse.dataDir}/media";
    };

    # User and group
    users.users.matrix-synapse = {
      group = "matrix-synapse";
      home = cfg.synapse.dataDir;
      createHome = true;
      shell = "${pkgs.bash}/bin/bash";
      uid = config.ids.uids.matrix-synapse;
    };

    users.groups.matrix-synapse = {
      gid = config.ids.gids.matrix-synapse;
    };

    # Service unit
    systemd.services.matrix-synapse = {
      description = "Synapse Matrix homeserver";
      after = [ "network.target" "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      preStart = "${cfg.synapse.package}/bin/synapse_homeserver --config-path ${cfg.synapse.configFile} --keys-directory ${cfg.synapse.dataDir} --generate-keys";
      environment = optionalAttrs (cfg.synapse.withJemalloc) {
        LD_PRELOAD = "${pkgs.jemalloc}/lib/libjemalloc.so";
      };

      serviceConfig = {
        Type = "notify";
        ExecStart = ''
          ${cfg.synapse.package}/bin/synapse_homeserver --config-path ${cfg.synapse.configFile} ${extraConfigFileArgs} --keys-directory ${cfg.synapse.dataDir}
        '';

        User = "matrix-synapse";
        Group = "matrix-synapse";
        WorkingDirectory = cfg.synapse.dataDir;

        LoadCredential = mapAttrsToList (name: path: "${name}.yaml:${path}") cfg.synapse.extraConfigFiles;

        ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        UMask = "0077";

        ProtectSystem = "full";
        ProtectHome = true;
        ProtectProc = "invisible";
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        RestrictRealtime = true;
        PrivateDevices = true;
      };
    };
  };
}
