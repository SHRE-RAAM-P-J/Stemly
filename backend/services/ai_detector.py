# services/ai_detector.py

import google.generativeai as genai
import json
import re

async def detect_topic(image_path: str):
    """
    Detect STEM topic + variables from an image using Gemini 2.0 Flash.
    Ensures clean JSON output (no markdown, no code fences).
    """

    # Read image file as bytes
    with open(image_path, "rb") as img:
        img_bytes = img.read()

    # --- STRICT JSON PROMPT ---
    system_prompt = """
    You are a STEM topic detector.

    Your job:
    - Identify the main STEM topic from the scanned image.
    - Identify important variables (e.g., v0, angle, g, refractive index, resistance).
    
    STRICT RULES:
    - Respond ONLY with a valid JSON object.
    - NO backticks.
    - NO markdown.
    - NO explanations.
    - NO code blocks.
    
    Format example:
    {
      "topic": "Projectile Motion",
      "variables": ["v0", "angle", "g"]
    }
    """

    # Gemini model
    model = genai.GenerativeModel("gemini-2.0-flash")

    response = model.generate_content(
        [
            system_prompt,
            {
                "mime_type": "image/png",
                "data": img_bytes
            }
        ]
    )

    # Raw text returned by Gemini
    raw_text = response.text.strip()

    # Remove ```json ... ``` if Gemini still adds markdown
    raw_text = re.sub(r"```json", "", raw_text)
    raw_text = re.sub(r"```", "", raw_text)
    raw_text = raw_text.strip()

    # Attempt to parse JSON
    try:
        parsed = json.loads(raw_text)
        topic = parsed.get("topic", "Unknown")
        variables = parsed.get("variables", [])
        return topic, variables

    except Exception as e:
        # Fallback: return raw response as topic
        print("⚠ JSON Parse Error in ai_detector:", e)
        print("Raw output:", raw_text)
        return raw_text, []
