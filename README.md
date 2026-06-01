# Maze Runner: Retro Arcade Escape Protocol 🎮

A low-level **16-bit x86 Assembly language** retro-arcade maze game engineered completely for real-mode DOS environments and optimized for the **EMU8086** emulator interface. This project implements a structural game loop, dynamic split-screen rendering, direct coordinate state validation, and low-level BIOS/DOS hardware interrupts.

---

## 🚀 Core Gameplay & Engine Features

- **Centralized State Machine:** Controlled cleanly via an 8-bit `current_state` router that dynamically directs transitions across the Main Menu, Active Maze Mission, Protocols Manual, and Victory Terminal.
- **Mode 13h High-Color Graphics:** Discards standard plain text mode to initialize an optimized $320 \times 200$ 256-color pixel canvas via BIOS `INT 10h` (`AX = 0013h`).
- **Stylized Cyberpunk Palette:** Features a dedicated color mapping scheme:
  - **Walls:** Solid, vibrant block tiles (`0DBh`) rendered in *Neon Cyber Cyan* (`03h`).
  - **Player Avatar:** An *Emerald Green* arcade smiling face character (`02h`) that alters execution behavior dynamically.
  - **Goal Nodes:** A *Golden Yellow* Pi symbol (`0E3h` / $\pi$) serving as the terminal data extraction point.
  - **Path Trails:** Tracks travel footprints by replacing cleared tiles with subtle tracking dots (`.`).
- **Selective Overwrite Vector Engine (Flicker-Free):** Prevents standard screen-wipe performance bottlenecks by targeting and restoring *only* the single coordinate index the player just vacated instead of redrawing the entire map grid.

---

## 🛠️ System Architecture & Memory Structures

The engine maps out custom grid bounds via a flat, multi-row matrix array processed mathematically inside the processor registers.

- **Coordinate Bounds:** 400-byte structural grid matrix mapped across a $20 \times 20$ layout block.
- **Flat Index Formula:** To track horizontal and vertical boundaries without dedicated game engines, target indexes are calculated dynamically inside individual subroutines via register multiplication and offset division:
  $$\text{Memory Offset} = (Y \times \text{Maze Width}) + X$$

---

## 🧠 Breakdown of Main Functions & Subroutines

### 🖥️ 1. Console Layout & Text Utilities
- `CLEAR_SCREEN`: Invokes `INT 10h / AX=0003h` to flush the video buffer and smoothly swap system execution layers.
- `SET_CURSOR`: Manipulates row (`DH`) and column (`DL`) indicators via `INT 10h / AH=02h`.
- `PRINT_COLOR_STR`: Iterates through character segments until striking a string termination byte (`$`). Reads cursor offsets via `AH=03h`, applies specific 8-bit visual attributes using `AH=09h`, and moves formatting boundaries forward incrementally.

### 🕹️ 2. Screen Renderers & Map Generators
- `DRAW_MAZE`: Loops continuously over the 400-byte tracking array. Utilizes the hardware `DIV` operation against `maze_width` ($20$) to extract exact row/column bounds and positions glowing boundaries wherever wall constants are met.
- `DRAW_PLAYER` & `DRAW_TARGET`: Maps coordinates straight to screen buffers to draw the player avatar and the extraction node ($\pi$).
- `ERASE_PLAYER`: Checks the player's last coordinate byte position in memory. If it was a standard walkway, it clears it to black; if it was already stepped on, it leaves a tracking dot (`.`). This ensures high-performance frame-rate execution.

### 📊 3. Interactive Split-Screen HUD
- `DRAW_UI`: Constructs a dual-panel layout. Isolates a vertical framing split at column index 20 from row 0 to 22 using a stack-safe loop (`push cx` / `pop cx`) to prevent internal BIOS interrupts from corrupting runtime loop parameters. It projects active metrics (steps taken, coordinates, bypass modes) directly onto the right column panel.
- `DISPLAY_MOVES` & `PRINT_WIN_MOVES`: Pulls raw binary 16-bit movement metrics and isolates individual decimal digits using iterative division (base-10) to render ASCII values on-screen.
- `PRINT_PERFORMANCE_RATING`: Evaluates final efficiency metrics upon landing on the extraction node:
  - **$\le 50$ moves:** Class-A Cyber Escapist (Green text)
  - **$51$ to $100$ moves:** Class-B Adroit Runner (Cyan text)
  - **$> 100$ moves:** Class-C Casual Survivor (Magenta text)

### ⌨️ 4. Input Trapping & Collision Engine
- **Keyboard Vector Reading (`INT 16h / AH=00h`):** Halts loop cycles until a key is caught. Traps extended hardware scan-codes in the high byte (`AH`) to track standard arrow key matrices:
  - **Up:** `48h` | **Down:** `50h` | **Left:** `4Bh` | **Right:** `4Dh`
- **Collision Checking:** Pre-evaluates adjacent array destinations. Rejects any coordinate updating if the target byte evaluates to a wall (`1`), unless the player toggles the *Spacebar Bypass Protocol* (Superman mode).

---

## 🎛️ Low-Level Hardware Interrupts Used

| Interrupt Hook | Sub-Service Configuration (`AH`) | System Operational Objective |
| :--- | :--- | :--- |
| **`INT 10h`** | `AH = 00h` / `AL = 13h` | Initializing Mode 13h Graphics ($320 \times 200$, 256 Colors) |
| **`INT 10h`** | `AH = 02h` | Directing hardware terminal cursor coordinates (`DH`=Row, `DL`=Col) |
| **`INT 10h`** | `AH = 03h` | Querying real-time cursor indicators and layout rows |
| **`INT 10h`** | `AH = 09h` | Printing custom character fonts with dedicated 8-bit color attributes |
| **`INT 16h`** | `AH = 00h` | Direct keyboard buffer read (Extracts high-byte hardware scan codes) |
| **`INT 21h`** | `AH = 4Ch` | Standard DOS termination (Returns system control back to the terminal OS) |

---

## ⚙️ How to Compile and Run

1. Download and launch the **EMU8086** (Microprocessor Emulator) application workspace.
2. Clone this repository or open the project's source file (`.asm`) directly inside the emulator text view.
3. Click the **Compile** button on the top taskbar to resolve segment boundaries.
4. Hit **Run** inside the emulator virtual environment to start the game!
