(* pplacer v0.3. Copyright (C) 2009  Frederick A Matsen.
 * This file is part of pplacer. pplacer is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. pplacer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with pplacer.  If not, see <http://www.gnu.org/licenses/>.
 *
 * do we want to have a "count", could have a combine_data
*)


open MapsSets

type 'a t = { data : 'a option; node : ('a t) IntMap.t }

type approx_choice = int * int list -> int

let empty = { data = None; node = IntMap.empty; }

let rec mem k t = 
  match k with
  | [] -> true 
  | x::l ->
      if IntMap.mem x t.node then mem l (IntMap.find x t.node)
      else false

let rec find k t = 
  match k with
  | [] -> t.data
  | x::l ->
      if IntMap.mem x t.node then find l (IntMap.find x t.node)
      else raise Not_found

let rec add k y t = 
  match k with
  | [] -> { t with data = Some y }
  | x::l ->
      { t with node = 
        IntMap.add
          x
          (add l y
            (if IntMap.mem x t.node then IntMap.find x t.node
            else empty))
          t.node }

let rec approx_find choice k t = 
  let rec aux k t = 
    match k with
    | [] -> t.data
    | x::l ->
        if IntMap.mem x t.node then aux l (IntMap.find x t.node)
        else 
        aux l (IntMap.find (choice x (IntMapFuns.keys t.node)) t.node)
  in
  aux t k


(* ppr *)

let rec ppr ppr_v ff t = 
  Format.fprintf ff "@[{";
  Format.fprintf ff "@[data = %a; @]" (Ppr.ppr_opt ppr_v) t.data;
    Ppr.ppr_list_inners 
     (fun ff k ->
       Format.fprintf ff "%a -> @[%a@]"
         Format.pp_print_int k
         (ppr ppr_v) (IntMap.find k t.node))
     ff
     (IntMapFuns.keys t.node);
  Format.fprintf ff "}@]"

let ppr_int = ppr Format.pp_print_int
