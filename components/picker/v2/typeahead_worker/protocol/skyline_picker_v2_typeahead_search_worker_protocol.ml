open! Core
module From_worker = From_worker
module Indices = Indices
module To_worker = To_worker
include Web_worker.Make (From_worker) (To_worker)
