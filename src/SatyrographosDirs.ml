open Core

let repository_dir sg_dir = Filename.concat sg_dir "repo"
let package_dir sg_dir = Filename.concat sg_dir "packages"
let metadata_file sg_dir = Filename.concat sg_dir "metadata"

let current_scheme_version sg_dir = Version.get_version sg_dir
