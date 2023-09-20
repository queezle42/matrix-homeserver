{ config, lib, ... }:
with lib;

let
  cfg = config.matrix-homeserver;
in {
  config = mkIf (cfg.enable && cfg.metrics) {
    matrix-homeserver.synapse.settings = {
      enable_metrics = true;
      listeners = [
        {
          port = 8009;
          # Metrics are availabe on "/_synapse/metrics"
          type = "metrics";
          bind_addresses = ["127.0.0.1"];
        }
      ];
    };
  };
}
