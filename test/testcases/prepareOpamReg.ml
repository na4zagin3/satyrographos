open Shexp_process
open Shexp_process.Infix

let theanoMetadata = "fonts-theano/metadata",
{|((version 1) (libraryName fonts-theano) (libraryVersion 2.0)
 (compatibility
  ((rename_fonts
    (((new_name fonts-theano:TheanoDidot) (old_name TheanoDidot))
     ((new_name fonts-theano:TheanoModern) (old_name TheanoModern))
     ((new_name fonts-theano:TheanoOldStyle) (old_name TheanoOldStyle))))))
 (dependencies ()))|}

let theanoFiles =
  [ theanoMetadata;
    "fonts-theano/hash/fonts.satysfi-hash",
      {|{"fonts-theano:TheanoDidot":<"Single":{"src-dist":"fonts-theano/TheanoDidot-Regular.otf"}>,"fonts-theano:TheanoModern":<"Single":{"src-dist":"fonts-theano/TheanoModern-Regular.otf"}>,"fonts-theano:TheanoOldStyle":<"Single":{"src-dist":"fonts-theano/TheanoOldStyle-Regular.otf"}>}|};
    "fonts-theano/fonts/fonts-theano/TheanoDidot-Regular.otf",
      "@@TheanoDidot-Regular.otf@@";
    "fonts-theano/fonts/fonts-theano/TheanoModern-Regular.otf",
      "@@TheanoModern-Regular.otf@@";
    "fonts-theano/fonts/fonts-theano/TheanoOldStyle-Regular.otf",
      "@@TheanoOldStyle-Regular.otf@@";
  ]

let grcnumMetadata = "grcnum/metadata",
{|((version 1) (libraryName grcnum) (libraryVersion 0.2)
 (compatibility
  ((rename_packages
    (((new_name grcnum/grcnum.satyh) (old_name grcnum.satyh))))))
 (dependencies ((fonts-theano ()))))|}

let grcnumPackagesGrcnumGrcnum = "grcnum/packages/grcnum/grcnum.satyh", "@@grcnum.satyh@@"

let grcnumFiles = [ grcnumMetadata; grcnumPackagesGrcnumGrcnum; ]

let prepare dir files =
  List.iter files ~f:(fun (file, content) ->
    let path = FilePath.concat dir file in
    mkdir ~p:() (FilePath.dirname path)
    >> (stdout_to path (echo content))
  )

