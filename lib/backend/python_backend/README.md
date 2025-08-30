# Mangrove Watch AI Backend

AI-powered backend for mangrove monitoring and conservation using Google Earth Engine, Gemini Vision API, and Machine Learning.

## Requirements

- Python 3.13 or higher
- MongoDB (local or Atlas)
- Google Cloud APIs (Gemini, Earth Engine)

## Installation

### 1. Create Virtual Environment (Recommended)

```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

**Note for TensorFlow:** If you need TensorFlow support, install it separately as it may require specific configuration for Python 3.13:

```bash
pip install tensorflow
```

### 3. Configure Environment Variables

1. Copy the example environment file:
   ```bash
   cp ../.env.example ../.env
   ```

2. Edit `../.env` and add your credentials:
   - MongoDB connection string
   - Google API keys (Gemini and/or general Google API key)
   - Google Earth Engine credentials
   - JWT secret key

### 4. Set Up Google Earth Engine

1. Create a Google Cloud Project
2. Enable Earth Engine API
3. Create a service account
4. Download the service account key JSON
5. Add the key to your `.env` file

## Running the Backend

### Development Mode

```bash
python main.py
```

Or with auto-reload:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Production Mode

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

## API Documentation

Once the server is running, you can access:

- **Interactive API Docs:** http://localhost:8000/docs
- **Alternative Docs:** http://localhost:8000/redoc
- **OpenAPI Schema:** http://localhost:8000/openapi.json

## Project Structure

```
python_backend/
├── main.py                 # FastAPI application entry point
├── requirements.txt        # Python dependencies
├── database/
│   ├── __init__.py
│   └── mongodb.py         # MongoDB connection and operations
├── models/
│   ├── __init__.py
│   ├── user.py           # User data models
│   ├── incident.py       # Incident report models
│   └── prediction.py     # ML prediction models
├── services/
│   ├── __init__.py
│   ├── auth_service.py   # Authentication service
│   ├── gemini_service.py # Gemini Vision API service
│   ├── gee_service.py    # Google Earth Engine service
│   └── ml_service.py     # Machine Learning service
└── models/               # ML model files (created at runtime)
```

## Key Features

- **Image Analysis:** Analyze mangrove images using Gemini Vision API
- **Satellite Data:** Access Google Earth Engine for satellite imagery analysis
- **ML Predictions:** Predict mangrove coverage using machine learning models
- **User Authentication:** JWT-based authentication system
- **Incident Reporting:** Report and track environmental incidents
- **Gamification:** Points, badges, and leaderboard system
- **Analytics Dashboard:** Real-time analytics and trends

## API Endpoints

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - User login

### Analysis
- `POST /analyze-image` - Analyze uploaded image (authenticated)
- `POST /public/analyze-image` - Public image analysis
- `POST /predict-mangrove` - Predict mangrove coverage
- `GET /satellite-analysis/{lat}/{lng}` - Get satellite data

### Incidents
- `POST /incidents` - Create incident report
- `GET /incidents` - List incidents
- `GET /incidents/{id}` - Get specific incident

### Analytics
- `GET /analytics/dashboard` - Dashboard statistics
- `GET /analytics/mangrove-trends` - Mangrove health trends
- `GET /mangrove-extent` - Mangrove extent data

### User
- `GET /user/profile` - User profile and stats
- `GET /leaderboard` - Top contributors

### System
- `GET /health` - Health check
- `GET /` - API information

## Troubleshooting

### Common Issues

1. **TensorFlow Installation:** If TensorFlow doesn't install, try:
   ```bash
   pip install --upgrade pip
   pip install tensorflow --no-cache-dir
   ```

2. **MongoDB Connection:** Ensure MongoDB is running:
   ```bash
   # Windows
   net start MongoDB
   
   # macOS/Linux
   sudo systemctl start mongod
   ```

3. **Google Earth Engine:** If GEE initialization fails, verify:
   - Service account has Earth Engine API access
   - Correct project ID in `.env`
   - Valid service account credentials

4. **Port Already in Use:** Change the port:
   ```bash
   uvicorn main:app --port 8001
   ```

## Development

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio

# Run tests
pytest
```

### Code Formatting

```bash
# Install development tools
pip install black flake8

# Format code
black .

# Check code style
flake8 .
```

## Deployment

For production deployment, consider:

1. Using a production ASGI server (Gunicorn with Uvicorn workers)
2. Setting up proper logging and monitoring
3. Using environment-specific configuration
4. Implementing rate limiting
5. Setting up SSL/TLS certificates
6. Using a reverse proxy (Nginx/Apache)

## License

This project is part of the Mangrove Watch initiative for environmental conservation.

## Support

For issues or questions, please check the main project documentation or create an issue in the repository.
