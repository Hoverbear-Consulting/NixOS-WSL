# Build with
#   nix-build -A system -A config.system.build.tarball ./nixos.nix

let
    # Snapshots of specific git revisions used to compose the system
    snapshots = rec {
        # The main pkg repo
        nixpkgs = builtins.fetchGit {
            name = "nixpkgs";
            # `git ls-remote https://github.com/nixos/nixpkgs nixpkgs-unstable`
            rev = "5f14d99efed32721172a819b6e78a5520bab4bc6";
            url = "https://github.com/nixos/nixpkgs";
            ref = "refs/heads/nixpkgs-unstable";
        };
    };
    # Imported nix expressions.
    nix = rec {
        pkgs = import snapshots.nixpkgs;
        os = import "${snapshots.nixpkgs}/nixos";
    };
    profile = "${snapshots.nixpkgs}/nixos/modules/profiles/minimal.nix";
    # The end configuration of the VM
    personality = rec {
        configuration = {
            imports = [
                profile
            ];
            boot.isContainer = true;
            environment.etc.hosts.enable = false;
            environment.etc."resolv.conf".enable = false;
            networking.dhcpcd.enable = false;

            system.build.tarball = nix.pkgs.callPackage "${snapshots.nixpkgs}/nixos/lib/make-system-tarball.nix" {
                contents = [];
                storeContents = nix.pkgs.pkgs2storeContents [
                    nix.config.system.build.toplevel
                    nix.pkgs.stdenv
                    nix.pkgs.channelSources
                ];
                extraCommands = "";
                compressCommand = "gzip";
                compressionExtension = ".gz";
            };
        };
        system = "x86_64-linux";
    };
in
nix.os personality