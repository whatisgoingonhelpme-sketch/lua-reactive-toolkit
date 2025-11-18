# Lua Reactive Toolkit

A tiny reactive system for Lua inspired by Solid.js/Svelte signals.  
Create **signals**, wire up **effects**, define **computed** values, and **watch** them update—no frameworks required.

## Features

- **Signals** – state containers with `getter` and `setter`.
- **Effects** – functions that automatically re-run when their dependencies change.
- **Computed** – derived state, cached and recalculated only when inputs change.
- **Watchers** – observe signal changes with old/new values.
- **Batching** – merge rapid updates so effects run only once per tick.
- **Peek** – read signals without tracking dependencies.

## Getting Started

1. Clone or download this repo.
2. Ensure you have a Lua 5.1–5.4 interpreter installed.
3. Run the demo to see reactive updates in action:

   ```bash
   lua demo.lua
