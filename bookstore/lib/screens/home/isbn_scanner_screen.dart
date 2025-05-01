// barcode_scanner_page.dart
import 'package:bookstore/services/book_information_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  late CameraController _controller;
  late BarcodeScanner _barcodeScanner;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  bool _showCamera = true;

  @override
  void initState() {
    super.initState();
    _initScanner();
    _barcodeScanner = GoogleMlKit.vision.barcodeScanner();
  }

  Future<void> _initScanner() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _controller.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
    _controller.startImageStream(_processCameraImage);
  }

  void _resetScanner() async {
    setState(() {
      _showCamera = true;
    });
    _isDetecting = false;
    await _controller.startImageStream(_processCameraImage);
  }

  void _showConfirmationDialog(
    String barcode,
    Map<String, dynamic> bookData,
  ) async {
    print(bookData);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(bookData["title"] ?? "Unkown Title"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bookData["imageLinks"]["thumbnail"] != null)
                  Image.network(
                    bookData["imageLinks"]["thumbnail"],
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(height: 10),
                Text("Author: ${bookData["authors"] ?? "Unknown"}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).maybePop();
                  _resetScanner();
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  Navigator.of(context).maybePop();

                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .collection("books")
                        .add({
                          "isbn": barcode,
                          "title": bookData["title"] ?? "",
                          "authors": bookData["authors"],
                          "cover": bookData["imageLinks"]["thumbnail"],
                          "scannedAt": Timestamp.now(),
                        });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Book saved to Firestore!")),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text("Add To Library"),
              ),
            ],
          ),
    );
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );

    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final barcode = barcodes.first.displayValue;

        if (barcode != null && mounted) {
          await _controller.stopImageStream();
          setState(() => _showCamera = false);

          final bookData = await fetchBookByIsbn(barcode);

          if (bookData != null) {
            _showConfirmationDialog(barcode, bookData);
          } else {
            _resetScanner();
          }
        } else {
          _resetScanner();
        }
      } else {
        _isDetecting = false;
      }
    } catch (e) {
      if (mounted) {
        SnackBar(
          content: Text("Error scanning or adding book. Please try again."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
      }
    }

    _isDetecting = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isCameraInitialized
              ? Stack(
                children: [
                  if (_showCamera)
                    SizedBox.expand(child: CameraPreview(_controller)),
                  if (_showCamera)
                    Center(
                      child: Container(
                        width: 250,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                    ),
                ],
              )
              : Center(child: CircularProgressIndicator()),
    );
  }
}
