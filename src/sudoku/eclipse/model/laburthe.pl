%
% Laburthe's models for the Sudoku CLP solver.
%   These are experiments with the three proposed models ;
%       PRIMAL >> DUAL >> ABSTRACT
%   (each model reinforces the previous one)
%
% @author   Michaël Dooreman & Bruno Vandekerkhove
% @version  1.0

% Set up the model for the given puzzle.
%
% @param Puzzle     The puzzle list to declare domains for.
% @param N          The dimension of the puzzle.
% @param K          The dimension of blocks.
setup_model(Puzzle, N, K, flatten(Variables)) :-
    list_2d_to_array(Puzzle, PuzzleArray),
    % Declare domains and generate constraints
    declare_domains_laburthe(PuzzleArray, Dual, Abstract, N, K),
    generate_constraints_laburthe(PuzzleArray, Dual, Abstract, N, K),
    % Make list of decision variables
    collection_to_list(flatten(Dual), DualList),
    collection_to_list(flatten(Abstract), AbstractList),
    append(Puzzle, DualList, Out),
    append(Out, AbstractList, Variables).

% Declare the domains for the given puzzle.
%
% @param Puzzle     The input puzzle (an array).
% @param Dual       Variables for the DUAL model.
% @param Abstract   Variables for the ABSTRACT model.
% @param N          The dimension of the puzzle.
declare_domains_laburthe(Puzzle, Dual, Abstract, N, K) :-
    % PRIMAL
    Puzzle :: 1..N,
    % DUAL
    dim(Dual, [3,N,N]), % Dual variables, each row has one series
    Dual :: 1..N,
    % ABSTRACT
    dim(Abstract, [4,N,N]), % Abstract variables, each row has one series
    % Abstract :: 1..N,
    (for(I, 1, N, K), param(Abstract, K, N) do
        J is I + K - 1,
        Abstract[1,I..J,1..N] :: I..J,
        Abstract[3,I..J,1..N] :: I..J
    ),
    (for(I, 1, N), param(Abstract, K, N) do
        findall(B, (block_column(N, K, I, B)), Blocks),
        Abstract[2,I,1..N] :: Blocks,
        findall(C, (block_column(N, K, C, I)), Columns),
        Abstract[4,I,1..N] :: Columns
    ).

% Generate the constraints for the given puzzle.
%
% @param Puzzle     The input puzzle (an array).
% @param Dual       Variables for the DUAL model.
% @param Abstract   Variables for the ABSTRACT model.
% @param N          The dimension of the puzzle.
% @param K          The dimension of blocks.
generate_constraints_laburthe(Puzzle, Dual, Abstract, N, K) :-
    % PRIMAL
    (for(I,1,N), param(Puzzle, N) do % Go through every row & column
        alldifferent(Puzzle[I,1..N]), % Different integer in row cells
        alldifferent(Puzzle[1..N,I]) % Different integer in column cells
    ),
    (multifor([I,J], 1, N, K), param(Puzzle, K) do
        alldifferent(flatten(Puzzle[I..I+K-1,J..J+K-1])) % Different integers in block cells
    ),
    % DUAL
    (multifor([I,V,X], 1, N), param(Puzzle, Dual, K) do
        #=(Dual[1,I,V], X, BoolRow),
        #=(Puzzle[I,X], V, BoolRow),
        #=(Dual[2,I,V], X, BoolColumn),
        #=(Puzzle[X,I], V, BoolColumn),
        #=(Dual[3,I,V], X, BoolBlock),
        row(K, I, X, Row),
        column(K, I, X, Column),
        #=(Puzzle[Row,Column], V, BoolBlock)
    ),
    (multifor([I,J], 1, [3,N]), param(Dual, N) do
        alldifferent(Dual[I,J,1..N])
    ),
    % ABSTRACT
    (multifor([I,V,X], 1, N), param(Dual, Abstract, K) do
        block(K, I, X, BlockL),
        Dual[1,I,V] #= X => Abstract[1,I,V] #= BlockL,
        block(K, X, I, BlockC),
        Dual[2,I,V] #= X => Abstract[2,I,V] #= BlockC,
        row(K, I, X, Row), % Block == i, InBlock == X
        Dual[3,I,V] #= X => Abstract[3,I,V] #= Row,
        column(K, I, X, Column), % Block == i, InBlock == X
        Dual[3,I,V] #= X => Abstract[4,I,V] #= Column
    ),
    (for(V, 1, N), param(Abstract, N, K) do % Multifor is less readable
        (for(I, 1, N, K), param(Abstract, K, N, V) do
            J is I + K - 1,
            alldifferent(Abstract[1,I..J,V]),
            alldifferent(Abstract[2,I..J,V]),
            alldifferent(Abstract[3,I..J,V]),
            findall(X, (block_column(N,K,I,B), X is Abstract[4,B,V]), Xs),
            alldifferent(Xs)
        )
    ).

% Checks whether the given column and block intersect.
%
% @param N      The puzzle size.
% @param K      The block size.
% @param Column The column number.
% @param Block  The block number.
block_column(N, K, Column, Block) :-
    between(1, N, 1, Block),
    Max is K * ((Block-1) mod K) + 3,
    between(1, N, 1, Column),
    Column =< Max,
    Column > Max - K.

% Transform the assignments to the decision variables to a solved puzzle.
%
% @param Variables  The decision variables (should be assigned).
% @param Puzzle     The input puzzle (this is a list).
% @param N          The dimension of the puzzle.
% @param K          The dimension of blocks.
% @param Solution   The puzzle's solution corresponding to the assignments to the variables.
read_solution(_, Puzzle, _, _, Puzzle).
