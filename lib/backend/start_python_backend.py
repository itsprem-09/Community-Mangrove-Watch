#!/usr/bin/env python3
"""
Startup script for the Python FastAPI backend
"""
import os
import sys
import subprocess
from pathlib import Path

def install_requirements():
    """Install Python requirements"""
    req_file = Path(__file__).parent / "python_backend" / "requirements.txt"
    if req_file.exists():
        print("Installing Python requirements...")
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", str(req_file)], check=True)
    else:
        print("Requirements file not found!")

def setup_environment():
    """Set up environment variables"""
    env_file = Path(__file__).parent / ".env"
    if not env_file.exists():
        print("Creating .env file from example...")
        example_file = Path(__file__).parent / ".env.example"
        if example_file.exists():
            with open(example_file, 'r') as f:
                content = f.read()
            with open(env_file, 'w') as f:
                f.write(content)
            print("Please update the .env file with your actual API keys and configuration!")
        else:
            print("No .env.example file found!")

def start_server():
    """Start the FastAPI server"""
    backend_dir = Path(__file__).parent / "python_backend"
    os.chdir(backend_dir)
    
    print("Starting Python FastAPI backend on http://localhost:8000")
    print("API documentation available at http://localhost:8000/docs")
    
    subprocess.run([
        sys.executable, "-m", "uvicorn", 
        "main:app", 
        "--host", "0.0.0.0", 
        "--port", "8000", 
        "--reload"
    ])

if __name__ == "__main__":
    print("=== Community Mangrove Watch - Python Backend ===")
    
    try:
        setup_environment()
        install_requirements()
        start_server()
    except KeyboardInterrupt:
        print("\nServer stopped by user")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
