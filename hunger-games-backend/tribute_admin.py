from pydantic import BaseModel
from classes import Tribute, Item
from pydantic import BaseModel, PrivateAttr

class TributeAdmin(BaseModel):
    tributes: list[Tribute] = []

    _tribute_id_counter: int = PrivateAttr(default=1)
    _item_id_counter: int = PrivateAttr(default=1)

    def add_tributes(self, new_tributes: list[Tribute]) -> bool:
        """Assigns sequential IDs using a counter and adds tributes to the list."""
        try:
            for tribute in new_tributes:
                tribute.id = self._tribute_id_counter
                self.tributes.append(tribute)
                self._tribute_id_counter += 1
            return True
        except Exception:
            return False

    def mark_as_dead(self, tribute_id: int) -> bool:
        """Searches for a tribute by ID and changes their status to deceased."""
        tribute = next((t for t in self.tributes if t.id == tribute_id), None)
        if tribute and tribute.is_alive:
            tribute.is_alive = False
            tribute.state_notes.append("Eliminated from the competition.")
            return True
        return False

    def add_item_to_tribute(self, tribute_id: int, item: Item) -> bool:
        """Assigns a counter-based ID to the item and gives it to the tribute."""
        tribute = next((t for t in self.tributes if t.id == tribute_id), None)
        
        if tribute and tribute.is_alive:
            item.id = self._item_id_counter
            tribute.items.append(item)
            self._item_id_counter += 1
            return True
        return False
    
    def remove_item_from_tribute(self, tribute_id: int, item_name: str) -> bool:
        """Removes an item from a tribute's inventory by item name."""
        tribute = self.get_tribute_by_id(tribute_id)
        if not tribute:
            return False
        
        item = next((i for i in tribute.items if i.name.lower() == item_name.lower()), None)
        if not item:
            return False
        
        tribute.items.remove(item)
        return True
    
    def get_tribute_by_id(self, tribute_id: int) -> Tribute | None:
        """
        Retrieves a specific tribute from the list by its unique ID.
        """
        return next((t for t in self.tributes if t.id == tribute_id), None)

    def get_all_tributes(self, only_alive: bool = False) -> list[Tribute]:
        """
        Returns the complete list of tributes registered in the simulation.
        """
        if only_alive:
            return [t for t in self.tributes if t.is_alive]
        return self.tributes
    
    
    def add_state_note(self, tribute_id: int, note: str) -> bool:
        """
        Adds a new status update or event description to a tribute's history.
        """
        tribute = self.get_tribute_by_id(tribute_id)
        if tribute:
            tribute.state_notes.append(note)
            return True
        return False

    def get_tribute_notes(self, tribute_id: int) -> list[str] | None:
        """
        Retrieves the full history of status notes for a specific tribute.
        """
        tribute = self.get_tribute_by_id(tribute_id)
        return tribute.state_notes if tribute else None

    def increase_kills(self, tribute_id: int) -> bool:
        """
        Increments the kill counter for a tribute by 1.
        """
        tribute = self.get_tribute_by_id(tribute_id)
        if tribute and tribute.is_alive:
            tribute.kills += 1
            return True
        return False