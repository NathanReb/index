open! Import

module type S = sig
  type t

  val v :
    ?flush_callback:(unit -> unit) ->
    readonly:bool ->
    fresh:bool ->
    generation:int63 ->
    fan_size:int63 ->
    string ->
    t

  val v_readonly : string -> t option

  val offset : t -> int63

  val read : t -> off:int63 -> len:int -> bytes -> int

  val clear : generation:int63 -> t -> unit

  val flush : ?no_callback:unit -> ?with_fsync:bool -> t -> unit

  val get_generation : t -> int63

  val set_fanout : t -> string -> unit

  val get_fanout : t -> string

  val rename : src:t -> dst:t -> unit

  val append : t -> string -> unit

  val close : t -> unit

  module Lock : sig
    type t

    val lock : string -> t

    val unlock : t -> unit

    val pp_dump : string -> (Format.formatter -> unit) option
    (** To be used for debugging purposes only. *)
  end

  module Header : sig
    type header = { offset : int63; generation : int63 }

    val set : t -> header -> unit

    val get : t -> header
  end

  val exists : string -> bool
  (** [exists name] is true iff there is a pre-existing IO instance called
      [name]. *)

  val size : t -> int
  (** Returns the true size of the underlying data representation in bytes. Note
      that this is not necessarily equal to the total size of {i observable}
      data, which is given by {!offset}.

      To be used for debugging purposes only. *)
end

module type Io = sig
  module type S = S

  module Extend (S : S) : sig
    include S with type t = S.t

    val iter :
      page_size:int63 ->
      ?min:int63 ->
      ?max:int63 ->
      (off:int63 -> buf:string -> buf_off:int -> int) ->
      t ->
      unit
  end
end
