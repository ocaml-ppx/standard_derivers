-------------------------------------------------
-----------------STRUCTURE TESTS-----------------
-------------------------------------------------
Test 1: regular record type
  $ test1="
  > type a = {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test1" > test.ml
  $ ./driver.exe test.ml
  type a = {
    x: int ;
    y: bool }[@@deriving make]
  include
    struct
      let _ = fun (_ : a) -> ()
      let make_a ~x  ~y  = { x; y }
      let _ = make_a
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 2: unexposed regular record type
  $ test4="
  > type b = {
  >   x : int ;
  >   y : string }[@@deriving make]"
  $ echo "$test2" > test.ml
  $ ./driver.exe test.ml

Test 3: invalid non-record type
  $ test3="
  > type c = int * int
  > [@@deriving make]"
  $ echo "$test3" > test.ml
  $ ./driver.exe test.ml
  File "test.ml", lines 2-3, characters 0-17:
  2 | type c = int * int
  3 | [@@deriving make]
  Error: Unsupported use of make (you can only use it on records).
  [1]

Test 4: recursive record types
  $ test4="
  > type d = {
  >   v: e ;
  >   w: bool }
  > and e = {
  >   x: int ;
  >   mutable y: bool ;
  >   z: d }[@@deriving make]"
  $ echo "$test4" > test.ml  
  $ ./driver.exe test.ml
  type d = {
    v: e ;
    w: bool }
  and e = {
    x: int ;
    mutable y: bool ;
    z: d }[@@deriving make]
  include
    struct
      let _ = fun (_ : d) -> ()
      let _ = fun (_ : e) -> ()
      let make_d ~v  ~w  = { v; w }
      let _ = make_d
      let make_e ~x  ~y  ~z  = { x; y; z }
      let _ = make_e
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 5: recursive types including a record type
  $ test5="
  > type f = int*g
  > and g = {
  >   v: f ;
  >   w: bool }[@@deriving make]"
  $ echo "$test5" > test.ml  
  $ ./driver.exe test.ml
  type f = (int * g)
  and g = {
    v: f ;
    w: bool }[@@deriving make]
  include
    struct
      let _ = fun (_ : f) -> ()
      let _ = fun (_ : g) -> ()
      let make_g ~v  ~w  = { v; w }
      let _ = make_g
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 6: recursive types without any record types
  $ test6="
  > type f = int*g
  > and g = bool*f [@@deriving make]"
  $ echo "$test6" > test.ml  
  $ ./driver.exe test.ml
  File "test.ml", lines 2-3, characters 0-32:
  2 | type f = int*g
  3 | and g = bool*f [@@deriving make]
  Error: 'with fields' can only be applied on type definitions in which at least one type definition is a record
  [1]

-------------------------------------------------
------------------INLINE TESTS-------------------
-------------------------------------------------
Test 1: regular record type
  $ test1="
  > type a = {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test1" > test.mli
  $ ./driver.exe test.mli 
  type a = {
    x: int ;
    y: bool }[@@deriving make]
  include sig [@@@ocaml.warning "-32"] val make_a : x:int -> y:bool -> a end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

Test 2: invalid non-record type
  $ test2="
  > type c = int * int
  > [@@deriving make]"
  $ echo "$test2" > test.mli
  $ ./driver.exe test.mli
  File "test.mli", lines 2-3, characters 0-17:
  2 | type c = int * int
  3 | [@@deriving make]
  Error: Unsupported use of make (you can only use it on records).
  [1]

Test 3: recursive record types
  $ test3="
  > type d = {
  >   v: e ;
  >   w: bool }
  > and e = {
  >   x: int ;
  >   mutable y: bool ;
  >   z: d }[@@deriving make]"
  $ echo "$test3" > test.mli
  $ ./driver.exe test.mli
  type d = {
    v: e ;
    w: bool }
  and e = {
    x: int ;
    mutable y: bool ;
    z: d }[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      val make_d : v:e -> w:bool -> d
      val make_e : x:int -> y:bool -> z:d -> e
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
