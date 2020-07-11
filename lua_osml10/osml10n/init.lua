local osml10n = {}

local function import(submodule)
  for k,v in pairs(require(submodule)) do
    assert(osml10n[k] == nil, "oops dopplet gemoppelt")
    osml10n[k] = v
  end
end

import "osml10n.helper_functions"
import "osml10n.get_country_name"
import "osml10n.street_abbrev"
import "osml10n.geo_transcript"
import "osml10n.get_localized_name_from_tags"

return osml10n
