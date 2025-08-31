import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../services/onnx_model_service.dart';

// Events
abstract class ImageAnalysisEvent extends Equatable {
  const ImageAnalysisEvent();

  @override
  List<Object?> get props => [];
}

class ImageAnalysisRequested extends ImageAnalysisEvent {
  final String imagePath;

  const ImageAnalysisRequested({required this.imagePath});

  @override
  List<Object> get props => [imagePath];
}

class ImageAnalysisReset extends ImageAnalysisEvent {}

// States
abstract class ImageAnalysisState extends Equatable {
  const ImageAnalysisState();

  @override
  List<Object?> get props => [];
}

class ImageAnalysisInitial extends ImageAnalysisState {}

class ImageAnalysisLoading extends ImageAnalysisState {}

class ImageAnalysisSuccess extends ImageAnalysisState {
  final bool isMangrove;
  final double confidence;
  final double mangroveProbability;
  final String predictionClass;
  final String modelType;
  final String message;
  final String imagePath;

  const ImageAnalysisSuccess({
    required this.isMangrove,
    required this.confidence,
    required this.mangroveProbability,
    required this.predictionClass,
    required this.modelType,
    required this.message,
    required this.imagePath,
  });

  @override
  List<Object> get props => [
    isMangrove,
    confidence,
    mangroveProbability,
    predictionClass,
    modelType,
    message,
    imagePath,
  ];
}

class ImageAnalysisError extends ImageAnalysisState {
  final String message;
  final String? imagePath;

  const ImageAnalysisError({required this.message, this.imagePath});

  @override
  List<Object?> get props => [message, imagePath];
}

// BLoC
class ImageAnalysisBloc extends Bloc<ImageAnalysisEvent, ImageAnalysisState> {
  final ApiService _apiService;
  final OnnxModelService _onnxService = OnnxModelService();
  bool _isOnnxInitialized = false;

  ImageAnalysisBloc(this._apiService) : super(ImageAnalysisInitial()) {
    on<ImageAnalysisRequested>(_onImageAnalysisRequested);
    on<ImageAnalysisReset>(_onImageAnalysisReset);
    _initializeOnnxService();
  }

  /// Initialize the local ONNX model service
  Future<void> _initializeOnnxService() async {
    try {
      _isOnnxInitialized = await _onnxService.initialize();
      print('ONNX service initialized: $_isOnnxInitialized');
    } catch (e) {
      print('Failed to initialize ONNX service: $e');
      _isOnnxInitialized = false;
    }
  }

  Future<void> _onImageAnalysisRequested(
    ImageAnalysisRequested event,
    Emitter<ImageAnalysisState> emit,
  ) async {
    emit(ImageAnalysisLoading());
    
    try {
      Map<String, dynamic> result;
      
      // Try local ONNX inference first
      if (_isOnnxInitialized && _onnxService.isModelLoaded) {
        print('Using local ONNX model for prediction');
        result = await _predictWithLocalModel(event.imagePath);
      } else {
        print('Using backend API for prediction');
        result = await _predictWithBackend(event.imagePath);
      }
      
      emit(ImageAnalysisSuccess(
        isMangrove: result['is_mangrove'] ?? false,
        confidence: (result['confidence'] ?? 0.0).toDouble(),
        mangroveProbability: (result['mangrove_probability'] ?? 0.0).toDouble(),
        predictionClass: result['prediction_class'] ?? 'unknown',
        modelType: result['model_type'] ?? 'unknown',
        message: result['message'] ?? 'Analysis completed',
        imagePath: event.imagePath,
      ));
    } catch (e) {
      emit(ImageAnalysisError(
        message: 'Failed to analyze image: ${e.toString()}',
        imagePath: event.imagePath,
      ));
    }
  }

  /// Predict using local ONNX model
  Future<Map<String, dynamic>> _predictWithLocalModel(String imagePath) async {
    try {
      // Read image file as bytes
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Get prediction from ONNX service
      final result = await _onnxService.predictMangrove(imageBytes);
      
      return result;
    } catch (e) {
      print('Local model prediction failed: $e');
      // Fallback to backend if local fails
      return await _predictWithBackend(imagePath);
    }
  }

  /// Predict using backend API
  Future<Map<String, dynamic>> _predictWithBackend(String imagePath) async {
    try {
      final result = await _apiService.predictMangroveFromImage(imagePath);
      
      // Ensure the result has the expected format
      return {
        'is_mangrove': result['is_mangrove'] ?? false,
        'confidence': result['confidence'] ?? 0.0,
        'mangrove_probability': result['mangrove_probability'] ?? 0.0,
        'prediction_class': result['prediction_class'] ?? 'unknown',
        'model_type': 'backend_api',
        'message': result['message'] ?? 'Analysis completed via backend',
        'processing_type': 'remote',
      };
    } catch (e) {
      print('Backend prediction failed: $e');
      // Return a basic fallback result
      return {
        'is_mangrove': false,
        'confidence': 0.1,
        'mangrove_probability': 0.0,
        'prediction_class': 'error',
        'model_type': 'error',
        'message': 'Both local and remote analysis failed. Please try again.',
        'processing_type': 'error',
      };
    }
  }

  Future<void> _onImageAnalysisReset(
    ImageAnalysisReset event,
    Emitter<ImageAnalysisState> emit,
  ) async {
    emit(ImageAnalysisInitial());
  }
}
