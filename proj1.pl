/*
** Author:  Jiahao Chen  1118749  jiahchen4@student.unimelb.edu.au
** COMP30020 - Declarative Programming: Project 1
** Semester 2, 2021
** 
** This project aims to solve fill-in puzzles using prolog.
** Puzzles may reach huge size (up to 32 by 20), which requires wise strategy.
**
** All support codes are written in the file proj2.pl. 
** The puzzle_solution/2 predicate will be satisfied if there is a solution.
** Functions are written as tail recursive if possible.
** CLPFD is used to help generating transpose matrix.
**
** Strategy: Find the best slot to fit each turn. 
** The best slot has the least amount of potential matches.
** For example, if there is only one 6-letter word, then fill it in first.
*/

:- ensure_loaded(library(clpfd)).

/*
** puzzle_solution(?Puzzle, +WordList).
**
** Get all the slots, then solve the puzzle recursively.
** It will fail if there is no solution.
*/
puzzle_solution(Puzzle, WordList) :-
    get_all_slots(Puzzle, Slots),
    puzzle_solve(Slots, WordList).

/*
** puzzle_solve(?Slots, +Words).
** 
** Find the best slot to fill, which has least amount of potential matches.
** Select(remove) this slot(word) from both word list and slot list.
** Recursively repeat the above procedures until there is a solution or fails.
*/
puzzle_solve([], []).
puzzle_solve(Slots, Words) :-
    best_match(Slots, Words, BestSlot),
    select(BestSlot, Words, RWords),
    select(BestSlot, Slots, RSlots),
    puzzle_solve(RSlots, RWords).

% ======================================================================= %
% Helper functions for getting slots in the puzzle.
% ======================================================================= %
/*
** get_all_slots(+Puzzle, -Slots).
**
** Find all slots in the puzzle vertically and horizontally.
** TPuzzle is the transposed puzzle generated by transpose/2.
** RSlots stands for slots in rows.
** CSlots stands for slots in columns.
*/
get_all_slots(Puzzle, Slots) :-
    transpose(Puzzle, TPuzzle),
    get_row_slots(Puzzle, RSlots),
    get_row_slots(TPuzzle, CSlots),
    append(RSlots, CSlots, Slots).

/*
** get_row_slots(+Puzzle, -Slots).
**
** Encapsulate the recursive call (get_row_slots/3).
*/
get_row_slots(Puzzle, Slots) :-
    get_row_slots(Puzzle, [], Slots).

/*
** get_row_slots(+Puzzle, -Slots0, -Slots).
**
** Keep adding new slots into slot lists (Slots).
** Slots0 is an accumulator which helps to reach tail recursive.
** Slots0 will finally unify with Slots when their is no more rows.
*/
get_row_slots([], Slots, Slots).
get_row_slots([Head|Rest], Slots0, Slots) :-
    get_slots(Head, [], NewSlot),
    append(Slots0, NewSlot, Slots1),
    get_row_slots(Rest, Slots1, Slots).

/*
** get_slots(+List, ?Slot, -Slots).
**
** Find slots in one list (row).
** Base case: Add current slot to slot lists (Slots) if length of slot > 1
** when there is no more elements in current row.
** Assume length of a word is at least 2.
** 
** General case: Keep updating current slot until '#' is encountered.
** Update slot list (Slots) when there is a new slot.
*/
get_slots([], Slot, Slots) :-
    length(Slot, L),
    ( L > 1 ->  
        Slots = [Slot]
    ; Slots = []
    ).
get_slots([Head|Rest], Slot, Slots) :-
    ( Head == '#' -> 
        length(Slot, L),
        ( L > 1 -> 
            Slots = [Slot|NewSlot]
        ; Slots = NewSlot
        ),
        get_slots(Rest, [], NewSlot)
    ; append(Slot, [Head], NewSlot),
      get_slots(Rest, NewSlot, Slots)
    ).

% ======================================================================= %
% Helper functions for finding matches for slots.
% ======================================================================= %
/*
** best_match(+Slots, +Words, -BestSlot).
**
** Sort all the slots based on their amount of potential matches 
** to find the slot with the least amount of potential matches. (BestSlot) 
*/
best_match(Slots, Words, BestSlot) :-
    potential_match(Slots, Words, Matches),
    maplist(length_value, Matches, LMatches),
    sort(1, @=<, LMatches, SortedMatches),
    [_-(BestSlot-_)|_] = SortedMatches.

/*
** potential_match(+Slots, +Words, -Matches).
**
** Find potential match words for each slot using setof/3.
** This is a vague filter which paves the way for best_match/3.
*/
potential_match([], _, []).
potential_match([Head|Rest], Words, [Head-Word|Matches]) :-
    setof(Head, member(Head, Words), Word),
    potential_match(Rest, Words, Matches).

/*
** length_value(+Pair, -NewPair).
**
** Make length of the value become key of the original pair
** so that we can sort slots in ascending order based on
** their amount of potential matches.
*/
length_value(Key-Value, L-Origin) :-
    Origin = Key-Value,
    length(Value, L).
