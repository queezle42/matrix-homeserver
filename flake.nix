{
  outputs = { ... }: {
    nixosModules.matrix-homeserver = ./modules/matrix-homeserver;
  };
}
