# Hunger Games Simulator

A Hunger Games simulator powered by an AI narrative agent built with LangChain and Groq. Register your own tributes and watch as the AI generates dramatic, story-driven events for each period of the Games — until only one survivor remains.

---

## Features

- AI-generated narrative events for every period (Bloodbath, Day, Night)
- Full game state tracking: kills, inventories, injuries, alliances, and more
- Structured output ensures narrative consistency and proper state management
- Multilanguage support — generate narratives in any language
- Period-by-period JSON logs saved automatically for debugging and replay
- REST API (FastAPI) for programmatic control
- Default tribute set for quick testing

---

## Tech Stack

- **Python 3.10+**
- **LangChain** — agent orchestration
- **Groq API** (llama-3.3-70b-versatile) — LLM backend
- **Pydantic** — data modeling and structured output validation
- **FastAPI + Uvicorn** — REST API server

---

## Project Structure

```
hunger-games-simulator/
│
├── api.py                  # FastAPI entry point (REST API)
├── state.py                # Global simulator state
├── main.py                 # Legacy console entry point
├── console_manager.py      # Console interface
├── simulator.py            # Simulation orchestration
├── agent_admin.py          # LLM agent connection and prompt building
├── tribute_admin.py        # Tribute state management
├── event_admin.py          # Event history management
├── classes.py              # Pydantic models (Tribute, Event, Item, etc.)
├── prompts.py              # System prompt
├── simulation_logs/        # Auto-generated JSON logs per period
├── HungerGamesSimulator.postman_collection.json
└── .env                    # API keys (not committed)
```

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/your-username/hunger-games-simulator.git
cd hunger-games-simulator
```

### 2. Create and activate the conda environment

```bash
conda create -n llm_env python=3.11
conda activate llm_env
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
pip install fastapi "uvicorn[standard]"
```

### 4. Set up environment variables

Create a `.env` file in the project root:

```
GROQ_API_KEY=your_api_key_here
```

---

## Running the API

```bash
conda activate llm_env
uvicorn api:app --reload
```

The server starts at `http://127.0.0.1:8000`.
Interactive docs (Swagger UI) are available at `http://127.0.0.1:8000/docs`.

---

## API Overview

The API is stateful and manages a single simulation instance in memory. The typical workflow is:

```
POST /simulation/start   →   POST /simulation/advance (repeat)   →   GET /simulation/winner
```

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/simulation/start` | Create a new simulation with custom or default tributes |
| POST | `/simulation/advance` | Run one period and get the generated event batch |
| GET | `/simulation/status` | Current period, phase, and alive tributes |
| GET | `/simulation/events` | Full event history with optional filters |
| GET | `/simulation/winner` | Returns the winner once the simulation is over |
| POST | `/simulation/reset` | Destroy the current simulation and clear state |

For full request/response details, query parameters, and examples, see [API_REFERENCE.md](API_REFERENCE.md).

You can also import `HungerGamesSimulator.postman_collection.json` directly into Postman to run all endpoints with pre-filled examples.

---

## How It Works

The simulator separates responsibilities between the AI and the application code:

- The **LLM** decides what happens narratively: who fights, who dies, who finds items
- The **application** applies those decisions deterministically to the game state

Each period, the agent receives the current list of alive tributes (with their inventories, kill counts, and state notes) and the recent event history. It returns a structured `EventBatch`, which the simulator uses to update kills, mark tributes as dead, add or remove items, and log state notes.

---

## Simulation Logs

After each period, a JSON file is saved to `simulation_logs/`:

```
bloodbath_0.json
day_1.json
night_1.json
day_2.json
...
```

Each file contains the alive tributes at the start of the period and all events that occurred.

---

## Notes

- The Groq free tier has a daily token limit of 100,000 tokens. Long simulations with many tributes may hit this limit.
- The quality of the narrative depends heavily on the system prompt. See `prompts.py` to adjust behavior, pacing, death frequency, and tone.
- The API is designed for local single-user use and does not handle concurrent requests.
