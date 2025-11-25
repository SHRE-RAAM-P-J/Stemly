import uuid
import os

SCANS_DIR = "static/scans/"

async def save_scan(file):
    # Ensure directory exists
    os.makedirs(SCANS_DIR, exist_ok=True)

    # Generate unique filename
    filename = f"{uuid.uuid4()}.png"
    file_path = os.path.join(SCANS_DIR, filename)

    # Save file to static directory
    contents = await file.read()
    with open(file_path, "wb") as f:
        f.write(contents)

    # Return relative path for frontend access
    return f"static/scans/{filename}"
