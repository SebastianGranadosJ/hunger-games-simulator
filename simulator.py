from pydantic import BaseModel, PrivateAttr
from classes import Tribute
from tribute_admin import TributeAdmin
from event_admin import EventAdmin
from agent_admin import AgentAdmin
from classes import EventBatch, EventType, Item

import json
import os

class Simulator(BaseModel):
    tributes: list[Tribute]
    logs_dir: str = "simulation_logs"
    language: str = "English"

    _tribute_admin: TributeAdmin = PrivateAttr()
    _event_admin: EventAdmin = PrivateAttr()
    _agent_admin: AgentAdmin = PrivateAttr()

    _current_period: int = PrivateAttr(default=0)
    _current_event_type: EventType = PrivateAttr(default=EventType.BLOODBATH)

    def model_post_init(self, __context):
        """Initializes the admin instances and registers the tributes."""
        self._tribute_admin = TributeAdmin()
        self._tribute_admin.add_tributes(self.tributes)

        self._event_admin = EventAdmin()
        self._agent_admin = AgentAdmin(language=self.language)

        os.makedirs(self.logs_dir, exist_ok=True)

    # -------------------------
    # Period Logic
    # -------------------------

    def _advance_period(self):
        """Advances the simulation to the next period."""
        if self._current_event_type == EventType.BLOODBATH:
            self._current_event_type = EventType.DAY
            self._current_period = 1
        elif self._current_event_type == EventType.DAY:
            self._current_event_type = EventType.NIGHT
        else:
            self._current_event_type = EventType.DAY
            self._current_period += 1

    def _is_simulation_over(self) -> bool:
        """Returns True if only one tribute remains alive."""
        return len(self._tribute_admin.get_all_tributes(only_alive=True)) <= 1

    def get_winner(self) -> Tribute | None:
        """Returns the last surviving tribute, or None if the simulation is not over."""
        alive = self._tribute_admin.get_all_tributes(only_alive=True)
        return alive[0] if len(alive) == 1 else None

    # -------------------------
    # Logging
    # -------------------------

    def _save_period_log(self, batch: EventBatch):
        """Saves the events of the current period to a JSON file."""
        filename = f"{self._current_event_type.value}_{self._current_period}.json"
        filepath = os.path.join(self.logs_dir, filename)

        data = {
            "period_number": self._current_period,
            "event_type": self._current_event_type.value,
            "alive_tributes": [
                {"id": t.id, "name": t.name, "kills": t.kills, "items": [i.name for i in t.items]}
                for t in self._tribute_admin.get_all_tributes(only_alive=True)
            ],
            "events": [
                json.loads(event.model_dump_json())
                for event in batch.events
            ]
        }

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

    # -------------------------
    # Event Application
    # -------------------------

    def _apply_events(self, batch: EventBatch):
        """Applies all state changes from a batch of events to the game state."""
        for event in batch.events:

            for item_event in event.items_added:
                item = Item(name=item_event.item_name)
                self._tribute_admin.add_item_to_tribute(int(item_event.tribute_id), item)

            for item_event in event.items_removed:
                self._tribute_admin.remove_item_from_tribute(int(item_event.tribute_id), item_event.item_name)

            for state_note in event.state_notes:
                self._tribute_admin.add_state_note(int(state_note.tribute_id), state_note.note)

            if event.killed_tribute_id:
                for tribute_id in event.killed_tribute_id:
                    self._tribute_admin.mark_as_dead(int(tribute_id))

            if event.killer_tribute_id:
                for tribute_id in event.killer_tribute_id:
                    self._tribute_admin.increase_kills(int(tribute_id))

            self._event_admin.add_event(event)

    # -------------------------
    # Simulation Flow
    # -------------------------

    def run_period(self) -> EventBatch | None:
        """Generates and applies events for the current period, then advances to the next one."""
        if self._is_simulation_over():
            print(f"The simulation is already over. Winner: {self.get_winner().name}")
            return None

        alive_tributes = self._tribute_admin.get_all_tributes(only_alive=True)
        past_events = self._event_admin.get_recent_events(self._current_period)
        batch = self._agent_admin.generate_events(
            period_number=self._current_period,
            event_type=self._current_event_type,
            alive_tributes=alive_tributes,
            past_events=past_events
        )

        if batch:
            self._save_period_log(batch)
            self._apply_events(batch)
            self._advance_period()

        return batch

    def run_full_simulation(self) -> Tribute | None:
        """Runs the simulation from start to finish and returns the winner."""
        while not self._is_simulation_over():
            self.run_period()

        winner = self.get_winner()
        if winner:
            print(f"The winner of the Hunger Games is: {winner.name} from District {winner.district}!")
        return winner
    
    def get_event_admin(self) -> EventAdmin:
        """Returns the event admin instance."""
        return self._event_admin