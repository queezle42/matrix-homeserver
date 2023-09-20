{
  imports = [
    ./options.nix
    ./matrix-synapse.nix
    ./postgresql.nix
    ./reverse-proxy.nix
    ./element.nix
    ./well-known.nix
    ./coturn.nix
    ./heisenbridge.nix
    ./metrics.nix
  ];
}
