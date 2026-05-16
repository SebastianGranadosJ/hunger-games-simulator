from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
from typing import Optional

import state
from classes import Tribute, EventBatch, EventType, Event
from simulator import Simulator

app = FastAPI(title="Hunger Games Simulator API")


# -------------------------
# Request / Response Models
# -------------------------

class TributeInput(BaseModel):
    name: str
    gender: str
    district: int


class StartRequest(BaseModel):
    tributes: list[TributeInput] | None = None
    language: str = "English"
    use_default_tributes: bool = False


class AdvanceResponse(BaseModel):
    batch: EventBatch
    is_over: bool
    winner: Tribute | None


class StatusResponse(BaseModel):
    period_number: int
    event_type: str
    alive_tributes: list[Tribute]


# -------------------------
# Helpers
# -------------------------

def _get_default_tributes() -> list[Tribute]:
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


# -------------------------
# Endpoints
# -------------------------

@app.post("/simulation/start")
def start_simulation(request: StartRequest):
    if state.simulator is not None:
        raise HTTPException(
            status_code=400,
            detail="A simulation is already running. Call /simulation/reset first."
        )

    if request.use_default_tributes:
        tributes = _get_default_tributes()
    else:
        if not request.tributes or len(request.tributes) < 2:
            raise HTTPException(
                status_code=400,
                detail="At least 2 tributes are required when use_default_tributes is false."
            )
        tributes = [
            Tribute(name=t.name, gender=t.gender, district=t.district, is_alive=True, kills=0)
            for t in request.tributes
        ]

    state.simulator = Simulator(tributes=tributes, language=request.language)
    return {
        "message": f"Simulation started with {len(tributes)} tributes.",
        "language": request.language,
        "tribute_count": len(tributes),
    }


@app.post("/simulation/advance", response_model=AdvanceResponse)
def advance_simulation():
    if state.simulator is None:
        raise HTTPException(status_code=400, detail="No simulation is currently running.")

    if state.simulator.get_winner() is not None:
        raise HTTPException(status_code=400, detail="The simulation is already over.")

    batch = state.simulator.run_period()

    if batch is None:
        raise HTTPException(status_code=400, detail="The simulation is already over.")

    winner = state.simulator.get_winner()
    return AdvanceResponse(batch=batch, is_over=winner is not None, winner=winner)


@app.get("/simulation/status", response_model=StatusResponse)
def get_status():
    if state.simulator is None:
        raise HTTPException(status_code=400, detail="No simulation is currently running.")

    return StatusResponse(
        period_number=state.simulator._current_period,
        event_type=state.simulator._current_event_type.value,
        alive_tributes=state.simulator._tribute_admin.get_all_tributes(only_alive=True),
    )


@app.get("/simulation/events", response_model=list[Event])
def get_events(
    period_number: Optional[int] = Query(default=None),
    event_type: Optional[str] = Query(default=None),
    tribute_id: Optional[str] = Query(default=None),
    kills_only: bool = Query(default=False),
):
    if state.simulator is None:
        raise HTTPException(status_code=400, detail="No simulation is currently running.")

    event_admin = state.simulator.get_event_admin()
    events = event_admin.get_all_events()

    if kills_only:
        events = [e for e in events if e.killed_tribute_id]

    if period_number is not None:
        events = [e for e in events if e.period_number == period_number]

    if event_type is not None:
        try:
            et = EventType(event_type.lower())
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail="Invalid event_type. Valid values: bloodbath, day, night."
            )
        events = [e for e in events if e.event_type == et]

    if tribute_id is not None:
        events = [e for e in events if tribute_id in e.related_tributes]

    return events


@app.get("/simulation/winner", response_model=Optional[Tribute])
def get_winner():
    if state.simulator is None:
        raise HTTPException(status_code=400, detail="No simulation is currently running.")

    return state.simulator.get_winner()


@app.post("/simulation/reset")
def reset_simulation():
    state.simulator = None
    return {"message": "Simulation reset successfully."}
