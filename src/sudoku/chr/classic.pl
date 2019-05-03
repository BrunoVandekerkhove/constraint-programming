%
% Classic model for the Sudoku CHR solver.
%
% Available variable heuristics include first_fail and input_order.
% Available value heuristics include indomain_min and indomain_max.
%
% @author   Michaël Dooreman & Bruno Vandekerkhove
% @version  1.0

:- module(classic, [solve/3,register_puzzle/3]).
:- use_module(library(chr)).
:- use_module(library(lists)).

:- chr_constraint assignment/3, variable_domain/5, first_fail/2, input_order/1, blocksize/1.

% ---------------------------
%        CHR rule base
% ---------------------------

% Constraint propagation (forward checking)
assignment(R,_,Val) \ variable_domain(R,C,V,L,Domain) # passive <=>
    select(Val,Domain,NewDomain) | NewL is L-1, NewL > 0, variable_domain(R,C,V,NewL,NewDomain).
assignment(_,C,Val) \ variable_domain(R,C,V,L,Domain) # passive <=>
    select(Val,Domain,NewDomain) | NewL is L-1, NewL > 0, variable_domain(R,C,V,NewL,NewDomain).
assignment(R1,C1,Val), blocksize(K) # passive \ variable_domain(R2,C2,V,L,Domain) # passive <=>
    block(K,R1,C1,B), block(K,R2,C2,B), select(Val,Domain,NewDomain)
    | NewL is L-1, NewL > 0, variable_domain(R2,C2,V,NewL,NewDomain).
assignment(_,_,_) <=> true.

% Input Order heuristic
input_order(N), variable_domain(R,C,Var,_,Domain) # passive
    <=> choose_val(Val,Domain,N), Var = Val, assignment(R,C,Val), input_order(N).

% First Fail heuristic
first_fail(L,N), variable_domain(R,C,Var,L,Domain) # passive
    <=> choose_val(Val,Domain,N), Var = Val, assignment(R,C,Val), first_fail(1,N).
first_fail(I,N) <=> I < N | NewI is I + 1, first_fail(NewI,N).
first_fail(_,_), blocksize(_) <=> true.

% The value heuristic
choose_val(X, List, _) :- member(X, List). % nth1(N, List, X).

% -----------------------------------------------
%  Entry point + utility functions for the model
% -----------------------------------------------

% Solve the given Sudoku puzzle with the classic model.
%
% @param Puzzle     The input puzzle as a list of lists.
% @param N          The dimension of the puzzle.
% @param K          The dimension of blocks.
solve(Puzzle, N, K) :-
    blocksize(K),
    register_puzzle(Puzzle, N, K),
    %input_order(N),
    first_fail(1,N).

% Register the pre-filled cells in the given puzzle.
%
% @param Puzzle     The input puzzle as a list of lists.
% @param N          The dimension of the puzzle.
% @param K          The dimension of blocks.
% @note No safety checks are done.
% @note Findall won't work here as it backtracks which undoes the insertion of constraints.
% @note Probably should have been written with recursion.
register_puzzle(Puzzle, N, _K) :-
    flatten(Puzzle, FlatPuzzle),
    findall(R-C-N-D, (create_domain(N,D),between(1,N,R),between(1,N,C)), Cells),
    maplist(generate_domain, Cells, FlatPuzzle), % The domains for cells that aren't assigned
    maplist(assign_value, Cells, FlatPuzzle). % Pre-filled cells
generate_domain(R-C-N-Domain, V) :- var(V) -> variable_domain(R,C,V,N,Domain) ; true.
assign_value(R-C-_-_, V) :- nonvar(V) -> assignment(R,C,V) ; true.
