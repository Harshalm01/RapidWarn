// lib/services/ai_classification_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIClassificationService {
  static final AIClassificationService _instance =
      AIClassificationService._internal();
  factory AIClassificationService() => _instance;
  AIClassificationService._internal();

  static const List<String> _disasterTypes = [
    'flood',
    'fire',
    'earthquake',
    'landslide',
    'storm',
    'accident',
    'other'
  ];

  /// Start monitoring for unprocessed insights and classify them
  void startClassificationMonitoring() {
    debugPrint('🤖 Starting AI Classification Service monitoring...');

    // Listen for new unprocessed insights
    FirebaseFirestore.instance
        .collection('insights')
        .where('processed', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      for (var doc in snapshot.docs) {
        await _processInsight(doc.id, doc.data());
      }
    });
  }

  /// Process a single insight with mock AI classification
  Future<void> _processInsight(String docId, Map<String, dynamic> data) async {
    try {
      debugPrint('🔄 Processing insight: $docId');

      // Simulate AI processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock AI classification (replace with real AI model)
      final classificationResult =
          await _mockAIClassification(data['media_url']);

      debugPrint(
          '🤖 Classification result: ${classificationResult['disaster_type']} (confidence: ${classificationResult['confidence']})');

      // 1. Update Firebase Firestore with classification results
      await FirebaseFirestore.instance
          .collection('insights')
          .doc(docId)
          .update({
        'disaster_type': classificationResult['disaster_type'],
        'confidence': classificationResult['confidence'],
        'processed': true,
        'processed_at': FieldValue.serverTimestamp(),
        'ai_analysis': classificationResult['analysis'],
      });

      // 2. Update Supabase table for real-time notifications (if disaster detected)
      if (classificationResult['disaster_type'] != 'other' &&
          classificationResult['confidence'] > 0.7) {
        await _updateSupabaseWithClassification(data, classificationResult);
      }

      debugPrint('✅ Insight $docId processed successfully');
    } catch (e) {
      debugPrint('❌ Error processing insight $docId: $e');

      // Mark as processed with error
      await FirebaseFirestore.instance
          .collection('insights')
          .doc(docId)
          .update({
        'processed': true,
        'error': e.toString(),
        'processed_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Update Supabase table to trigger real-time notifications
  Future<void> _updateSupabaseWithClassification(
      Map<String, dynamic> data, Map<String, dynamic> classification) async {
    try {
      debugPrint('📤 Updating Supabase for real-time notifications...');

      final supabase = Supabase.instance.client;

      // Insert or update the insights table in Supabase with only existing columns
      await supabase.from('insights').upsert({
        'media_url': data['media_url'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'disaster_type': classification['disaster_type'],
        'processed': true,
        'uploader_id': data['uploader_id'],
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint(
          '✅ Supabase updated - real-time notifications will be triggered');
    } catch (e) {
      debugPrint('❌ Failed to update Supabase: $e');
      // Continue processing even if Supabase update fails
    }
  }

  /// Mock AI classification (replace with real AI model API call)
  Future<Map<String, dynamic>> _mockAIClassification(String mediaUrl) async {
    debugPrint('🔍 Analyzing media: $mediaUrl');

    // Simulate AI processing
    final random = Random();

    // Mock classification logic (replace with real AI)
    String disasterType;
    double confidence;
    String analysis;

    // Random classification for demo (replace with real AI model)
    final typeIndex = random.nextInt(_disasterTypes.length);
    disasterType = _disasterTypes[typeIndex];
    confidence = 0.5 + (random.nextDouble() * 0.5); // 0.5 to 1.0

    switch (disasterType) {
      case 'flood':
        analysis =
            'Water accumulation detected in the image. Potential flood risk identified.';
        break;
      case 'fire':
        analysis =
            'Smoke or fire patterns detected. Emergency response may be required.';
        break;
      case 'earthquake':
        analysis =
            'Structural damage or debris patterns suggest seismic activity.';
        break;
      case 'landslide':
        analysis = 'Soil movement or debris flow patterns detected.';
        break;
      case 'storm':
        analysis = 'Severe weather conditions or wind damage detected.';
        break;
      case 'accident':
        analysis = 'Vehicle accident or emergency situation detected.';
        break;
      default:
        analysis =
            'No clear disaster patterns detected. Image classified as normal.';
        confidence =
            0.3 + (random.nextDouble() * 0.4); // Lower confidence for 'other'
    }

    return {
      'disaster_type': disasterType,
      'confidence': confidence,
      'analysis': analysis,
      'model_version': 'mock_v1.0',
      'processing_time_ms': 2000,
    };
  }

  /// Manually reprocess all unprocessed insights (for testing)
  Future<void> reprocessAllPendingInsights() async {
    debugPrint('🔄 Manually reprocessing all pending insights...');

    final querySnapshot = await FirebaseFirestore.instance
        .collection('insights')
        .where('processed', isEqualTo: false)
        .get();

    debugPrint('📊 Found ${querySnapshot.docs.length} pending insights');

    for (var doc in querySnapshot.docs) {
      await _processInsight(doc.id, doc.data());
      // Add small delay to avoid overwhelming the system
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('✅ All pending insights reprocessed');
  }

  /// FOR TESTING: Force classify a specific insight
  Future<void> forceClassifyInsight(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('insights')
          .doc(docId)
          .get();

      if (doc.exists) {
        await _processInsight(docId, doc.data()!);
      } else {
        debugPrint('❌ Insight $docId not found');
      }
    } catch (e) {
      debugPrint('❌ Error force classifying insight $docId: $e');
    }
  }
}

// INTEGRATION NOTES:
// 
// To integrate a real AI model, replace the _mockAIClassification method with:
// 
// 1. **Google Cloud Vision API** for basic image analysis
// 2. **Custom TensorFlow Lite model** for on-device processing
// 3. **Firebase ML Kit** for basic image recognition
// 4. **Custom API endpoint** with models like YOLO, ResNet, etc.
// 5. **OpenAI Vision API** for advanced image understanding
//
// Example real implementation:
// 
// Future<Map<String, dynamic>> _realAIClassification(String mediaUrl) async {
//   final response = await http.post(
//     Uri.parse('YOUR_AI_API_ENDPOINT'),
//     headers: {'Authorization': 'Bearer YOUR_API_KEY'},
//     body: jsonEncode({'image_url': mediaUrl}),
//   );
//   
//   final result = jsonDecode(response.body);
//   return {
//     'disaster_type': result['predicted_class'],
//     'confidence': result['confidence'],
//     'analysis': result['description'],
//   };
// }