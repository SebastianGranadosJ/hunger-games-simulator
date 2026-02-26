# 🏹 Hunger Games Simulator

A Hunger Games simulator powered by an AI narrative agent built with LangChain and Groq. Register your own tributes and watch as the AI generates dramatic, story-driven events for each period of the Games — until only one survivor remains.

---

## Features

- AI-generated narrative events for every period (Bloodbath, Day, Night)
- Full game state tracking: kills, inventories, injuries, alliances, and more
- Structured output ensures narrative consistency and proper state management
- Multilanguage support — generate narratives in any language
- Period-by-period JSON logs saved automatically for debugging and replay
- Console interface to register tributes, advance periods, and read event history
- Default tribute set for quick testing

---

## Tech Stack

- **Python 3.10+**
- **LangChain** — agent orchestration
- **Groq API** (llama-3.3-70b-versatile) — LLM backend
- **Pydantic** — data modeling and structured output validation

---

## Project Structure

```
hunger-games-simulator/
│
├── main.py                 # Entry point
├── console_manager.py      # Console interface
├── simulator.py            # Simulation orchestration
├── agent_admin.py          # LLM agent connection and prompt building
├── tribute_admin.py        # Tribute state management
├── event_admin.py          # Event history management
├── models.py               # Pydantic models (Tribute, Event, Item, etc.)
├── prompts.py              # System prompt
├── simulation_logs/        # Auto-generated JSON logs per period
└── .env                    # API keys (not committed)
```

---

## Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/hunger-games-simulator.git
cd hunger-games-simulator
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Create a `.env` file with your Groq API key:
```
GROQ_API_KEY=your_api_key_here
```

4. Run the simulator:
```bash
python main.py
```

---

## Usage

On startup, the console will guide you through:

1. **Tribute registration** — enter tributes manually or load a default set for testing
2. **Language selection** — choose English, Spanish, or any custom language
3. **Main menu** — advance the simulation one period at a time, run it to completion, or browse the event history

---

## How It Works

The simulator separates responsibilities between the AI and your code:

- The **LLM** decides what happens narratively: who fights, who dies, who finds items
- Your **code** applies those decisions deterministically to the game state

Each period, the agent receives the current list of alive tributes (with their inventories, kill counts, and state notes) and the recent event history. It returns a structured `EventBatch` object, which the simulator uses to update kills, mark tributes as dead, add or remove items, and log state notes.

---

## Simulation Logs

After each period, a JSON file is saved to `simulation_logs/` with the format:

```
bloodbath_0.json
day_1.json
night_1.json
day_2.json
...
```

Each file contains the alive tributes at the start of the period and all events that occurred, making it easy to trace exactly what the AI generated and how the state changed.

---

## Notes

- The Groq free tier has a daily token limit of 100,000 tokens. Long simulations with many tributes may hit this limit.
- The quality of the narrative depends heavily on the system prompt. See `prompts.py` to adjust behavior, pacing, death frequency, and tone.
