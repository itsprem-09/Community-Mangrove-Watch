import google.generativeai as genai
import os
from PIL import Image
import io
import base64
from typing import Dict, Any
from datetime import datetime

class GeminiService:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY", os.getenv("GOOGLE_API_KEY"))
        self.model = None
        self.initialized = False
    
    def initialize(self):
        """Initialize Gemini service with API key"""
        if self.api_key:
            try:
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel('gemini-1.5-flash')
                self.initialized = True
                print("Gemini service initialized successfully")
            except Exception as e:
                print(f"Failed to initialize Gemini service: {e}")
                self.initialized = False
        else:
            print("Gemini API key not found")
            self.initialized = False
    
    async def analyze_mangrove_image(self, image_data: bytes) -> Dict[str, Any]:
        """Analyze image using Gemini API to detect mangroves"""
        if not self.model:
            raise Exception("Gemini API key not configured")
        
        try:
            # Convert bytes to PIL Image
            image = Image.open(io.BytesIO(image_data))
            
            # Prepare the prompt for mangrove detection
            prompt = """
            Analyze this image and determine if it contains mangroves. Consider the following:
            
            1. Are there mangrove trees visible in the image?
            2. Look for characteristic features like:
               - Prop roots (aerial roots extending into water/mud)
               - Dense, green canopy near water bodies
               - Coastal/estuarine environment
               - Salt-tolerant vegetation
               - Trees growing in or near brackish water
            
            3. Assess the health of any mangroves present:
               - Green, dense foliage indicates healthy mangroves
               - Brown, sparse, or damaged foliage indicates stressed/unhealthy mangroves
               - Dead or cut trees indicate mangrove loss
            
            4. Identify any threats or issues:
               - Evidence of cutting or destruction
               - Pollution or debris
               - Land reclamation activities
               - Human encroachment
            
            Respond in the following JSON format:
            {
                "is_mangrove": true/false,
                "confidence": 0.0-1.0,
                "description": "Detailed description of what you see",
                "health_assessment": "healthy/stressed/damaged/unclear",
                "threats_detected": ["list", "of", "threats"],
                "coverage_estimate": "percentage or description",
                "recommendations": "Action recommendations if applicable"
            }
            """
            
            # Generate response
            response = self.model.generate_content([prompt, image])
            
            # Parse the response (assuming it returns JSON-like text)
            try:
                # Extract JSON from response
                response_text = response.text
                if "```json" in response_text:
                    json_start = response_text.find("```json") + 7
                    json_end = response_text.find("```", json_start)
                    response_text = response_text[json_start:json_end].strip()
                elif "{" in response_text and "}" in response_text:
                    json_start = response_text.find("{")
                    json_end = response_text.rfind("}") + 1
                    response_text = response_text[json_start:json_end]
                
                import json
                analysis = json.loads(response_text)
                
                # Ensure required fields exist
                analysis.setdefault("is_mangrove", False)
                analysis.setdefault("confidence", 0.5)
                analysis.setdefault("description", "Unable to analyze image properly")
                
                return analysis
                
            except (json.JSONDecodeError, Exception):
                # Fallback to text analysis if JSON parsing fails
                return {
                    "is_mangrove": "mangrove" in response.text.lower(),
                    "confidence": 0.6,
                    "description": response.text,
                    "health_assessment": "unclear",
                    "threats_detected": [],
                    "coverage_estimate": "Unable to determine",
                    "recommendations": "Manual verification recommended"
                }
                
        except Exception as e:
            raise Exception(f"Failed to analyze image with Gemini: {str(e)}")
    
    async def generate_incident_analysis(self, incident_data: dict, image_data: bytes = None) -> Dict[str, Any]:
        """Generate detailed analysis for an incident report"""
        if not self.model:
            return {"analysis": "Gemini API not available"}
        
        try:
            prompt = f"""
            Analyze this mangrove incident report:
            
            Type: {incident_data.get('type', 'Unknown')}
            Description: {incident_data.get('description', 'No description')}
            Location: {incident_data.get('latitude', 'Unknown')}, {incident_data.get('longitude', 'Unknown')}
            Severity: {incident_data.get('severity', 'Unknown')}
            
            Please provide:
            1. Risk assessment
            2. Urgency level (1-10)
            3. Recommended actions
            4. Potential environmental impact
            5. Verification suggestions for authorities
            
            Format your response as structured text.
            """
            
            if image_data:
                image = Image.open(io.BytesIO(image_data))
                response = self.model.generate_content([prompt, image])
            else:
                response = self.model.generate_content(prompt)
            
            return {
                "ai_analysis": response.text,
                "timestamp": datetime.utcnow().isoformat(),
                "model": "gemini-1.5-flash"
            }
            
        except Exception as e:
            return {
                "ai_analysis": f"Analysis failed: {str(e)}",
                "timestamp": datetime.utcnow().isoformat(),
                "model": "gemini-1.5-flash"
            }
