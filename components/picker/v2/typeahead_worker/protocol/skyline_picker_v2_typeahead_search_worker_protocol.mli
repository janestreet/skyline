open! Core
module From_worker = From_worker
module Indices = Indices
module To_worker = To_worker

include
  Web_worker.S
  with type to_worker_message := To_worker.message
   and type to_worker_t := To_worker.t
   and type from_worker_t := From_worker.t
   and type from_worker_message := From_worker.message
