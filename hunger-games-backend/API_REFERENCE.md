# API Reference — Hunger Games Simulator

Base URL: `http://127.0.0.1:8000`

All request bodies must use `Content-Type: application/json`.
All responses are JSON.
Error responses follow the format `{ "detail": "error message" }` with HTTP status 400.

---

## Table of Contents

- [POST /simulation/start](#post-simulationstart)
- [POST /simulation/advance](#post-simulationadvance)
- [GET /simulation/status](#get-simulationstatus)
- [GET /simulation/events](#get-simulationevents)
- [GET /simulation/winner](#get-simulationwinner)
- [POST /simulation/reset](#post-simulationreset)
- [Data Models](#data-models)

---

## POST /simulation/start

Creates and initializes a new simulation. The simulation is kept in memory and persists across requests until `/simulation/reset` is called.

**Returns 400** if a simulation is already running.

### Request Body

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `use_default_tributes` | boolean | No | `false` | If `true`, ignores the `tributes` field and loads 8 predefined tributes |
| `tributes` | array of [TributeInput](#tributeinput) | Conditional | — | Required when `use_default_tributes` is `false`. Minimum 2 tributes |
| `language` | string | No | `"English"` | Language for the AI-generated narrative (e.g. `"Spanish"`, `"French"`) |

### Default Tributes

When `use_default_tributes: true`, the following tributes are loaded:

| Name | Gender | District |
|------|--------|----------|
| Katniss Everdeen | F | 12 |
| Peeta Mellark | M | 12 |
| Cato | M | 2 |
| Clove | F | 2 |
| Finnick Odair | M | 4 |
| Glimmer | F | 1 |
| Marvel | M | 1 |
| Rue | F | 11 |

### Example — Default Tributes

```http
POST /simulation/start
Content-Type: application/json

{
  "use_default_tributes": true,
  "language": "English"
}
```

### Example — Custom Tributes

```http
POST /simulation/start
Content-Type: application/json

{
  "use_default_tributes": false,
  "language": "Spanish",
  "tributes": [
    { "name": "Katniss Everdeen", "gender": "F", "district": 12 },
    { "name": "Peeta Mellark",    "gender": "M", "district": 12 },
    { "name": "Cato",             "gender": "M", "district": 2  },
    { "name": "Clove",            "gender": "F", "district": 2  }
  ]
}
```

### Response — 200 OK

```json
{
  "message": "Simulation started with 8 tributes.",
  "language": "English",
  "tribute_count": 8
}
```

### Response — 400 Bad Request

```json
{ "detail": "A simulation is already running. Call /simulation/reset first." }
```

```json
{ "detail": "At least 2 tributes are required when use_default_tributes is false." }
```

---

## POST /simulation/advance

Runs one period of the simulation. The period sequence is:

```
Bloodbath → Day 1 → Night 1 → Day 2 → Night 2 → ...
```

The AI agent generates a batch of narrative events for the period. Those events are applied to the game state (kills, items, state notes) before the response is returned.

**Returns 400** if no simulation is running or the simulation is already over.

### Request Body

None.

### Example

```http
POST /simulation/advance
```

### Response — 200 OK

```json
{
  "batch": {
    "events": [
      {
        "related_tributes": ["1", "3"],
        "event_type": "bloodbath",
        "period_number": 0,
        "narrative": "Cato sprints to the Cornucopia and seizes a sword before Katniss can reach it. She retreats into the treeline with nothing but a backpack.",
        "killed_tribute_id": null,
        "killer_tribute_id": null,
        "items_added": [
          { "tribute_id": "3", "item_name": "Sword" },
          { "tribute_id": "1", "item_name": "Backpack" }
        ],
        "items_removed": [],
        "state_notes": [
          { "tribute_id": "1", "note": "Retreated to the forest. No weapons." }
        ]
      }
    ]
  },
  "is_over": false,
  "winner": null
}
```

When the simulation ends on this advance call:

```json
{
  "batch": { "events": [ ... ] },
  "is_over": true,
  "winner": {
    "id": 1,
    "name": "Katniss Everdeen",
    "gender": "F",
    "district": 12,
    "items": [ { "id": 3, "name": "Bow" } ],
    "state_notes": [ "Wounded in the left leg." ],
    "is_alive": true,
    "kills": 2
  }
}
```

### Response — 400 Bad Request

```json
{ "detail": "No simulation is currently running." }
```

```json
{ "detail": "The simulation is already over." }
```

---

## GET /simulation/status

Returns a snapshot of the current simulation state.

### Example

```http
GET /simulation/status
```

### Response — 200 OK

```json
{
  "period_number": 1,
  "event_type": "day",
  "alive_tributes": [
    {
      "id": 1,
      "name": "Katniss Everdeen",
      "gender": "F",
      "district": 12,
      "items": [ { "id": 3, "name": "Bow" } ],
      "state_notes": [],
      "is_alive": true,
      "kills": 0
    },
    {
      "id": 3,
      "name": "Cato",
      "gender": "M",
      "district": 2,
      "items": [ { "id": 1, "name": "Sword" } ],
      "state_notes": [],
      "is_alive": true,
      "kills": 1
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `period_number` | integer | Current period number (0 = Bloodbath, 1+ = Day/Night cycles) |
| `event_type` | string | One of `"bloodbath"`, `"day"`, `"night"` |
| `alive_tributes` | array of [Tribute](#tribute) | All tributes currently alive |

### Response — 400 Bad Request

```json
{ "detail": "No simulation is currently running." }
```

---

## GET /simulation/events

Returns the event history of the current simulation. All query parameters are optional and can be combined — filters are applied in sequence (AND logic).

### Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `period_number` | integer | Filter by period number (0 = Bloodbath, 1, 2, …) |
| `event_type` | string | Filter by phase: `bloodbath`, `day`, or `night` |
| `tribute_id` | string | Filter events where this tribute ID appears in `related_tributes` |
| `kills_only` | boolean | If `true`, return only events where at least one tribute was killed. Default: `false` |

### Examples

**All events:**
```http
GET /simulation/events
```

**Only kill events:**
```http
GET /simulation/events?kills_only=true
```

**All events from Night 1:**
```http
GET /simulation/events?period_number=1&event_type=night
```

**Kill events involving tribute with ID 3:**
```http
GET /simulation/events?tribute_id=3&kills_only=true
```

**All events from the Bloodbath:**
```http
GET /simulation/events?event_type=bloodbath
```

### Response — 200 OK

Returns an array of [Event](#event) objects.

```json
[
  {
    "related_tributes": ["2", "8"],
    "event_type": "night",
    "period_number": 1,
    "narrative": "Rue and Peeta form an unlikely alliance by the river, sharing food and warmth through the cold night.",
    "killed_tribute_id": null,
    "killer_tribute_id": null,
    "items_added": [],
    "items_removed": [],
    "state_notes": [
      { "tribute_id": "2", "note": "Allied with Rue." },
      { "tribute_id": "8", "note": "Allied with Peeta." }
    ]
  },
  {
    "related_tributes": ["3", "4"],
    "event_type": "night",
    "period_number": 1,
    "narrative": "Cato ambushes Clove in a moment of treachery, striking her down to eliminate a rival.",
    "killed_tribute_id": ["4"],
    "killer_tribute_id": ["3"],
    "items_added": [],
    "items_removed": [],
    "state_notes": []
  }
]
```

### Response — 400 Bad Request

```json
{ "detail": "No simulation is currently running." }
```

```json
{ "detail": "Invalid event_type. Valid values: bloodbath, day, night." }
```

---

## GET /simulation/winner

Returns the winning tribute once the simulation is over. Returns `null` if the simulation has not yet concluded.

### Example

```http
GET /simulation/winner
```

### Response — 200 OK (simulation in progress)

```json
null
```

### Response — 200 OK (simulation over)

```json
{
  "id": 1,
  "name": "Katniss Everdeen",
  "gender": "F",
  "district": 12,
  "items": [
    { "id": 3, "name": "Bow" },
    { "id": 7, "name": "Arrows" }
  ],
  "state_notes": [
    "Wounded in the left leg.",
    "Recovered after resting at the lake."
  ],
  "is_alive": true,
  "kills": 2
}
```

### Response — 400 Bad Request

```json
{ "detail": "No simulation is currently running." }
```

---

## POST /simulation/reset

Destroys the current simulation and clears the global state. Always succeeds regardless of whether a simulation is running.

After calling reset, a new simulation can be started with `/simulation/start`.

### Example

```http
POST /simulation/reset
```

### Response — 200 OK

```json
{ "message": "Simulation reset successfully." }
```

---

## Data Models

### TributeInput

Used only in the request body of `/simulation/start`.

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Full name of the tribute |
| `gender` | string | `"M"` or `"F"` |
| `district` | integer | District number (1–12 by convention) |

### Tribute

Full tribute object returned in responses. IDs are assigned sequentially starting from 1 when the simulation is started.

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer \| null | Unique tribute ID assigned at simulation start |
| `name` | string | Full name |
| `gender` | string | `"M"` or `"F"` |
| `district` | integer | District number |
| `items` | array of [Item](#item) | Current inventory |
| `state_notes` | array of string | Accumulated state notes (injuries, alliances, etc.) |
| `is_alive` | boolean | Whether the tribute is still in the simulation |
| `kills` | integer | Total confirmed kills |

### Item

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer \| null | Unique item ID assigned when added to inventory |
| `name` | string | Item name (e.g. `"Sword"`, `"Bow"`, `"Backpack"`) |

### Event

| Field | Type | Description |
|-------|------|-------------|
| `related_tributes` | array of string | IDs of all tributes involved in this event |
| `event_type` | string | `"bloodbath"`, `"day"`, or `"night"` |
| `period_number` | integer | Period in which this event occurred (0 = Bloodbath) |
| `narrative` | string | AI-generated narrative text describing the event |
| `killed_tribute_id` | array of string \| null | IDs of tributes who died in this event |
| `killer_tribute_id` | array of string \| null | IDs of tributes responsible for the kill(s) |
| `items_added` | array of [ItemEvent](#itemevent) | Items granted to tributes in this event |
| `items_removed` | array of [ItemEvent](#itemevent) | Items taken from tributes in this event |
| `state_notes` | array of [StateNote](#statenote) | Narrative state updates applied to specific tributes |

### EventBatch

| Field | Type | Description |
|-------|------|-------------|
| `events` | array of [Event](#event) | All events generated for a single period |

### ItemEvent

| Field | Type | Description |
|-------|------|-------------|
| `tribute_id` | string | ID of the tribute receiving or losing the item |
| `item_name` | string | Name of the item |

### StateNote

| Field | Type | Description |
|-------|------|-------------|
| `tribute_id` | string | ID of the tribute this note applies to |
| `note` | string | Descriptive note added to the tribute's history |

### AdvanceResponse

Returned by `POST /simulation/advance`.

| Field | Type | Description |
|-------|------|-------------|
| `batch` | [EventBatch](#eventbatch) | All events generated this period |
| `is_over` | boolean | `true` if the simulation ended after this period |
| `winner` | [Tribute](#tribute) \| null | The winning tribute, or `null` if still ongoing |
