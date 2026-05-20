/**
 * Water Sort Game - Type-Safe Architecture
 * 
 * This file defines the complete type system for a Water Sort game.
 * Any runtime implementation must conform to these type definitions,
 * ensuring type safety and correctness at the TypeScript level.
 */

// ============================================================================
// Core Types and Data Structures
// ============================================================================

/** Color enumeration for water in bottles */
export type Color = 'red' | 'blue' | 'green' | 'yellow' | 'purple' | 'orange';

/** A slot in a bottle can be empty or contain a color */
export type Slot = { type: 'empty' } | { type: 'filled'; color: Color };

/** A bottle with exactly 4 slots */
export type Bottle = readonly [Slot, Slot, Slot, Slot];

/** Tuple of 12 bottles (10 filled + 2 empty) */
export type Bottles = readonly [
  Bottle, Bottle, Bottle, Bottle, Bottle, Bottle,
  Bottle, Bottle, Bottle, Bottle, Bottle, Bottle
];

/** Game state representation */
export interface GameState {
  readonly bottles: Bottles;
  readonly moves: number;
  readonly solved: boolean;
}

// ============================================================================
// Game Logic Type Constraints
// ============================================================================

/** Pour action: from bottle index i to bottle index j */
export type PourAction = {
  readonly type: 'pour';
  readonly from: number;
  readonly to: number;
};

/** Reset action */
export type ResetAction = {
  readonly type: 'reset';
};

/** Solve action (AI solver placeholder) */
export type SolveAction = {
  readonly type: 'solve';
};

/** Valid game messages */
export type Msg = PourAction | ResetAction | SolveAction;

// ============================================================================
// Core Logic Constraints
// ============================================================================

/**
 * Validates that a bottle index is within bounds [0, 11]
 */
export type ValidBottleIndex = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11;

/**
 * Validates that source and destination are different
 */
export type ValidPourAction = PourAction & {
  readonly from: ValidBottleIndex;
  readonly to: ValidBottleIndex;
  // This is a marker - actual validation happens at runtime
  readonly _validated: true;
};

/**
 * Signature for checking if a bottle is empty
 * Returns true iff all slots contain Empty
 */
export interface IsEmptyBottle {
  (bottle: Bottle): boolean;
}

/**
 * Signature for checking if a bottle is completely filled with one color
 * Returns true iff all slots are filled and all contain the same color
 */
export interface IsFullBottle {
  (bottle: Bottle): boolean;
}

/**
 * Signature for getting the top color of a bottle
 * Returns Some color if there's a filled slot at the top, None otherwise
 */
export interface TopColor {
  (bottle: Bottle): Color | null;
}

/**
 * Signature for counting consecutive colors from the top
 */
export interface CountTopColor {
  (bottle: Bottle): 0 | 1 | 2 | 3 | 4;
}

/**
 * Signature for getting available space (empty slots)
 */
export interface AvailableSpace {
  (bottle: Bottle): 0 | 1 | 2 | 3 | 4;
}

/**
 * Signature for checking if pour is valid
 * Pre-conditions:
 *  - src is not empty
 *  - dst has available space
 *  - if dst is not empty, top colors match
 */
export interface CanPour {
  (src: Bottle, dst: Bottle): boolean;
}

/**
 * Signature for performing a pour operation
 * Returns [newSrc, newDst] if valid, null if invalid
 * 
 * Constraints:
 *  - Must validate with canPour first
 *  - Must preserve total water quantity
 *  - Must pour from top of src
 *  - Must pour to top of dst
 *  - Must not exceed dst capacity
 */
export interface Pour {
  (src: Bottle, dst: Bottle): [Bottle, Bottle] | null;
}

/**
 * Signature for checking if game is solved
 * Returns true iff all non-empty bottles are complete (full with one color)
 */
export interface IsSolved {
  (bottles: Bottles): boolean;
}

/**
 * Signature for checking if a state is solvable
 * May perform heuristic checks or BFS/DFS to determine solvability
 */
export interface IsSolvable {
  (bottles: Bottles): boolean;
}

// ============================================================================
// Elm Architecture Constraints
// ============================================================================

/**
 * Pure update function signature
 * Must be a pure function: (Msg, GameState) -> GameState
 * 
 * Constraints:
 *  - Pour action: validates indices, calls pour(), updates moves, checks isSolved
 *  - Reset action: resets moves to 0 without changing bottles
 *  - Solve action: placeholder, can return state unchanged
 *  - Must never mutate input state
 *  - Must return valid GameState
 */
export interface Update {
  (msg: Msg, state: GameState): GameState;
}

/**
 * View function signature
 * Takes a GameState and returns a renderable representation
 */
export interface View {
  (state: GameState): string | object;
}

/**
 * Subscription/effect handler signature
 * Could be used for time-based updates or AI moves
 */
export interface Subscription {
  (state: GameState): Msg | null;
}

// ============================================================================
// Initial State Generation
// ============================================================================

/**
 * Signature for generating initial bottles from a seed
 * 
 * Constraints:
 *  - Must produce 10 filled bottles with 6 colors (2 of each)
 *  - Must produce 2 empty bottles
 *  - Order determined by seed for reproducibility
 */
export interface GenerateInitialBottles {
  (seed: number): Bottles;
}

/**
 * Signature for finding a solvable state from timestamp
 * 
 * Algorithm:
 *  1. Start with seed = timestamp % 2^50
 *  2. Generate state from seed
 *  3. If isSolvable(state), return state
 *  4. Otherwise, seed = (seed + bigPrime) % 2^50
 *  5. Repeat with attempt limit (e.g., 1000)
 */
export interface FindSolvableState {
  (timestamp: number): Bottles;
}

/**
 * Signature for initializing game state from Unix timestamp (milliseconds)
 * 
 * Constraints:
 *  - Must accept Unix timestamp in milliseconds
 *  - Must use FindSolvableState to find initial configuration
 *  - Must return GameState with moves = 0, solved = false
 */
export interface InitGameState {
  (timestampMs: number): GameState;
}

/**
 * Constants for seed generation
 */
export interface SeedConstants {
  readonly bigPrime: 1000000007;
  readonly seedSpace: 1125899906842624; // 2^50
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Get all valid moves from current state
 * Returns list of (from, to) pairs where pour is possible
 */
export interface ValidMoves {
  (bottles: Bottles): ReadonlyArray<readonly [ValidBottleIndex, ValidBottleIndex]>;
}

/**
 * Render game state as string for display
 */
export interface RenderGameState {
  (state: GameState): string;
}

// ============================================================================
// Complete Implementation Contract
// ============================================================================

/**
 * Any implementation of the Water Sort game must provide all of these functions.
 * This interface ensures type safety across the entire application.
 */
export interface WaterSortGame {
  // Logic functions
  readonly isEmptyBottle: IsEmptyBottle;
  readonly isFullBottle: IsFullBottle;
  readonly topColor: TopColor;
  readonly countTopColor: CountTopColor;
  readonly availableSpace: AvailableSpace;
  readonly canPour: CanPour;
  readonly pour: Pour;
  readonly isSolved: IsSolved;
  readonly isSolvable: IsSolvable;

  // Elm architecture
  readonly update: Update;
  readonly view: View;
  readonly subscription?: Subscription;

  // State initialization
  readonly generateInitialBottles: GenerateInitialBottles;
  readonly findSolvableState: FindSolvableState;
  readonly initGameState: InitGameState;

  // Utilities
  readonly validMoves: ValidMoves;
  readonly renderGameState: RenderGameState;

  // Constants
  readonly seedConstants: SeedConstants;
}

// ============================================================================
// Type Guards and Helpers
// ============================================================================

/**
 * Type guard to check if a value is a valid Color
 */
export function isColor(value: unknown): value is Color {
  return typeof value === 'string' && 
    ['red', 'blue', 'green', 'yellow', 'purple', 'orange'].includes(value);
}

/**
 * Type guard to check if a value is a valid Slot
 */
export function isSlot(value: unknown): value is Slot {
  return typeof value === 'object' && value !== null &&
    ('type' in value) &&
    (value.type === 'empty' || 
     (value.type === 'filled' && 'color' in value && isColor((value as any).color)));
}

/**
 * Type guard to check if a value is a valid Bottle (4 slots)
 */
export function isBottle(value: unknown): value is Bottle {
  return Array.isArray(value) &&
    value.length === 4 &&
    value.every(isSlot);
}

/**
 * Type guard to check if a value is valid Bottles (12 bottles)
 */
export function isBottles(value: unknown): value is Bottles {
  return Array.isArray(value) &&
    value.length === 12 &&
    value.every(isBottle);
}

/**
 * Type guard to check if a value is a valid GameState
 */
export function isGameState(value: unknown): value is GameState {
  return typeof value === 'object' && value !== null &&
    'bottles' in value && isBottles((value as any).bottles) &&
    'moves' in value && typeof (value as any).moves === 'number' &&
    'solved' in value && typeof (value as any).solved === 'boolean';
}

/**
 * Type guard to check if action is a valid PourAction
 */
export function isPourAction(value: unknown): value is PourAction {
  return typeof value === 'object' && value !== null &&
    'type' in value && (value as any).type === 'pour' &&
    'from' in value && typeof (value as any).from === 'number' &&
    'to' in value && typeof (value as any).to === 'number';
}

/**
 * Type guard to check if action is a valid Msg
 */
export function isMsg(value: unknown): value is Msg {
  return typeof value === 'object' && value !== null &&
    'type' in value && 
    ['pour', 'reset', 'solve'].includes((value as any).type);
}
