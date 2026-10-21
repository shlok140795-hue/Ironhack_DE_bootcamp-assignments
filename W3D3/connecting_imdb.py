from datetime import timedelta
import json
import logging
import os
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


from airflow import DAG # type: ignore
from airflow.exceptions import AirflowException # type: ignore
from airflow.providers.standard.operators.python import PythonOperator # type: ignore
from pendulum import datetime # type: ignore




# Read the API key from Docker's environment
RAPIDAPI_KEY = os.environ.get("RAPIDAPI_KEY")


API_URL = "https://imdb236.p.rapidapi.com/api/imdb/most-popular-tv"


# Keep files in /tmp to match your original DAG and current setup
RAW_FILE = Path("/tmp/most_popular_tv.json")
TOP5_FILE = Path("/tmp/top_5_tv_shows.json")




# TASK 1: Fetch IMDb TV data
def fetch_imdb_data():
    if not RAPIDAPI_KEY:
        raise AirflowException(
            "RAPIDAPI_KEY is missing from the Airflow environment."
        )


    request = Request(
        API_URL,
        headers={
            "x-rapidapi-host": "imdb236.p.rapidapi.com",
            "x-rapidapi-key": RAPIDAPI_KEY,
            "User-Agent": "Mozilla/5.0",
            "Accept": "application/json",
        },
        method="GET",
    )


    try:
        with urlopen(request, timeout=30) as response:
            status_code = response.status
            response_text = response.read().decode("utf-8")


    except HTTPError as error:
        error_body = error.read().decode("utf-8", errors="replace")
        raise AirflowException(
            f"IMDb API returned HTTP {error.code}: {error_body[:500]}"
        ) from error


    except (URLError, TimeoutError) as error:
        raise AirflowException(
            f"Could not connect to IMDb API: {error}"
        ) from error


    logging.info("IMDb API returned HTTP %s", status_code)


    try:
        data = json.loads(response_text)
    except json.JSONDecodeError as error:
        raise AirflowException(
            "IMDb API did not return valid JSON."
        ) from error


    with open(RAW_FILE, "w", encoding="utf-8") as file:
        json.dump(data, file, indent=2)


    logging.info("Raw response saved to %s", RAW_FILE)
    logging.info("Raw response type: %s", type(data).__name__)


    return "IMDb data fetched successfully"




# TASK 2: Extract and rank the top five TV shows
def extract_top_5():
    if not RAW_FILE.exists():
        raise AirflowException(
            f"Raw data file not found: {RAW_FILE}"
        )


    with open(RAW_FILE, "r", encoding="utf-8") as file:
        data = json.load(file)


    # Handle a list response or common dictionary response formats
    if isinstance(data, list):
        shows = data
    elif isinstance(data, dict):
        shows = data.get("data", data.get("results", []))
    else:
        raise AirflowException("Unexpected API response format.")


    if not isinstance(shows, list) or not shows:
        raise AirflowException(
            "No shows found. Inspect the raw JSON response."
        )


    def get_rank(show):
        rank = show.get("rank", 9999)
        try:
            return int(rank)
        except (ValueError, TypeError):
            return 9999


    valid_shows = [
        show for show in shows if isinstance(show, dict)
    ]


    top_5 = sorted(valid_shows, key=get_rank)[:5]


    if not top_5:
        raise AirflowException("No valid TV show records found.")


    with open(TOP5_FILE, "w", encoding="utf-8") as file:
        json.dump(top_5, file, indent=2)


    logging.info("Top five TV shows:")


    for show in top_5:
        logging.info(
            "Rank: %s | Title: %s | Year: %s",
            show.get("rank", "N/A"),
            show.get("title", show.get("primaryTitle", "Unknown")),
            show.get("year", show.get("startYear", "N/A")),
        )


    logging.info("Top-five results saved to %s", TOP5_FILE)




# DAG definition
with DAG(
    dag_id="imdb_tv_analysis_dag",
    description="Fetch popular IMDb TV shows and extract the top five",
    start_date=datetime(2026, 1, 1),
    schedule="@daily",
    catchup=False,
    default_args={
        "retries": 2,
        "retry_delay": timedelta(seconds=15),
    },
    tags=["imdb", "api", "analysis"],
) as dag:


    fetch_data = PythonOperator(
        task_id="fetch_most_popular_tv",
        python_callable=fetch_imdb_data,
    )


    analyze_top_5 = PythonOperator(
        task_id="extract_top_5_shows",
        python_callable=extract_top_5,
    )


    fetch_data >> analyze_top_5
