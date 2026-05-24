module Watersort exposing (..)


-- Color type
type Color
    = Red
    | Blue
    | Green
    | Yellow
    | Purple
    | Orange
    | Pink
    | Cyan
    | Brown
    | Gray
    | Black
    | White
    | Lime
    | Navy
    | Teal
    | Magenta


-- A slot can be empty or contain a color
type Slot
    = Empty
    | Filled Color


-- A bottle contains slots (ordered vertically from bottom to top)
type alias Bottle =
    { slots : List Slot
    , capacity : Int
    }


-- A board contains bottles
type alias Board =
    { bottles : List Bottle
    , numColors : Int
    }


-- A game state
type alias GameState =
    { board : Board
    , moves : List Move
    , seed : Int
    , levelNumber : Int
    , initialBoard : Board
    }


-- A move represents pouring from one bottle to another
type alias Move =
    { fromBottle : Int
    , toBottle : Int
    , colorMoved : Color
    , unitsMoved : Int
    }


-- Career level difficulty parameters
type alias LevelParameters =
    { numBottles : Int
    , slotsPerBottle : Int
    , difficulty : Difficulty
    }


type Difficulty
    = Easy
    | Normal
    | Hard
    | Extreme


-- Utility functions

{-| Create an empty bottle with a given capacity
-}
emptyBottle : Int -> Bottle
emptyBottle capacity =
    { slots = List.repeat capacity Empty
    , capacity = capacity
    }


{-| Create an empty board with a given number of bottles and slots per bottle
-}
emptyBoard : Int -> Int -> Int -> Board
emptyBoard numBottles slotsPerBottle numColors =
    { bottles = List.repeat numBottles (emptyBottle slotsPerBottle)
    , numColors = numColors
    }


{-| Check if a bottle is solved (contains only one color in all slots, no empty slots)
-}
isSolvedBottle : Bottle -> Bool
isSolvedBottle bottle =
    case bottle.slots of
        [] ->
            True

        first :: rest ->
            case first of
                Empty ->
                    False

                Filled color ->
                    List.all (\slot -> slot == Filled color) rest


{-| Check if a board is completely solved (all bottles are either empty or solved)
-}
isBoardSolved : Board -> Bool
isBoardSolved board =
    List.all isBottleSolvedOrEmpty board.bottles


{-| Check if a bottle is empty or solved
-}
isBottleSolvedOrEmpty : Bottle -> Bool
isBottleSolvedOrEmpty bottle =
    if List.all (\slot -> slot == Empty) bottle.slots then
        True

    else
        isSolvedBottle bottle


{-| Check if a bottle has at least one empty slot
-}
hasEmptySlot : Bottle -> Bool
hasEmptySlot bottle =
    List.any (\slot -> slot == Empty) bottle.slots


{-| Get the top color of a bottle (the first non-empty slot from the end)
-}
getTopColor : Bottle -> Maybe Color
getTopColor bottle =
    bottle.slots
        |> List.reverse
        |> List.dropWhile (\slot -> slot == Empty)
        |> List.head
        |> Maybe.andThen
            (\slot ->
                case slot of
                    Empty ->
                        Nothing

                    Filled color ->
                        Just color
            )


{-| Count the number of empty slots in a bottle
-}
countEmptySlots : Bottle -> Int
countEmptySlots bottle =
    List.length (List.filter (\slot -> slot == Empty) bottle.slots)


{-| Calculate next seed for career levels: (seed + 1000000007) % (2^50)
-}
nextSeed : Int -> Int
nextSeed seed =
    (seed + 1000000007) |> modBy (2 ^ 50)


{-| Determine level parameters based on level number
-}
levelParameters : Int -> LevelParameters
levelParameters levelNum =
    let
        baseDifficulty =
            (levelNum // 5) |> min 9

        difficulty =
            if modBy 100 levelNum == 0 then
                Extreme

            else if modBy 25 levelNum == 0 then
                Hard

            else
                case baseDifficulty of
                    0 ->
                        Easy

                    1 ->
                        Easy

                    _ ->
                        Normal

        lastDigit =
            modBy 10 levelNum

        easyLevel =
            lastDigit == 1 || lastDigit == 3 || lastDigit == 7 || lastDigit == 9

        numBottles =
            if modBy 100 levelNum == 0 then
                14

            else if modBy 25 levelNum == 0 then
                12

            else if easyLevel then
                4

            else
                3 + (baseDifficulty // 3)

        slotsPerBottle =
            if modBy 100 levelNum == 0 then
                8

            else if modBy 25 levelNum == 0 then
                8

            else if easyLevel then
                2

            else
                2 + (baseDifficulty // 3)
    in
    { numBottles = numBottles
    , slotsPerBottle = slotsPerBottle
    , difficulty = difficulty
    }
