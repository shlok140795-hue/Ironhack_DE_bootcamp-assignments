from datetime import datetime


import logging


from airflow import DAG # type: ignore
from airflow.providers.standard.operators.python import PythonOperator # type: ignore
from airflow.utils.email import send_email # type: ignore




def send_notification():
    logging.info("Starting email notification...")


    send_email(
        to=["shlok140795@gmail.com"],
        subject="Airflow Email Notification Test",
        html_content="""
        <h2>Airflow Email Test</h2>
        <p>Hello!</p>
        <p>Your Airflow DAG ran successfully.</p>
        <p>This email was sent automatically by Apache Airflow.</p>
        """,
    )


    logging.info("Email notification sent successfully.")




with DAG(
    dag_id="email_dag",
    description="Send an email notification from Airflow",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["email", "notification"],
) as dag:


    email_task = PythonOperator(
        task_id="send_email",
        python_callable=send_notification,
    )
