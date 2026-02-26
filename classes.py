from pydantic import BaseModel
from enum import Enum

class EventType(Enum):
    BLOODBATH = "bloodbath"
    DAY = "day"
    NIGHT = "night"

class Item(BaseModel):
    id: int | None = None
    name: str

class Tribute(BaseModel):
    id: int | None = None
    name: str
    gender: str
    district: int
    items: list[Item] = []
    state_notes: list[str] = []
    is_alive: bool
    kills: int

class ItemEvent(BaseModel):
    tribute_id: str
    item_name: str

class StateNote(BaseModel):
    tribute_id: str
    note: str

class Event(BaseModel):
    related_tributes: list[str]
    event_type: EventType                   # Type of event: bloodbath, day or night
    period_number: int                      # Day or night number (e.g: Day 1, Night 1, Day 2...)
    narrative: str                          # The narrative text of the event
    killed_tribute_id: list[str] | None     # If there was a death, who died
    killer_tribute_id: list[str] | None     # Who killed (if applicable)
    items_added: list[ItemEvent]            # [{tribute_id, item_name}, ...]
    items_removed: list[ItemEvent]          # [{tribute_id, item_name}, ...]
    state_notes: list[StateNote]            # [{tribute_id, note}, ...]

class EventBatch(BaseModel):
    events: list[Event]