val _ = Control.Print.printDepth := 10;
val _ = Control.Print.printLength := 10;
val _ = Control.Print.stringDepth := 2000;
val _ = Control.polyEqWarn := false;

fun split blockSize list = 
    let 
        fun split_helper inner_list accumulated_list count =
            if count < blockSize then
                case inner_list of
                    [] => []
                    | head::tail => 
                        split_helper tail (accumulated_list @ [head]) (count + 1)
            else 
                accumulated_list :: split_helper inner_list [] 0
    in
        split_helper list [] 0
    end;

fun xGCD (a, b) = 
    let 
        fun extended_gcd (old_r, r, old_s, s, old_t, t) =
            if r <> 0 then
                let 
                    val quotient = old_r div r
                in
                    extended_gcd(r, old_r - quotient * r, s, old_s - quotient * s, t, old_t - quotient * t)
                end
            else 
                (old_r, old_s, old_t)
    in
        extended_gcd (a, b, 1, 0, 0, 1)
    end;

signature RING =
sig
    eqtype t
    val zero : t
    val one : t
    val neg : t -> t
    val xGCD : t * t -> t * t * t
    val inv : t -> t option
    val + : t * t -> t
    val * : t * t -> t
end;

functor Ring (val n : int) :> RING where type t = int =
struct
    type t = int
    val zero = 0
    val one = 1
    fun neg x = ~x mod n
    val xGCD = xGCD
    
    fun inv x =
        case xGCD (x mod n, n) of
        (1, s, _) => SOME (s mod n)
        | _ => NONE

    fun op + a =  Int.+ a mod n
    fun op * p =  Int.* p mod n
end;

signature MAT =
sig
  eqtype t
  structure Vec :
    sig
        val dot : t list -> t list -> t
        val add : t list -> t list -> t list
        val sub : t list -> t list -> t list
        val scale : t -> t list -> t list
    end
  val tr : t list list -> t list list
  val mul : t list list -> t list list -> t list list
  val id : int -> t list list
  val join : t list list -> t list list -> t list list
  val inv : t list list -> t list list option
end;

functor Mat (R : RING) :> MAT where type t = R.t =
struct
  type t = R.t
  structure Vec =
    struct
        fun dot list1 list2 = List.foldl (fn (x, acc) => R.+(x, acc)) R.zero (ListPair.map (fn (x, y) => R.*(x, y)) (list1, list2))
        fun add list1 list2 = ListPair.map R.+ (list1, list2)
        fun sub list1 list2 = ListPair.map (fn (x, y) => R.+(x, (R.neg y))) (list1, list2)
        fun scale scalar list1 = List.map (fn x => R.*(x, scalar)) list1
    end

    fun tr matrix =
        case matrix of 
            [] => []
            | _ => case hd matrix of
                [] => []
                | _ => List.map (fn row => hd row) matrix :: tr (List.map (fn row => tl row) matrix)

    fun mul matrix1 matrix2 = List.map (fn rows => List.map (fn columns => Vec.dot rows columns) (tr matrix2)) matrix1

    fun id size = raise NotImplemented
    fun join _ _ = raise NotImplemented
    fun inv _ = raise NotImplemented
end;

structure M = Mat (Ring (val n = 27));

