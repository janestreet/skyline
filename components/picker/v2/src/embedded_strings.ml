open! Core
open! Private_skyline_prelude

module For_worker_filter = struct
  let worker_blob_js =
    [%embed_file_as_string
      "components/picker/v2/typeahead_worker/bin/typeahead_worker.bc.js"]
  ;;
end
