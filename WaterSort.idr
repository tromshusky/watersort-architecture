module WaterSort

%default total

-- ============================================================================
-- Types and Data Structures
-- ============================================================================

||| Color type for water in the bottles
public export
data Color = Red | Blue | Green | Yellow | Purple | Orange
  deriving (Eq, Ord, Show)

||| A slot in a bottle can be empty or contain a color
public export
data Slot = Empty | Filled Color
  deriving (Eq, Show)

||| A bottle has 4 slots
public export
record Bottle where
  constructor MkBottle
  slots : Vect 4 Slot

public export
Show Bottle where
  show (MkBottle slots) = "[" ++ show (toList slots) ++ "]"

||| A Vect of 12 bottles (10 filled + 2 empty)
public export
Bottles : Type
Bottles = Vect 12 Bottle

||| Game state
public export
record GameState where
  constructor MkGameState
  bottles : Bottles
  moves : Nat
  solved : Bool

public export
Show GameState where
  show (MkGameState bottles moves solved) = 
    "GameState { bottles: " ++ show bottles ++ 
    ", moves: " ++ show moves ++ 
    ", solved: " ++ show solved ++ " }"

-- ============================================================================
-- Model and Logic
-- ============================================================================

||| Check if a bottle is completely empty
isEmptyBottle : Bottle -> Bool
isEmptyBottle (MkBottle slots) = all (\s => s == Empty) (toList slots)

||| Check if a bottle is completely filled with one color
isFullBottle : Bottle -> Bool
isFullBottle (MkBottle slots) = 
  let slotList = toList slots
  in case slotList of
    [] => False
    (x :: xs) => 
      let isFilled = case x of
            Empty => False
            Filled _ => True
      in isFilled && all (\s => s == x) (toList slots)

||| Get the top color of a bottle (if any)
topColor : Bottle -> Maybe Color
topColor (MkBottle slots) = 
  case reverse (toList slots) of
    [] => Nothing
    (Filled c :: _) => Just c
    (Empty :: rest) => 
      case reverse rest of
        [] => Nothing
        (Filled c :: _) => Just c
        _ => Nothing

||| Count consecutive colors from the top of a bottle
countTopColor : Bottle -> Nat
countTopColor (MkBottle slots) =
  case topColor (MkBottle slots) of
    Nothing => 0
    Just c => 
      let reversed = reverse (toList slots)
          filled = takeWhile (\s => s == Filled c) reversed
      in length filled

||| Get available space in a bottle (number of empty slots)
availableSpace : Bottle -> Nat
availableSpace (MkBottle slots) = length (filter (\s => s == Empty) (toList slots))

||| Check if we can pour from source bottle to destination bottle
canPour : Bottle -> Bottle -> Bool
canPour src dst =
  case (topColor src, topColor dst) of
    (Nothing, _) => False  -- Source is empty
    (_, Nothing) => availableSpace dst > 0  -- Destination is empty
    (Just c1, Just c2) => c1 == c2 && availableSpace dst > 0  -- Same color and space
    _ => False

||| Pour from source to destination
||| Returns Nothing if the pour is invalid
pour : Bottle -> Bottle -> Maybe (Bottle, Bottle)
pour src@(MkBottle srcSlots) dst@(MkBottle dstSlots) =
  if not (canPour src dst) then Nothing
  else
    case (topColor src, topColor dst) of
      (Nothing, _) => Nothing
      (Just srcColor, _) =>
        let
          srcList = toList srcSlots
          dstList = toList dstSlots
          
          -- How many can we pour
          canPourCount = min (countTopColor src) (availableSpace dst)
          
          -- Remove from source (from the top)
          reversedSrc = reverse srcList
          filledCount = length (takeWhile (\s => s /= Empty) reversedSrc)
          emptyCount = 4 `minus` filledCount
          
          newSrcList = replicate emptyCount Empty ++ 
                       drop canPourCount (take filledCount reversedSrc)
          
          -- Add to destination
          newDstSlots = replicate canPourCount (Filled srcColor) ++ 
                        filter (\s => s == Empty) dstList
          
          newSrc = MkBottle (fromList (take 4 (reverse newSrcList)))
          newDst = MkBottle (fromList (take 4 newDstSlots))
        in
          Just (newSrc, newDst)

||| Check if the game is solved (all non-empty bottles are filled with one color)
isSolved : Bottles -> Bool
isSolved bottles =
  all (\b => isEmptyBottle b || isFullBottle b) (toList bottles)

||| Check if a game state is solvable (basic heuristic)
||| A state is considered solvable if it's not already stuck
isSolvable : Bottles -> Bool
isSolvable bottles = True  -- Simplified: all states are assumed solvable for now
                            -- A proper implementation would need a solver

-- ============================================================================
-- Game Update Logic (Elm Architecture)
-- ============================================================================

||| Msg type for Elm architecture
public export
data Msg 
  = Pour Nat Nat  -- Pour from bottle i to bottle j
  | Reset
  | Solve

||| Update function following Elm architecture
update : Msg -> GameState -> GameState
update msg state@(MkGameState bottles moves solved) =
  case msg of
    Pour i j =>
      if solved || i >= 12 || j >= 12 || i == j
      then state
      else
        let
          srcBottle = index i bottles
          dstBottle = index j bottles
        in
          case pour srcBottle dstBottle of
            Nothing => state
            Just (newSrc, newDst) =>
              let
                newBottles = replaceAt i newSrc bottles
                newBottles' = replaceAt j newDst newBottles
                newSolved = isSolved newBottles'
              in
                MkGameState newBottles' (moves + 1) newSolved
    
    Reset => MkGameState bottles 0 False
    Solve => state  -- Placeholder for AI solver

-- ============================================================================
-- Initial State Generation
-- ============================================================================

||| Big prime for pseudo-random seed advancement
bigPrime : Nat
bigPrime = 1000000007

||| Modulo for seed space (2^50)
seedSpace : Nat
seedSpace = 1125899906842624

||| Simple pseudo-random number generator
prng : Nat -> Nat
prng seed = (seed * bigPrime) `mod` seedSpace

||| Generate initial bottles from a seed
generateInitialBottles : Nat -> Bottles
generateInitialBottles seed =
  let
    -- Create 10 filled bottles (each with 4 of the same color)
    -- Distribute 6 colors across 10 bottles (each color appears twice)
    filledBottles : List Bottle = 
      [MkBottle (replicate 4 (Filled Red)),
       MkBottle (replicate 4 (Filled Red)),
       MkBottle (replicate 4 (Filled Blue)),
       MkBottle (replicate 4 (Filled Blue)),
       MkBottle (replicate 4 (Filled Green)),
       MkBottle (replicate 4 (Filled Green)),
       MkBottle (replicate 4 (Filled Yellow)),
       MkBottle (replicate 4 (Filled Yellow)),
       MkBottle (replicate 4 (Filled Purple)),
       MkBottle (replicate 4 (Filled Purple))]
    
    -- 2 empty bottles
    emptyBottles : List Bottle =
      [MkBottle (replicate 4 Empty),
       MkBottle (replicate 4 Empty)]
  in
    case fromList (filledBottles ++ emptyBottles) of
      Nothing => MkBottle (replicate 4 Empty) `replicate` 12
      Just v => v

||| Find a solvable initial state from a timestamp
findSolvableState : Nat -> Nat -> Bottles
findSolvableState timestamp attempts =
  if attempts >= 1000 then
    -- Fallback: return default state if we can't find solvable state
    generateInitialBottles timestamp
  else
    let
      state = generateInitialBottles timestamp
    in
      if isSolvable state
      then state
      else
        let
          nextSeed = ((timestamp + bigPrime) `mod` seedSpace)
        in
          findSolvableState nextSeed (attempts + 1)

||| Initialize game state from Unix timestamp (milliseconds)
initGameState : Nat -> GameState
initGameState timestampMs =
  let
    seed = timestampMs `mod` seedSpace
    bottles = findSolvableState seed 0
  in
    MkGameState bottles 0 False

-- ============================================================================
-- Utilities
-- ============================================================================

||| Helper function to generate list of naturals
range : Nat -> Nat -> List Nat
range n m = if n >= m then [] else n :: range (n + 1) m

||| Get all valid moves from current state
validMoves : Bottles -> List (Nat, Nat)
validMoves bottles =
  [ (i, j) | i <- range 0 12,
             j <- range 0 12,
             i /= j,
             canPour (index i bottles) (index j bottles) ]

||| Render game state as a string
renderGameState : GameState -> String
renderGameState state = show state
