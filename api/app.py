from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pymysql
import os
import socket
import time

app = FastAPI(title="Milestone API")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8081", "http://127.0.0.1:8081"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# MariaDB configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'mariadb-service.milestone-app.svc.cluster.local'),
    'user': os.getenv('DB_USER', 'appuser'),
    'password': os.getenv('DB_PASSWORD', 'apppassword'),
    'database': os.getenv('DB_NAME', 'milestone'),
    'port': int(os.getenv('DB_PORT', '3306')),
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

def get_db_connection(max_retries=3, delay=2):
    """Get MariaDB connection with retry logic"""
    for attempt in range(max_retries):
        try:
            conn = pymysql.connect(**DB_CONFIG)
            return conn
        except pymysql.Error as e:
            print(f"Database connection attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(delay)
                continue
            else:
                raise e

@app.get("/")
async def root():
    return {"message": "Milestone 2 API", "container_id": socket.gethostname()}

@app.get("/user")
async def get_user():
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT name FROM users WHERE id = 1")
            result = cursor.fetchone()
        
        conn.close()
        
        if result:
            return {"name": result['name'], "container_id": socket.gethostname()}
        else:
            return {"name": "Brent Verlinden", "container_id": socket.gethostname()}
    except Exception as e:
        print(f"Database error: {e}")
        return {"name": "Brent Verlinden", "container_id": socket.gethostname(), "error": "Database connection failed"}

@app.get("/container")
async def get_container_info():
    return {
        "container_id": socket.gethostname(),
        "hostname": socket.gethostname()
    }

@app.put("/user/{name}")
async def update_user(name: str):
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("UPDATE users SET name = %s WHERE id = 1", (name,))
        conn.commit()
        conn.close()
        return {"message": "User updated successfully", "new_name": name}
    except Exception as e:
        print(f"Update error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT 1")
        conn.close()
        return {"status": "healthy", "container_id": socket.gethostname()}
    except Exception as e:
        print(f"Health check error: {e}")
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")

@app.get("/metrics")
async def metrics():
    return {
        "http_requests_total": 1,
        "container_id": socket.gethostname()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)