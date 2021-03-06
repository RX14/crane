module Crane
  VERSION     = "0.1.0"
  DESCRIPTION = "Manage and install crystal versions and toolchains with ease"
end

require "./util"
require "./version_manager"
require "./command"
require "./tasks/**"
