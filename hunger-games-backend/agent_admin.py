

from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain.agents import create_agent
from pydantic import BaseModel, PrivateAttr
from classes import EventBatch, EventType, Tribute, Event
from prompts import SYSTEM_PROMPT
import os

load_dotenv()
class AgentAdmin(BaseModel):

    model_name: str = "llama-3.3-70b-versatile"
    base_url: str = "https://api.groq.com/openai/v1"
    temperature: float = 0.7
    language: str = "English"
    tools: list = []

    _llm: ChatOpenAI = PrivateAttr()
    _agent: any = PrivateAttr()

    def model_post_init(self, __context):
        """Initializes the LLM connection and the agent after the model is created."""
        self._llm = ChatOpenAI(
            model=self.model_name,
            base_url=self.base_url,
            api_key=os.getenv("GROQ_API_KEY"),
            temperature=self.temperature,
            streaming=False,
        )

        self._agent = create_agent(
            model=self._llm,
            system_prompt=SYSTEM_PROMPT,
            response_format=EventBatch,
            tools=self.tools
        )

    def _build_prompt(self, period_number: int, event_type: EventType,
                  alive_tributes: list[Tribute], past_events: list[Event]) -> str:

        tributes_info = "\n".join([
            f"- ID: {t.id} | Name: {t.name} | District: {t.district} | "
            f"Kills: {t.kills} | Items: {[i.name for i in t.items]} | "
            f"Notes: {t.state_notes}"
            for t in alive_tributes
        ])

        history = "\n".join([
            f"[{e.event_type.value.upper()} {e.period_number}] {e.narrative}"
            for e in past_events
        ]) if past_events else "No previous events."

        final_two_warning = ""
        if len(alive_tributes) == 2:
            final_two_warning = """
        ## FINAL TWO WARNING
        Only 2 tributes remain. This is the final confrontation. Exactly ONE tribute must survive and be declared the winner.
        Only one death must occur this period. The survivor must be clearly established. Do NOT kill both tributes.
        """

        return f"""
        ## Current Period
        Type: {event_type.value}
        Period Number: {period_number}

        ## Alive Tributes ({len(alive_tributes)} remaining)
        {tributes_info}

        ## Recent Event History (last 2 periods)
        {history}

        {final_two_warning}

        ## REMINDER
        This period MUST have at least 2 deaths. Do not generate the events without including at least two deaths.
        Always write all narratives and state notes in {self.language}.

        Generate the events for this period. Every alive tribute must be covered by at least one event.
        """

    def generate_events(self, period_number: int, event_type: EventType, alive_tributes: list[Tribute], past_events: list[Event]) -> EventBatch | None:
        """Generates a batch of events for the current period based on the game state."""
        try:
            prompt = self._build_prompt(period_number, event_type, alive_tributes, past_events)
            raw_response = self._agent.invoke({
                "messages": [{"role": "user", "content": prompt}]
            })
            return raw_response["structured_response"]
        except Exception as e:
            print(f"Error generating events: {e}")
            return None