from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from typing import Optional, Dict, Any
from auth.auth_middleware import require_firebase_user
from config import llm, is_ai_enabled, GEMINI_API_KEY
from langchain.prompts import PromptTemplate
from langchain.output_parsers import PydanticOutputParser
from pydantic import Field
import google.generativeai as genai
import json
import re
from utils.file_utils import resolve_scan_path


router = APIRouter(
    prefix="/chat",
    tags=["Chat"],
    dependencies=[Depends(require_firebase_user)],
)


class ChatRequest(BaseModel):
    user_prompt: str
    topic: str
    variables: list
    image_path: Optional[str] = None
    current_params: Optional[Dict[str, Any]] = None
    template_id: Optional[str] = None


class ChatResponse(BaseModel):
    response: str = Field(description="Natural language response to the user")
    parameter_updates: Optional[Dict[str, Any]] = Field(
        description="Dictionary of parameter updates, if any", default=None
    )
    update_type: str = Field(
        description="Type of response: 'explanation', 'parameter_change', or 'both'"
    )


def clean_json_output(text: str):
    """Remove markdown code blocks from JSON output."""
    text = text.strip()
    text = re.sub(r"```json", "", text)
    text = re.sub(r"```", "", text)
    text = text.strip()
    try:
        return json.loads(text)
    except:
        return None


async def handle_unified_chat(
    user_prompt: str,
    topic: str,
    variables: list,
    image_path: Optional[str] = None,
    current_params: Optional[Dict[str, Any]] = None,
    template_id: Optional[str] = None,
) -> ChatResponse:
    """
    Unified chat handler that can:
    1. Answer questions about the physics problem
    2. Update visualiser parameters
    3. Do both
    """
    if not is_ai_enabled():
        return ChatResponse(
            response="AI is not configured.",
            parameter_updates=None,
            update_type="explanation",
        )

    try:
        parser = PydanticOutputParser(pydantic_object=ChatResponse)

        # Build context about the problem
        context_parts = [
            f"Topic: {topic}",
            f"Variables involved: {', '.join(variables)}",
        ]

        if template_id:
            context_parts.append(f"Current simulation: {template_id}")

        if current_params:
            context_parts.append(f"Current parameters: {current_params}")

        context = "\n".join(context_parts)

        # If image is available, use Gemini Vision
        if image_path:
            try:
                local_path = resolve_scan_path(image_path)
                ext = local_path.suffix.lower()
                mime_type = "image/jpeg" if ext in (".jpg", ".jpeg") else "image/png"

                with open(local_path, "rb") as img:
                    img_bytes = img.read()

                system_prompt = f"""
You are an expert Physics Tutor and Simulation Controller.

Context from the scanned physics problem:
{context}

The user has scanned a physics problem (image provided below).

User's message: "{user_prompt}"

Your tasks:
1. Analyze the user's request.
2. If they want to change simulation parameters (e.g., "make velocity 20 m/s", "set angle to 45 degrees"):
   - Determine which parameters need updating
   - Ensure values are physically reasonable
   - Include these in "parameter_updates"
3. If they ask a physics question (e.g., "why does it curve?", "what is the formula?"):
   - Use the scanned image and context to answer clearly
   - Explain concepts in a student-friendly way
4. You can do both if needed.

IMPORTANT: Return ONLY valid JSON in this exact format:
{parser.get_format_instructions()}

No markdown, no code blocks, just raw JSON.
"""

                model = genai.GenerativeModel("gemini-2.0-flash")
                response = model.generate_content(
                    [
                        system_prompt,
                        {"mime_type": mime_type, "data": img_bytes},
                    ]
                )

                raw_text = response.text
                data = clean_json_output(raw_text)

                if data:
                    return ChatResponse(**data)

            except Exception as e:
                print(f"⚠ Gemini Vision Error: {e}")
                # Fall back to text-only mode

        # Text-only mode (no image or image failed)
        prompt_template = PromptTemplate(
            template="""
You are an expert Physics Tutor and Simulation Controller.

Context:
{context}

User's message: "{user_prompt}"

Your tasks:
1. If they want to change parameters, update them in "parameter_updates"
2. If they ask a question, provide a clear answer in "response"
3. Set "update_type" to: "explanation", "parameter_change", or "both"

{format_instructions}

Return ONLY valid JSON, no markdown.
""",
            input_variables=["context", "user_prompt"],
            partial_variables={"format_instructions": parser.get_format_instructions()},
        )

        chain = prompt_template | llm | parser

        result = await chain.ainvoke({"context": context, "user_prompt": user_prompt})

        return result

    except Exception as e:
        import traceback

        traceback.print_exc()
        print(f"❌ Chat Error: {e}")
        return ChatResponse(
            response="I'm having trouble processing your request. Please try again.",
            parameter_updates=None,
            update_type="explanation",
        )


@router.post("/ask")
async def chat_ask(req: ChatRequest, request: Request):
    """
    Unified chat endpoint that handles both parameter updates and explanations.
    """
    user_id = request.state.user["uid"]

    print(f"💬 Chat request from {user_id}: {req.user_prompt}")

    response = await handle_unified_chat(
        user_prompt=req.user_prompt,
        topic=req.topic,
        variables=req.variables,
        image_path=req.image_path,
        current_params=req.current_params,
        template_id=req.template_id,
    )

    print(f"💬 Response type: {response.update_type}")
    if response.parameter_updates:
        print(f"💬 Parameter updates: {response.parameter_updates}")

    return response.dict()
