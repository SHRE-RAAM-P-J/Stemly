import os
import uuid

ALLOWED_CONTENT_TYPES = {"image/png", "image/jpeg", "image/jpg"}
MAX_SCAN_BYTES = 5 * 1024 * 1024  # 5 MB
SCANS_DIR = "static/scans/"


async def save_scan(file):
    os.makedirs(SCANS_DIR, exist_ok=True)

    # Read first 1KB to check magic bytes
    header = await file.read(1024)
    await file.seek(0)  # Reset cursor

    is_png = header.startswith(b"\x89PNG\r\n\x1a\n")
    is_jpeg = header.startswith(b"\xff\xd8\xff")

    if not (is_png or is_jpeg):
        raise ValueError("Invalid file format. Only PNG and JPEG are allowed.")
    
    # We still use the extension for the filename, but based on detection
    ext = ".png" if is_png else ".jpg"

    filename = f"{uuid.uuid4()}{ext}"
    file_path = os.path.join(SCANS_DIR, filename)

    contents = bytearray()
    total_bytes = 0
    while True:
        chunk = await file.read(1024 * 1024)
        if not chunk:
            break
        total_bytes += len(chunk)
        if total_bytes > MAX_SCAN_BYTES:
            raise ValueError("File too large. Maximum allowed size is 5 MB.")
        contents.extend(chunk)

    if total_bytes == 0:
        raise ValueError("Uploaded file is empty.")

    with open(file_path, "wb") as f:
        f.write(contents)

    return f"static/scans/{filename}"
