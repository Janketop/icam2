#!/usr/bin/env python3
"""
Simple Proof of Concept script for ICAM2
Tests basic detection and face recognition capabilities

Run this BEFORE starting full development to verify:
1. GPU is working
2. YOLO detection works
3. Face recognition works
4. Performance is acceptable

Usage:
    python poc_simple.py --image test.jpg
    python poc_simple.py --video test.mp4
"""

import argparse
import time
import sys
from pathlib import Path

import cv2
import torch
import numpy as np

# Colors for visualization
GREEN = (0, 255, 0)
RED = (0, 0, 255)
BLUE = (255, 0, 0)
YELLOW = (0, 255, 255)


def check_gpu():
    """Check if CUDA GPU is available"""
    print("=" * 50)
    print("GPU Check")
    print("=" * 50)

    if torch.cuda.is_available():
        device = torch.cuda.get_device_name(0)
        memory = torch.cuda.get_device_properties(0).total_memory / 1e9
        print(f"✅ GPU Available: {device}")
        print(f"✅ GPU Memory: {memory:.2f} GB")
        return True
    else:
        print("❌ GPU NOT Available - This will be very slow!")
        print("   Consider using a machine with NVIDIA GPU")
        return False


def test_yolo_detection(image_path=None):
    """Test YOLO person detection"""
    print("\n" + "=" * 50)
    print("YOLO Detection Test")
    print("=" * 50)

    try:
        from ultralytics import YOLO

        # Load model
        print("Loading YOLOv8n model...")
        model = YOLO('yolov8n.pt')

        # Create test image if none provided
        if image_path is None or not Path(image_path).exists():
            print("Creating synthetic test image...")
            test_img = np.random.randint(0, 255, (640, 480, 3), dtype=np.uint8)
        else:
            print(f"Loading image: {image_path}")
            test_img = cv2.imread(str(image_path))
            if test_img is None:
                print(f"❌ Could not load image: {image_path}")
                return False

        # Test detection
        print("Running detection...")
        start_time = time.time()
        results = model(test_img, classes=[0], verbose=False)  # class 0 = person
        detection_time = (time.time() - start_time) * 1000

        # Parse results
        detections = results[0].boxes
        person_count = len(detections)

        print(f"✅ Detection completed in {detection_time:.2f}ms")
        print(f"✅ Detected {person_count} person(s)")

        # Performance check
        if detection_time < 50:
            print(f"✅ Performance: EXCELLENT (<50ms)")
        elif detection_time < 100:
            print(f"⚠️  Performance: GOOD (50-100ms)")
        elif detection_time < 200:
            print(f"⚠️  Performance: ACCEPTABLE (100-200ms)")
        else:
            print(f"❌ Performance: TOO SLOW (>{200}ms)")
            print("   Consider using a more powerful GPU or lighter model")

        # GPU Memory check
        if torch.cuda.is_available():
            memory_allocated = torch.cuda.memory_allocated() / 1e9
            memory_reserved = torch.cuda.memory_reserved() / 1e9
            print(f"✅ GPU Memory Used: {memory_allocated:.2f} GB (Reserved: {memory_reserved:.2f} GB)")

            if memory_allocated > 6:
                print("⚠️  High memory usage! May have issues with multiple cameras")

        return True

    except ImportError:
        print("❌ Ultralytics YOLO not installed!")
        print("   Install: pip install ultralytics")
        return False
    except Exception as e:
        print(f"❌ Error during detection: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_face_recognition(image_path=None):
    """Test face recognition with InsightFace"""
    print("\n" + "=" * 50)
    print("Face Recognition Test")
    print("=" * 50)

    try:
        import insightface
        from insightface.app import FaceAnalysis

        # Initialize
        print("Loading InsightFace model...")
        app = FaceAnalysis(name='buffalo_l', providers=['CUDAExecutionProvider', 'CPUExecutionProvider'])
        app.prepare(ctx_id=0 if torch.cuda.is_available() else -1, det_size=(640, 640))

        # Create or load test image
        if image_path is None or not Path(image_path).exists():
            print("Creating synthetic test image with face...")
            # Create a simple face-like pattern
            test_img = np.ones((480, 640, 3), dtype=np.uint8) * 200
            # Draw a circle (fake face)
            cv2.circle(test_img, (320, 240), 80, (150, 150, 150), -1)
            # Draw eyes
            cv2.circle(test_img, (290, 220), 15, (0, 0, 0), -1)
            cv2.circle(test_img, (350, 220), 15, (0, 0, 0), -1)
            # Draw mouth
            cv2.ellipse(test_img, (320, 270), (40, 20), 0, 0, 180, (0, 0, 0), 2)
        else:
            print(f"Loading image: {image_path}")
            test_img = cv2.imread(str(image_path))
            if test_img is None:
                print(f"❌ Could not load image: {image_path}")
                return False

        # Test recognition
        print("Running face detection and recognition...")
        start_time = time.time()
        faces = app.get(test_img)
        recognition_time = (time.time() - start_time) * 1000

        print(f"✅ Recognition completed in {recognition_time:.2f}ms")
        print(f"✅ Detected {len(faces)} face(s)")

        if len(faces) > 0:
            face = faces[0]
            print(f"✅ Face embedding shape: {face.embedding.shape}")
            print(f"✅ Face bbox: {face.bbox}")
            print(f"✅ Face confidence: {face.det_score:.3f}")

        # Performance check
        if recognition_time < 100:
            print(f"✅ Performance: EXCELLENT (<100ms)")
        elif recognition_time < 200:
            print(f"⚠️  Performance: GOOD (100-200ms)")
        else:
            print(f"⚠️  Performance: ACCEPTABLE but may be slow for real-time")

        return True

    except ImportError:
        print("❌ InsightFace not installed!")
        print("   Install: pip install insightface onnxruntime-gpu")
        return False
    except Exception as e:
        print(f"❌ Error during recognition: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_video_processing(video_path):
    """Test video processing performance"""
    print("\n" + "=" * 50)
    print("Video Processing Test")
    print("=" * 50)

    if not Path(video_path).exists():
        print(f"❌ Video file not found: {video_path}")
        return False

    try:
        from ultralytics import YOLO

        print(f"Loading video: {video_path}")
        cap = cv2.VideoCapture(str(video_path))

        if not cap.isOpened():
            print("❌ Could not open video file")
            return False

        fps = cap.get(cv2.CAP_PROP_FPS)
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        print(f"Video info: {frame_count} frames @ {fps} FPS")

        # Load YOLO
        model = YOLO('yolov8n.pt')

        # Process first 30 frames
        print("Processing first 30 frames...")
        process_times = []
        frame_idx = 0
        max_frames = min(30, frame_count)

        while frame_idx < max_frames:
            ret, frame = cap.read()
            if not ret:
                break

            start_time = time.time()
            results = model(frame, classes=[0], verbose=False)
            process_time = (time.time() - start_time) * 1000
            process_times.append(process_time)

            frame_idx += 1

            if frame_idx % 10 == 0:
                print(f"  Processed {frame_idx}/{max_frames} frames...")

        cap.release()

        # Statistics
        avg_time = np.mean(process_times)
        p95_time = np.percentile(process_times, 95)
        achieved_fps = 1000 / avg_time

        print(f"\n✅ Processed {len(process_times)} frames")
        print(f"✅ Average processing time: {avg_time:.2f}ms")
        print(f"✅ P95 processing time: {p95_time:.2f}ms")
        print(f"✅ Achieved FPS: {achieved_fps:.1f}")

        # Performance evaluation
        if achieved_fps >= 10:
            print(f"✅ Performance: EXCELLENT (≥10 FPS)")
        elif achieved_fps >= 5:
            print(f"✅ Performance: GOOD (5-10 FPS)")
        elif achieved_fps >= 3:
            print(f"⚠️  Performance: ACCEPTABLE (3-5 FPS)")
        else:
            print(f"❌ Performance: TOO SLOW (<3 FPS)")
            print("   System may struggle with real-time processing")

        return True

    except Exception as e:
        print(f"❌ Error during video processing: {e}")
        import traceback
        traceback.print_exc()
        return False


def generate_report(results):
    """Generate final PoC report"""
    print("\n" + "=" * 50)
    print("PROOF OF CONCEPT SUMMARY")
    print("=" * 50)

    all_passed = all(results.values())

    print("\nResults:")
    for test, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"  {test}: {status}")

    print("\n" + "=" * 50)
    if all_passed:
        print("✅ ALL TESTS PASSED!")
        print("\nRecommendation: You can proceed with full development.")
        print("Next steps:")
        print("  1. Review PRE_DEVELOPMENT_CHECKLIST.md")
        print("  2. Collect employee photos for training")
        print("  3. Set up development environment")
        print("  4. Start with Week 1 of DEVELOPMENT_PLAN.md")
    else:
        print("⚠️  SOME TESTS FAILED!")
        print("\nRecommendation: Address issues before proceeding.")
        print("Common solutions:")
        print("  - Install missing dependencies: pip install -r requirements.txt")
        print("  - Check GPU drivers: nvidia-smi")
        print("  - Use lighter models if performance is low")
        print("  - Consider cloud GPU if local hardware insufficient")
    print("=" * 50)

    return all_passed


def main():
    parser = argparse.ArgumentParser(description='ICAM2 Proof of Concept Test')
    parser.add_argument('--image', type=str, help='Path to test image')
    parser.add_argument('--video', type=str, help='Path to test video')
    parser.add_argument('--skip-video', action='store_true', help='Skip video test')
    args = parser.parse_args()

    print("""
    ╔═══════════════════════════════════════════════════════════╗
    ║         ICAM2 - Proof of Concept Test Suite              ║
    ║                                                           ║
    ║  This script verifies that your system is ready for      ║
    ║  ICAM2 development by testing core functionality.        ║
    ╚═══════════════════════════════════════════════════════════╝
    """)

    results = {}

    # Test 1: GPU Check
    results['GPU'] = check_gpu()

    # Test 2: YOLO Detection
    results['Detection'] = test_yolo_detection(args.image)

    # Test 3: Face Recognition
    results['Face Recognition'] = test_face_recognition(args.image)

    # Test 4: Video Processing (optional)
    if not args.skip_video and args.video:
        results['Video Processing'] = test_video_processing(args.video)

    # Generate report
    all_passed = generate_report(results)

    sys.exit(0 if all_passed else 1)


if __name__ == '__main__':
    main()
