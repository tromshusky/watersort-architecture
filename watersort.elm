module Watersort exposing (..)


-- Colors

type Color
    = Red | Blue | Green | Yellow | Purple | Orange | Pink | Cyan
    | Brown | Gray | Black | White | Lime | Navy | Teal | Magenta


-- Bottle structure

type Slot
    = Empty | Filled Color

type alias Bottle =
    { slots : List Slot
    , capacity : Int
    }


-- Board and game state

type alias Board =
    { bottles : List Bottle
    , numColors : Int
    }

type alias GameState =
    { board : Board
    , moves : List Move
    , seed : Int
    , levelNumber : Int
    , initialBoard : Board
    }


-- Moves and difficulty

type alias Move =
    { fromBottle : Int
    , toBottle : Int
    , colorMoved : Color
    , unitsMoved : Int
    }

type Difficulty
    = Easy | Normal | Hard | Extreme

type alias LevelParameters =
    { numBottles : Int
    , slotsPerBottle : Int
    , difficulty : Difficulty
    }


-- Utility functions

emptyBottle : Int -> Bottle
emptyBottle capacity = { slots = List.repeat capacity Empty, capacity = capacity }

emptyBoard : Int -> Int -> Int -> Board
emptyBoard numBottles slotsPerBottle numColors = { bottles = List.repeat numBottles (emptyBottle slotsPerBottle), numColors = numColors }

isSolvedBottle : Bottle -> Bool
isSolvedBottle bottle = case bottle.slots of
    [] -> True
    first :: rest -> case first of
        Empty -> False
        Filled color -> List.all (\slot -> slot == Filled color) rest

isBoardSolved : Board -> Bool
isBoardSolved board = List.all isBottleSolvedOrEmpty board.bottles

isBottleSolvedOrEmpty : Bottle -> Bool
isBottleSolvedOrEmpty bottle = if List.all (\slot -> slot == Empty) bottle.slots then True else isSolvedBottle bottle

hasEmptySlot : Bottle -> Bool
hasEmptySlot bottle = List.any (\slot -> slot == Empty) bottle.slots

getTopColor : Bottle -> Maybe Color
getTopColor bottle = bottle.slots |> List.reverse |> List.dropWhile (\slot -> slot == Empty) |> List.head |> Maybe.andThen (\slot -> case slot of
    Empty -> Nothing
    Filled color -> Just color)

countEmptySlots : Bottle -> Int
countEmptySlots bottle = List.length (List.filter (\slot -> slot == Empty) bottle.slots)

nextSeed : Int -> Int
nextSeed seed = (seed + 1000000007) |> modBy (2 ^ 50)

levelParameters : Int -> LevelParameters
levelParameters levelNum =
    let
        baseDifficulty = (levelNum // 5) |> min 9
        difficulty = if modBy 100 levelNum == 0 then Extreme else if modBy 25 levelNum == 0 then Hard else case baseDifficulty of
            0 -> Easy
            1 -> Easy
            _ -> Normal
        lastDigit = modBy 10 levelNum
        easyLevel = lastDigit == 1 || lastDigit == 3 || lastDigit == 7 || lastDigit == 9
        numBottles = if modBy 100 levelNum == 0 then 14 else if modBy 25 levelNum == 0 then 12 else if easyLevel then 4 else 3 + (baseDifficulty // 3)
        slotsPerBottle = if modBy 100 levelNum == 0 then 8 else if modBy 25 levelNum == 0 then 8 else if easyLevel then 2 else 2 + (baseDifficulty // 3)
    in
    { numBottles = numBottles, slotsPerBottle = slotsPerBottle, difficulty = difficulty }
