from pydantic import BaseModel
from classes import Event, EventType
from pydantic import BaseModel


class EventAdmin(BaseModel):
    events: list[Event] = []

    def add_event(self, event: Event) -> bool:
        """Adds a new event to the simulation history."""
        try:
            self.events.append(event)
            return True
        except Exception:
            return False

    def get_events_by_type(self, event_type: EventType) -> list[Event]:
        """Returns all events that match a specific event type."""
        return [e for e in self.events if e.event_type == event_type]

    def get_events_by_period(self, period_number: int, event_type: EventType) -> list[Event]:
        """Returns all events that occurred during a specific period and type."""
        return [e for e in self.events if e.period_number == period_number and e.event_type == event_type]

    def get_all_events(self) -> list[Event]:
        """Returns the complete list of events registered in the simulation."""
        return self.events

    def get_events_by_tribute(self, tribute_id: str) -> list[Event]:
        """Returns all events in which a specific tribute was involved."""
        return [e for e in self.events if tribute_id in e.related_tributes]

    def get_kill_events(self) -> list[Event]:
        """Returns all events that resulted in the death of one or more tributes."""
        return [e for e in self.events if e.killed_tribute_id]
    
    def get_recent_events(self, batches_back: int = 2) -> list[Event]:
        """Returns events from the last N periods, prioritizing night over day."""
        if not self.events:
            return []

        # Get the highest period number available
        max_period = max(e.period_number for e in self.events)
        
        collected = []
        period = max_period
        batches_found = 0

        while period >= 0 and batches_found < batches_back:
            # Try night first, then day, then bloodbath
            for event_type in [EventType.NIGHT, EventType.DAY, EventType.BLOODBATH]:
                period_events = self.get_events_by_period(period, event_type)
                if period_events:
                    collected = period_events + collected
                    batches_found += 1
                    break
            period -= 1

        return collected