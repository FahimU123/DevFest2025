import requests
from requests.auth import HTTPBasicAuth
import datetime
import json

#Replace with your generated API Key and URL
API_KEY = "API_KEY"
BASE_URL = "BASE_URL"

# NLU endpoint
NLU_URL = f"{BASE_URL}/v1/analyze?version=2022-04-07"


def analyze_pothole_report(date_str: str, lat: float, lon: float):
    """
    Sends a synthetic 'pothole report' sentence to Watson NLU and
    prints out entities/keywords/etc.
    """
    text = (
        f"There is a pothole reported on {date_str} at coordinates "
        f"latitude {lat} and longitude {lon} in Michigan."
    )

    payload = {
        "text": text,
        "features": {
            "keywords": {},
            "entities": {
                "mentions": True,
                "sentiment": False,
                "emotion": False
            },
            "categories": {}
        },
        "language": "en"
    }

    headers = {
        "Content-Type": "application/json"
    }

    response = requests.post(
        NLU_URL,
        headers=headers,
        auth=HTTPBasicAuth("apikey", API_KEY),
        data=json.dumps(payload)
    )

    response.raise_for_status()
    data = response.json()

    print("Raw NLU response:")
    print(json.dumps(data, indent=2))


if __name__ == "__main__":
    # Example values (what Siri will give you)
    today = datetime.date.today().isoformat()
    lat = 42.3314
    lon = -83.0458

    analyze_pothole_report(today, lat, lon)

