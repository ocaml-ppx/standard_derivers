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
