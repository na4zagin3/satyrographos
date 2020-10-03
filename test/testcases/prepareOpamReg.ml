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

let grcnumDocFiles = [
  "grcnum-doc/metadata",
{|((version 1) (libraryName grcnum-doc) (libraryVersion 0.2) (compatibility ())
(dependencies ((fonts-theano ()) (grcnum ()))))|};
   "grcnum-doc/docs/grcnum-doc/doc-grcnum-ja.pdf", "@@doc-grcnum-ja.pdf@@"; ]

let classGreekFiles = [
  "class-greek/metadata",
{|((version 1) (libraryName class-greek) (libraryVersion 0.1) (compatibility ())
 (dependencies ((grcnum ()))))|};
  "class-greek/packages/class-greek/greek.satyh", "@@greek.satyh@@"; ]

let baseFiles = [
  "base/metadata",
{|((version 1) (libraryName base) (libraryVersion 1.1.1) (compatibility ())
(dependencies ()))|};
  "base/packages/base/void.satyh", "@@void.satyh@@"; ]

(* TODO Remove this function *)
let prepare =
  TestLib.prepare_files

