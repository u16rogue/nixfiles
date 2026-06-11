{ nixpkgs, ... }: {
    templates = let lib = nixpkgs.lib; in lib.pipe (builtins.readDir ./.) [
        (lib.filterAttrs (name: value: value == "directory"))
        (lib.mapAttrs (name: value: {
            path = ./. + "/${name}"; # sloppa told me this is the right thing to do
        }))
    ];
}

#{ nixpkgs, ... }: {
#    templates =
#        let
#            lib = nixpkgs.lib;
#            contents = builtins.readDir ./.;
#            folders = lib.pipe contents [
#                builtins.attrNames
#                (builtins.filter (name: contents.${name} == "directory"))
#            ];
#        in
#            builtins.listToAttrs (
#                (builtins.map (name: {
#                    inherit name;
#                    value.path = ./. + "/${name}"; # sloppa told me this is the right thing to do
#                }))
#                folders
#            )
#    ;
#}
