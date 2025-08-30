const express = require('express');
const router = express.Router();
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

// Python backend URL
const PYTHON_BACKEND_URL = process.env.PYTHON_BACKEND_URL || 'http://localhost:8000';

// In-memory storage as fallback (replace with MongoDB in production)
let fallbackIncidents = [
  {
    id: '1',
    type: 'pollution',
    description: 'Plastic waste found near mangrove area',
    location: { latitude: 13.0827, longitude: 80.2707 },
    severity: 'high',
    status: 'pending',
    userId: 'demo_user',
    timestamp: new Date('2024-01-15T10:30:00').toISOString(),
    images: [],
    reporterName: 'Demo User'
  },
  {
    id: '2',
    type: 'illegalCutting',
    description: 'Illegal logging activity detected',
    location: { latitude: 13.0850, longitude: 80.2680 },
    severity: 'critical',
    status: 'verified',
    userId: 'demo_user',
    timestamp: new Date('2024-01-14T14:20:00').toISOString(),
    images: [],
    reporterName: 'Demo User'
  }
];

// Helper function to check Python backend availability
async function isPythonBackendAvailable() {
  try {
    const response = await axios.get(`${PYTHON_BACKEND_URL}/health`, {
      timeout: 2000,
      headers: {
        'User-Agent': 'Express-Backend/1.0',
        'Accept': 'application/json'
      }
    });
    return response.status === 200;
  } catch (error) {
    console.log('[Incidents] Python backend not available:', error.message);
    return false;
  }
}

// GET all incidents
router.get('/', async (req, res) => {
  try {
    console.log('[Incidents] GET /incidents - Fetching all incidents');
    
    // Try Python backend first
    const pythonAvailable = await isPythonBackendAvailable();
    
    if (pythonAvailable) {
      try {
        const response = await axios.get(`${PYTHON_BACKEND_URL}/incidents`, {
          timeout: 5000,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'Express-Backend/1.0',
            'Origin': req.headers.origin || 'http://localhost:5000',
            ...req.headers.authorization && { 'Authorization': req.headers.authorization }
          },
          validateStatus: function (status) {
            return status < 500; // Resolve only if the status code is less than 500
          }
        });
        
        if (response.status === 200) {
          console.log('[Incidents] Successfully fetched from Python backend');
          return res.json(response.data);
        } else if (response.status === 403) {
          console.log('[Incidents] Python backend returned 403 - Using fallback data');
          // Fall through to use fallback data
        } else {
          console.log(`[Incidents] Python backend returned ${response.status} - Using fallback data`);
        }
      } catch (pythonError) {
        console.error('[Incidents] Python backend error:', pythonError.message);
      }
    }
    
    // Fallback to local data
    console.log('[Incidents] Using fallback data');
    const sortedIncidents = [...fallbackIncidents].sort((a, b) => 
      new Date(b.timestamp) - new Date(a.timestamp)
    );
    
    res.json(sortedIncidents);
  } catch (error) {
    console.error('[Incidents] Error fetching incidents:', error);
    res.status(500).json({ 
      error: 'Failed to fetch incidents',
      message: error.message,
      usingFallback: true
    });
  }
});

// POST new incident
router.post('/', async (req, res) => {
  try {
    console.log('[Incidents] POST /incidents - Creating new incident');
    console.log('[Incidents] Request body:', JSON.stringify(req.body, null, 2));
    
    // Validate required fields
    const { type, description, location, severity } = req.body;
    
    if (!type || !description || !location) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['type', 'description', 'location']
      });
    }
    
    // Prepare incident data
    const incidentData = {
      type: type || 'other',
      description: description || '',
      location: location || { latitude: 0, longitude: 0 },
      severity: severity || 'medium',
      status: 'pending',
      userId: req.body.userId || 'anonymous',
      reporterName: req.body.reporterName || 'Anonymous',
      timestamp: new Date().toISOString(),
      images: req.body.images || [],
      ...req.body // Include any additional fields
    };
    
    // Try Python backend first for ML validation
    const pythonAvailable = await isPythonBackendAvailable();
    
    if (pythonAvailable) {
      try {
        console.log('[Incidents] Sending to Python backend for ML validation');
        
        const response = await axios.post(
          `${PYTHON_BACKEND_URL}/incidents`,
          incidentData,
          {
            timeout: 10000,
            headers: {
              'Content-Type': 'application/json',
              ...req.headers.authorization && { 'Authorization': req.headers.authorization }
            }
          }
        );
        
        console.log('[Incidents] Python backend response:', response.data);
        
        // Add ML predictions if available
        if (response.data.prediction) {
          incidentData.mlPrediction = response.data.prediction;
          incidentData.confidence = response.data.confidence;
        }
        
        return res.status(201).json(response.data);
      } catch (pythonError) {
        console.error('[Incidents] Python backend error:', pythonError.message);
        if (pythonError.response) {
          console.error('[Incidents] Python response:', pythonError.response.data);
        }
      }
    }
    
    // Fallback: Store locally
    console.log('[Incidents] Storing incident locally (fallback)');
    const newIncident = {
      id: Date.now().toString(),
      ...incidentData,
      mlPrediction: 'Pending ML analysis',
      confidence: 0
    };
    
    fallbackIncidents.push(newIncident);
    
    res.status(201).json({
      ...newIncident,
      message: 'Incident created locally. ML analysis pending.',
      usingFallback: true
    });
    
  } catch (error) {
    console.error('[Incidents] Error creating incident:', error);
    res.status(500).json({ 
      error: 'Failed to create incident',
      message: error.message,
      details: error.response?.data || error.stack
    });
  }
});

// POST analyze image with ML
router.post('/analyze-image', async (req, res) => {
  try {
    console.log('[Incidents] POST /analyze-image - Analyzing image with ML');
    
    // Check if Python backend is available
    const pythonAvailable = await isPythonBackendAvailable();
    
    if (!pythonAvailable) {
      return res.json({
        prediction: 'Mangrove area detected (offline analysis)',
        confidence: 0.75,
        details: {
          health_status: 'moderate',
          coverage: 0.65,
          threats_detected: ['possible pollution'],
          offline_mode: true
        }
      });
    }
    
    // Forward to Python backend
    const formData = new FormData();
    
    if (req.file) {
      formData.append('image', req.file.buffer, req.file.originalname);
    } else if (req.body.image) {
      formData.append('image', req.body.image);
    }
    
    const response = await axios.post(
      `${PYTHON_BACKEND_URL}/analyze-image`,
      formData,
      {
        headers: formData.getHeaders(),
        timeout: 30000
      }
    );
    
    console.log('[Incidents] ML analysis complete');
    res.json(response.data);
    
  } catch (error) {
    console.error('[Incidents] Error analyzing image:', error.message);
    
    // Return fallback prediction
    res.json({
      prediction: 'Analysis temporarily unavailable',
      confidence: 0,
      error: error.message,
      fallback: true
    });
  }
});

// GET incident by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`[Incidents] GET /incidents/${id}`);
    
    // Try Python backend first
    const pythonAvailable = await isPythonBackendAvailable();
    
    if (pythonAvailable) {
      try {
        const response = await axios.get(`${PYTHON_BACKEND_URL}/incidents/${id}`, {
          timeout: 5000,
          headers: req.headers
        });
        return res.json(response.data);
      } catch (pythonError) {
        if (pythonError.response?.status !== 404) {
          console.error('[Incidents] Python backend error:', pythonError.message);
        }
      }
    }
    
    // Fallback to local data
    const incident = fallbackIncidents.find(inc => inc.id === id);
    
    if (!incident) {
      return res.status(404).json({ error: 'Incident not found' });
    }
    
    res.json(incident);
  } catch (error) {
    console.error('[Incidents] Error fetching incident:', error);
    res.status(500).json({ 
      error: 'Failed to fetch incident',
      message: error.message 
    });
  }
});

// PUT update incident status
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`[Incidents] PUT /incidents/${id}`);
    
    // Try Python backend first
    const pythonAvailable = await isPythonBackendAvailable();
    
    if (pythonAvailable) {
      try {
        const response = await axios.put(
          `${PYTHON_BACKEND_URL}/incidents/${id}`,
          req.body,
          {
            timeout: 5000,
            headers: {
              'Content-Type': 'application/json',
              ...req.headers.authorization && { 'Authorization': req.headers.authorization }
            }
          }
        );
        return res.json(response.data);
      } catch (pythonError) {
        console.error('[Incidents] Python backend error:', pythonError.message);
      }
    }
    
    // Fallback to local update
    const incidentIndex = fallbackIncidents.findIndex(inc => inc.id === id);
    
    if (incidentIndex === -1) {
      return res.status(404).json({ error: 'Incident not found' });
    }
    
    fallbackIncidents[incidentIndex] = {
      ...fallbackIncidents[incidentIndex],
      ...req.body,
      id,
      updatedAt: new Date().toISOString()
    };
    
    res.json(fallbackIncidents[incidentIndex]);
  } catch (error) {
    console.error('[Incidents] Error updating incident:', error);
    res.status(500).json({ 
      error: 'Failed to update incident',
      message: error.message 
    });
  }
});

// GET incident statistics
router.get('/stats/summary', async (req, res) => {
  try {
    console.log('[Incidents] GET /stats/summary');
    
    // Try Python backend first
    const pythonAvailable = await isPythonBackendAvailable();
    
    if (pythonAvailable) {
      try {
        const response = await axios.get(`${PYTHON_BACKEND_URL}/incidents/stats/summary`, {
          timeout: 5000
        });
        return res.json(response.data);
      } catch (pythonError) {
        console.error('[Incidents] Python backend error:', pythonError.message);
      }
    }
    
    // Fallback statistics
    const stats = {
      total: fallbackIncidents.length,
      pending: fallbackIncidents.filter(inc => inc.status === 'pending').length,
      verified: fallbackIncidents.filter(inc => inc.status === 'verified').length,
      resolved: fallbackIncidents.filter(inc => inc.status === 'resolved').length,
      byType: {
        pollution: fallbackIncidents.filter(inc => inc.type === 'pollution').length,
        illegalCutting: fallbackIncidents.filter(inc => inc.type === 'illegalCutting').length,
        landReclamation: fallbackIncidents.filter(inc => inc.type === 'landReclamation').length,
        dumping: fallbackIncidents.filter(inc => inc.type === 'dumping').length,
        other: fallbackIncidents.filter(inc => inc.type === 'other').length
      },
      usingFallback: true
    };
    
    res.json(stats);
  } catch (error) {
    console.error('[Incidents] Error fetching statistics:', error);
    res.status(500).json({ 
      error: 'Failed to fetch statistics',
      message: error.message 
    });
  }
});

module.exports = router;
