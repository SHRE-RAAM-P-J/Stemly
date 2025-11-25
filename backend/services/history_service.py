import uuid
from datetime import datetime

# Temporary DB — replace with MongoDB/Postgres later
DATABASE = []

def add_history(user_id, image_path, topic, variables):
    record = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "image_path": image_path,
        "topic": topic,
        "variables": variables,
        "timestamp": datetime.now().isoformat()
    }

    DATABASE.append(record)
    return record["id"]


def get_user_history(user_id):
    return [entry for entry in DATABASE if entry["user_id"] == user_id]
