from simulator import Simulator
from classes import EventBatch, EventType, Tribute, Event


class ConsoleManager:
    def __init__(self):
        self._simulator: Simulator | None = None

    # -------------------------
    # Display Helpers
    # -------------------------

    def _print_separator(self):
        print("\n" + "=" * 60 + "\n")

    def _print_event(self, event: Event):
        period_label = f"{event.event_type.value.upper()} {event.period_number}"
        print(f"[{period_label}]")
        print(event.narrative)
        if event.killed_tribute_id:
            print(f"  ☠ Eliminated: {', '.join(event.killed_tribute_id)}")
        print()

    def _print_batch(self, batch: EventBatch):
        for event in batch.events:
            self._print_event(event)

    # -------------------------
    # Setup
    # -------------------------

    def _register_tributes(self) -> list[Tribute]:
        tributes = []
        print("Enter tribute details. Type 'done' as name when finished.\n")

        while True:
            name = input("Tribute name: ").strip()
            if name.lower() == "done":
                if len(tributes) < 2:
                    print("You need at least 2 tributes to start the simulation.")
                    continue
                break

            gender = input("Gender (M/F): ").strip()
            
            while True:
                try:
                    district = int(input("District (1-12): ").strip())
                    if 1 <= district <= 12:
                        break
                    print("District must be between 1 and 12.")
                except ValueError:
                    print("Please enter a valid number.")

            tributes.append(Tribute(
                name=name,
                gender=gender,
                district=district,
                is_alive=True,
                kills=0
            ))
            print(f"  ✓ {name} from District {district} registered.\n")

        return tributes


    # -------------------------
    # Simulation Controls
    # -------------------------

    def _read_events_menu(self):
        if self._simulator is None:
            print("No simulation running.")
            return

        print("\nRead events by:")
        print("  [1] Current period")
        print("  [2] Specific period")
        print("  [3] Specific tribute")
        print("  [4] All kill events")
        print("  [5] All events")
        print("  [0] Back")

        choice = input("\nOption: ").strip()

        event_admin = self._simulator.get_event_admin()

        if choice == "1":
            period = self._simulator._current_period
            event_type = self._simulator._current_event_type
            events = event_admin.get_events_by_period(period, event_type)
            for e in events:
                self._print_event(e)

        elif choice == "2":
            try:
                period = int(input("Period number: ").strip())
                print("  [1] Day  [2] Night  [3] Bloodbath")
                t = input("Type: ").strip()
                type_map = {"1": EventType.DAY, "2": EventType.NIGHT, "3": EventType.BLOODBATH}
                event_type = type_map.get(t)
                if not event_type:
                    print("Invalid type.")
                    return
                events = event_admin.get_events_by_period(period, event_type)
                for e in events:
                    self._print_event(e)
            except ValueError:
                print("Invalid input.")

        elif choice == "3":
            tribute_id = input("Tribute ID: ").strip()
            events = event_admin.get_events_by_tribute(tribute_id)
            for e in events:
                self._print_event(e)

        elif choice == "4":
            for e in event_admin.get_kill_events():
                self._print_event(e)

        elif choice == "5":
            for e in event_admin.get_all_events():
                self._print_event(e)

    # -------------------------
    # Main Loop
    # -------------------------

    def _load_default_tributes(self) -> list[Tribute]:
        """Loads a predefined set of tributes for testing purposes."""
        return [
            Tribute(name="Katniss Everdeen", gender="F", district=12, is_alive=True, kills=0),
            Tribute(name="Peeta Mellark",    gender="M", district=12, is_alive=True, kills=0),
            Tribute(name="Cato",             gender="M", district=2,  is_alive=True, kills=0),
            Tribute(name="Clove",            gender="F", district=2,  is_alive=True, kills=0),
            Tribute(name="Finnick Odair",    gender="M", district=4,  is_alive=True, kills=0),
            Tribute(name="Glimmer",          gender="F", district=1,  is_alive=True, kills=0),
            Tribute(name="Marvel",           gender="M", district=1,  is_alive=True, kills=0),
            Tribute(name="Rue",              gender="F", district=11, is_alive=True, kills=0),
        ]

    def run(self):
        print("\n" + "=" * 60)
        print("        WELCOME TO THE HUNGER GAMES SIMULATOR")
        print("=" * 60 + "\n")

        print("  [1] Register tributes manually")
        print("  [2] Load default tributes (testing)")
        choice = input("\nOption: ").strip()

        if choice == "2":
            tributes = self._load_default_tributes()
            print(f"\n  ✓ {len(tributes)} default tributes loaded.")
        else:
            tributes = self._register_tributes()

        self._print_separator()

        print("Select the language for the simulation narrative:")
        print("  [1] English")
        print("  [2] Spanish")
        print("  [3] Custom")
        lang_choice = input("\nOption: ").strip()

        if lang_choice == "1":
            language = "English"
        elif lang_choice == "2":
            language = "Spanish"
        elif lang_choice == "3":
            language = input("Enter language: ").strip()
        else:
            print("Invalid option, defaulting to English.")
            language = "English"

        self._print_separator()

        self._simulator = Simulator(tributes=tributes, language=language)
        print(f"Simulation initialized with {len(tributes)} tributes in {language}.\n")

        while True:
            print("=" * 60)
            print("MAIN MENU")
            print("  [1] Advance one period")
            print("  [2] Run full simulation")
            print("  [3] Read events")
            print("  [0] Exit")
            print("=" * 60)

            choice = input("\nOption: ").strip()

            if choice == "1":
                self._print_separator()
                batch = self._simulator.run_period()
                if batch:
                    self._print_batch(batch)
                winner = self._simulator.get_winner()
                if winner:
                    self._print_separator()
                    print(f"🏆 THE WINNER IS {winner.name.upper()} FROM DISTRICT {winner.district}!")

            elif choice == "2":
                self._print_separator()
                winner = self._simulator.run_full_simulation()
                if winner:
                    print(f"🏆 THE WINNER IS {winner.name.upper()} FROM DISTRICT {winner.district}!")

            elif choice == "3":
                self._read_events_menu()

            elif choice == "0":
                print("\nMay the odds be ever in your favor. Goodbye.")
                break

            else:
                print("Invalid option.")