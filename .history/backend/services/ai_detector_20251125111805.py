# services/ai_detector.py
import google.generativeai as genai
import base64

async def detect_topic(image_path: str):

    # Load image and convert to bytes
    with open(image_path, "rb") as img:
        img_bytes = img.read()

    system_prompt = """
    You are a STEM topic detector.

    Identify the topic and variables from the image.
    Respond ONLY in JSON:

    {
      "topic": "...",
      "variables": ["v0", "angle", "g"]
    }
    """

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

    raw_text = response.text

    try:
        import json
        parsed = json.loads(raw_text)
        return parsed.get("topic"), parsed.get("variables", [])
    except:
        return raw_text, []
