import numpy as np
import tensorflow as tf
from sklearn.ensemble import RandomForestRegressor
import joblib
import os
from typing import Dict, Any
import logging
import onnxruntime as ort
from PIL import Image
import cv2
from io import BytesIO

logger = logging.getLogger(__name__)

class MLModelService:
    def __init__(self):
        self.nn_model = None
        self.rf_model = None
        self.onnx_session = None
        self.model_loaded = False
        self.onnx_loaded = False
        self.models_path = "models/"
    
    async def load_model(self):
        """Load pre-trained models"""
        try:
            # Try to load ONNX model first
            onnx_model_path = os.path.join(self.models_path, "best.onnx")
            
            if os.path.exists(onnx_model_path):
                self.onnx_session = ort.InferenceSession(onnx_model_path)
                self.onnx_loaded = True
                logger.info("ONNX model loaded successfully")
            
            # Try to load existing TensorFlow models
            nn_model_path = os.path.join(self.models_path, "mangrove_nn_model.h5")
            rf_model_path = os.path.join(self.models_path, "mangrove_rf_model.pkl")
            
            if os.path.exists(nn_model_path):
                self.nn_model = tf.keras.models.load_model(nn_model_path)
                logger.info("Neural network model loaded successfully")
            
            if os.path.exists(rf_model_path):
                self.rf_model = joblib.load(rf_model_path)
                logger.info("Random Forest model loaded successfully")
            
            # If no models exist, create and train basic models
            if not self.nn_model and not self.rf_model:
                await self.create_and_train_models()
            
            self.model_loaded = True
            
        except Exception as e:
            logger.error(f"Failed to load models: {e}")
            # Create basic models as fallback
            await self.create_basic_fallback_models()
    
    async def create_and_train_models(self):
        """Create and train models based on GreenRoots approach"""
        try:
            # Create directories
            os.makedirs(self.models_path, exist_ok=True)
            
            # Generate synthetic training data (in real scenario, use actual satellite data)
            X_train, y_train = self._generate_training_data()
            
            # Train Neural Network (adapted from GreenRoots)
            self.nn_model = self._build_neural_network()
            self.nn_model.fit(X_train, y_train, epochs=50, validation_split=0.2, verbose=0)
            
            # Train Random Forest
            self.rf_model = RandomForestRegressor(n_estimators=100, random_state=42)
            self.rf_model.fit(X_train, y_train)
            
            # Save models
            self.nn_model.save(os.path.join(self.models_path, "mangrove_nn_model.h5"))
            joblib.dump(self.rf_model, os.path.join(self.models_path, "mangrove_rf_model.pkl"))
            
            logger.info("Models trained and saved successfully")
            
        except Exception as e:
            logger.error(f"Failed to create and train models: {e}")
            await self.create_basic_fallback_models()
    
    def _build_neural_network(self):
        """Build neural network architecture based on GreenRoots"""
        model = tf.keras.Sequential([
            tf.keras.layers.Dense(128, activation='relu', input_shape=(7,)),  # 7 Landsat bands
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(64, activation='relu'),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(32, activation='relu'),
            tf.keras.layers.Dense(1, activation='sigmoid')  # Output: mangrove coverage (0-1)
        ])
        
        model.compile(
            optimizer='adam',
            loss='binary_crossentropy',
            metrics=['accuracy', 'mae']
        )
        
        return model
    
    def _generate_training_data(self, n_samples=10000):
        """Generate synthetic training data for demonstration"""
        # In real implementation, this would load actual satellite data
        np.random.seed(42)
        
        # Generate 7 bands of Landsat data (normalized to 0-1)
        X = np.random.rand(n_samples, 7)
        
        # Simulate mangrove detection based on vegetation indices
        # NDVI = (B5 - B4) / (B5 + B4) for Landsat 8
        ndvi = (X[:, 4] - X[:, 3]) / (X[:, 4] + X[:, 3] + 1e-8)
        ndwi = (X[:, 2] - X[:, 4]) / (X[:, 2] + X[:, 4] + 1e-8)
        
        # Mangrove likelihood based on NDVI, NDWI, and other factors
        mangrove_likelihood = (
            (ndvi > 0.3) & (ndvi < 0.8) &  # Moderate to high vegetation
            (ndwi > -0.3) & (ndwi < 0.3) &  # Near water but not fully aquatic
            (X[:, 5] < 0.5)  # Low brightness (shadow from dense canopy)
        ).astype(float)
        
        # Add some noise and variation
        mangrove_likelihood += np.random.normal(0, 0.1, n_samples)
        mangrove_likelihood = np.clip(mangrove_likelihood, 0, 1)
        
        return X, mangrove_likelihood
    
    async def create_basic_fallback_models(self):
        """Create basic rule-based fallback models"""
        logger.info("Creating basic fallback models")
        self.model_loaded = True
    
    async def predict_mangrove_coverage(self, satellite_data: Dict[str, Any]) -> Dict[str, Any]:
        """Predict mangrove coverage from satellite data"""
        try:
            ndvi = satellite_data.get('ndvi', 0.0)
            ndwi = satellite_data.get('ndwi', 0.0)
            savi = satellite_data.get('savi', 0.0)
            
            if self.nn_model:
                # Use neural network prediction
                # Prepare input features (7 bands simulation)
                features = np.array([[
                    0.1,  # B1 - Coastal/Aerosol
                    0.15, # B2 - Blue
                    0.2,  # B3 - Green
                    0.25, # B4 - Red
                    ndvi + 0.25,  # B5 - NIR (derived from NDVI)
                    0.15, # B6 - SWIR1
                    0.1   # B7 - SWIR2
                ]])
                
                prediction = self.nn_model.predict(features, verbose=0)[0][0]
                confidence = 0.8
                
            elif self.rf_model:
                # Use Random Forest prediction
                features = np.array([[
                    0.1, 0.15, 0.2, 0.25, ndvi + 0.25, 0.15, 0.1
                ]])
                prediction = self.rf_model.predict(features)[0]
                confidence = 0.75
                
            else:
                # Rule-based fallback prediction
                prediction = self._rule_based_prediction(ndvi, ndwi, savi)
                confidence = 0.6
            
            # Ensure prediction is between 0 and 1
            prediction = max(0.0, min(1.0, prediction))
            
            # Assess mangrove health
            health_score = self._calculate_health_score(ndvi, prediction)
            
            return {
                "coverage": float(prediction),
                "confidence": float(confidence),
                "ndvi": float(ndvi),
                "health_score": float(health_score),
                "model_type": "neural_network" if self.nn_model else ("random_forest" if self.rf_model else "rule_based")
            }
            
        except Exception as e:
            logger.error(f"Prediction failed: {e}")
            # Return safe default
            return {
                "coverage": 0.0,
                "confidence": 0.0,
                "ndvi": 0.0,
                "health_score": 0.0,
                "model_type": "error",
                "error": str(e)
            }
    
    def _rule_based_prediction(self, ndvi: float, ndwi: float, savi: float) -> float:
        """Rule-based mangrove prediction as fallback"""
        score = 0.0
        
        # NDVI contribution (mangroves typically have moderate to high NDVI)
        if 0.3 <= ndvi <= 0.8:
            score += 0.4
        elif 0.2 <= ndvi < 0.3:
            score += 0.2
        elif ndvi > 0.8:
            score += 0.1  # Too high might indicate other vegetation
        
        # NDWI contribution (mangroves are near water)
        if -0.3 <= ndwi <= 0.3:
            score += 0.3
        elif -0.5 <= ndwi < -0.3:
            score += 0.1
        
        # SAVI contribution
        if 0.2 <= savi <= 0.6:
            score += 0.3
        elif 0.1 <= savi < 0.2:
            score += 0.1
        
        return min(1.0, score)
    
    def _calculate_health_score(self, ndvi: float, coverage: float) -> float:
        """Calculate mangrove health score (0-100)"""
        if coverage < 0.1:
            return 0.0  # No mangroves detected
        
        # Health based on NDVI values
        if ndvi >= 0.6:
            health = 90.0
        elif ndvi >= 0.4:
            health = 70.0
        elif ndvi >= 0.2:
            health = 50.0
        else:
            health = 20.0
        
        # Adjust for coverage
        health *= coverage
        
        return min(100.0, health)
    
    def preprocess_image(self, image_data: bytes) -> np.ndarray:
        """Preprocess image for ONNX model inference"""
        try:
            # Convert bytes to PIL Image
            image = Image.open(BytesIO(image_data))
            
            # Convert to RGB if not already
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Resize image (assuming model expects 224x224, adjust as needed)
            image = image.resize((224, 224))
            
            # Convert to numpy array
            image_array = np.array(image)
            
            # Normalize to [0,1] range
            image_array = image_array.astype(np.float32) / 255.0
            
            # Add batch dimension and transpose to CHW format (Channel, Height, Width)
            # Most ONNX models expect NCHW format (Batch, Channel, Height, Width)
            image_array = np.transpose(image_array, (2, 0, 1))  # HWC to CHW
            image_array = np.expand_dims(image_array, axis=0)  # Add batch dimension
            
            return image_array
            
        except Exception as e:
            logger.error(f"Error preprocessing image: {e}")
            raise e
    
    async def predict_mangrove_from_image(self, image_data: bytes) -> Dict[str, Any]:
        """Predict if image contains mangrove using ONNX model"""
        try:
            if not self.onnx_loaded or self.onnx_session is None:
                # Fallback to rule-based image analysis
                return await self._fallback_image_prediction(image_data)
            
            # Preprocess image
            processed_image = self.preprocess_image(image_data)
            
            # Get input name from ONNX model
            input_name = self.onnx_session.get_inputs()[0].name
            
            # Run inference
            outputs = self.onnx_session.run(None, {input_name: processed_image})
            
            # Process outputs (assuming binary classification)
            prediction = outputs[0][0]  # Adjust based on your model's output format
            
            # Convert to probability if needed
            if len(prediction) == 2:  # Binary classification with two outputs
                mangrove_prob = float(prediction[1])  # Probability of mangrove class
            else:  # Single output
                mangrove_prob = float(prediction[0]) if prediction[0] <= 1.0 else 1.0 / (1.0 + np.exp(-prediction[0]))
            
            # Determine if it's mangrove based on threshold
            is_mangrove = mangrove_prob > 0.5
            confidence = max(mangrove_prob, 1.0 - mangrove_prob)  # Confidence is the max probability
            
            return {
                "is_mangrove": is_mangrove,
                "confidence": float(confidence),
                "mangrove_probability": float(mangrove_prob),
                "prediction_class": "mangrove" if is_mangrove else "not_mangrove",
                "model_type": "onnx",
                "message": f"This image {'contains' if is_mangrove else 'does not contain'} mangrove vegetation with {confidence*100:.1f}% confidence."
            }
            
        except Exception as e:
            logger.error(f"ONNX prediction failed: {e}")
            # Fallback to basic analysis
            return await self._fallback_image_prediction(image_data)
    
    async def _fallback_image_prediction(self, image_data: bytes) -> Dict[str, Any]:
        """Fallback image analysis when ONNX model is not available"""
        try:
            # Simple color-based analysis as fallback
            image = Image.open(BytesIO(image_data))
            image_array = np.array(image)
            
            # Calculate green ratio (simple heuristic)
            if len(image_array.shape) == 3 and image_array.shape[2] >= 3:
                green_ratio = np.mean(image_array[:, :, 1]) / (np.mean(image_array) + 1e-8)
                
                # Simple rule: high green content might indicate vegetation
                is_mangrove = green_ratio > 1.1  # Adjust threshold as needed
                confidence = min(0.6, abs(green_ratio - 1.0) + 0.3)  # Lower confidence for fallback
                
                return {
                    "is_mangrove": is_mangrove,
                    "confidence": float(confidence),
                    "mangrove_probability": float(green_ratio - 0.5) if green_ratio > 0.5 else 0.0,
                    "prediction_class": "mangrove" if is_mangrove else "not_mangrove",
                    "model_type": "fallback_color_analysis",
                    "message": f"Basic analysis suggests this image {'might contain' if is_mangrove else 'likely does not contain'} vegetation (confidence: {confidence*100:.1f}%). For accurate results, please ensure ONNX model is loaded."
                }
            else:
                # Cannot analyze grayscale or invalid images
                return {
                    "is_mangrove": False,
                    "confidence": 0.1,
                    "mangrove_probability": 0.0,
                    "prediction_class": "unknown",
                    "model_type": "fallback_error",
                    "message": "Unable to analyze image format. Please ensure the image is a valid color image."
                }
                
        except Exception as e:
            logger.error(f"Fallback prediction failed: {e}")
            return {
                "is_mangrove": False,
                "confidence": 0.0,
                "mangrove_probability": 0.0,
                "prediction_class": "error",
                "model_type": "error",
                "message": f"Error analyzing image: {str(e)}"
            }
    
    async def retrain_model(self, new_data: Dict[str, Any]):
        """Retrain model with new validated data"""
        # This would be implemented to continuously improve the model
        # with validated incident reports and expert annotations
        pass
