import os
from urllib.parse import quote_plus

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker


database_user = quote_plus(os.getenv("DATABASE_USER", "task_app"))
database_password = quote_plus(os.getenv("DATABASE_PASSWORD", ""))
database_host = os.getenv("DATABASE_HOST", "db")
database_port = os.getenv("DATABASE_PORT", "3306")
database_name = os.getenv("DATABASE_NAME", "task_manager")

DATABASE_URL = (
    f"mysql+pymysql://{database_user}:{database_password}"
    f"@{database_host}:{database_port}/{database_name}"
)

engine = create_engine(DATABASE_URL, pool_pre_ping=True)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False
)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()