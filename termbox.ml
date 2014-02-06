open Core.Std

type color =
  | Default
  | Black
  | Red
  | Green
  | Yellow
  | Blue
  | Magenta
  | Cyan
  | White

type key =
  | F1
  | F2
  | F3
  | F4
  | F5
  | F6
  | F7
  | F8
  | F9
  | F10
  | F11
  | F12
  | Insert
  | Delete
  | Home
  | End
  | Page_up
  | Page_down
  | Arrow_up
  | Arrow_down
  | Arrow_left
  | Arrow_right

type event =
  | Key of key
  | Ascii of char
  | Utf8 of int32
  | Resize of int * int

module Termbox : sig
  val init : unit -> int
  val shutdown : unit -> unit

  val width : unit -> int
  val height : unit -> int

  val clear : unit -> unit
  val set_clear_attributes : color -> color -> unit

  val present : unit -> unit

  val set_cursor : int -> int -> unit
  val hide_cursor : unit -> unit

  val set_cell_char : ?fg : color -> ?bg : color -> int -> int -> char -> unit
  val set_cell_utf8 : ?fg : color -> ?bg : color -> int -> int -> int32 -> unit

  val poll_event : unit -> event
end = struct
  type cell = { ch : int; fg : color; bg : color }
  type buff = cell list

  external init : unit -> int = "tbstub_init"
  external shutdown : unit -> unit = "tb_shutdown"

  external width : unit -> int = "tbstub_width"
  external height : unit -> int = "tbstub_height"

  external clear : unit -> unit = "tb_clear"

  external set_clear_attributes : color -> color -> unit = "tbstub_set_clear_attributes"

  external present : unit -> unit = "tb_present"

  external set_cursor : int -> int -> unit = "tbstub_set_cursor"

  let hide_cursor () =
    set_cursor (-1) (-1)

  external tb_change_cell : int -> int -> int32 -> color -> color -> unit = "tbstub_change_cell"

  let set_cell_utf8 ?(fg=Default) ?(bg=Default) x y ch =
    tb_change_cell x y ch fg bg

  let set_cell_char ?(fg=Default) ?(bg=Default) x y ch =
    let ch_int32 = Int32.of_int_exn (Char.to_int ch) in
    set_cell_utf8 ~fg ~bg x y ch_int32

  external poll_event : unit -> event = "tbstub_poll_event"
end