(* Test 1: regular record type *)
type a = 
  { x : int
  ; y : bool
  }
[@@deriving_inline make]

let _ = fun (_ : a) -> ()
let make_a ~x  ~y  = { x; y }
let _ = make_a
[@@@end]

(* Test 2: recursive record types *)
type b = 
  { v : c
  ; w : bool
  }
and c =
  { x : int
  ; mutable y : bool
  ; z : b
  }
[@@deriving_inline make]

let _ = fun (_ : b) -> ()
let _ = fun (_ : c) -> ()
let make_b ~v  ~w  = { v; w }
let _ = make_b
let make_c ~x  ~y  ~z  = { x; y; z }
let _ = make_c
[@@@end]

(* Test 3: invalid non-record type *)
(* type d = int * int
[@@deriving_inline make]
[@@@end] *)

(* Test 4: record type unexposed in interface *)
type e = 
  { x : int
  ; y : string
  }
[@@deriving_inline make]

let _ = fun (_ : e) -> ()
let make_e ~x  ~y  = { x; y }
let _ = make_e
[@@@end]
