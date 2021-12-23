type t =
  { x : int
  ; mutable y : bool
  }
[@@deriving_inline create]

include sig [@@@ocaml.warning "-32"] 
  val create : x:int -> y:bool -> t
end
[@@ocaml.doc "@inline"]

[@@@end]
