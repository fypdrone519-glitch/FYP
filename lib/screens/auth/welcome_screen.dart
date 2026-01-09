import 'package:car_listing_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/welcome_screen_image.png', // or Image.network for URL
              fit: BoxFit.cover,
            ),
          ),
          //Heading and Subheading
          SafeArea(
            child: Container(
              width: MediaQuery.of(context).size.width,// To make it full width
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Share Lane',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'The Safe Way to Share.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child:SafeArea(
              top:false,
              child:Center(
                child: HorizontalSlider(
                  onSlideComplete: () {
                    // Navigate to Login Screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              )
            )
          ),
        ],
      )
    );
  }
}

class HorizontalSlider extends StatefulWidget {
  final VoidCallback onSlideComplete;
  
  const HorizontalSlider({
    Key? key,
    required this.onSlideComplete,
  }) : super(key: key);

  @override
  State<HorizontalSlider> createState() => _HorizontalSliderState();
}

class _HorizontalSliderState extends State<HorizontalSlider> {
  double _dragPosition = 5.0;
  double _maxDrag = 0.0;
  bool _isDragging = false;
  
  @override
    double get _rotationAngle {
    final progress = (_dragPosition / _maxDrag).clamp(0.0, 1.0);
    return progress * 1.5708; // ~20 degrees max
  }
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate max drag distance (container width - icon width)
          _maxDrag = constraints.maxWidth - 70;
          
          return GestureDetector(
            onHorizontalDragStart: (details) {
              setState(() {
                _isDragging = true;
              });
            },
            onHorizontalDragUpdate: (details) {
              setState(() {
                // Update drag position, constrained between 0 and maxDrag
                _dragPosition += details.delta.dx;
                _dragPosition = _dragPosition.clamp(0.0, _maxDrag);
              });
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                _isDragging = false;
                
                // Check if slider reached the end (90% threshold)
                if (_dragPosition >= _maxDrag * 0.9) {
                  // Complete the slide
                  _dragPosition = _maxDrag;
                  widget.onSlideComplete();
                } else {
                  // Snap back to start
                  _dragPosition=5.0;
                }
              });
            },
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                color: Colors.grey[300],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Green Progress Track
                  AnimatedContainer(
                    duration: _isDragging 
                        ? Duration.zero 
                        : Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: _dragPosition +65, // +70 for icon width
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      gradient: LinearGradient(
                        colors: [
                          Color(0x245CD2) .withOpacity(0.8),
                          Color(0x245CD2).withOpacity(1.0),
                        ],
                      ),
                    ),
                    child: ClipRect(
                      child: CustomPaint(
                        painter: _DottedLinesPainter(),
                      ),
                    ),
                  ),
                  
                  // Sliding Car Icon
                  AnimatedPositioned(
                    duration: _isDragging 
                        ? Duration.zero 
                        : Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    left: _dragPosition,
                    top: 5,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Transform.rotate(
                          angle: _rotationAngle,
                          child: Image.asset(
                            'lib/assets/slider_icon.png',
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Text Hint (fades as you slide)
                  if (_dragPosition < _maxDrag * 0.3)
                    Center(
                      child: Opacity(
                        opacity: 1 - (_dragPosition / (_maxDrag * 0.3)),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 100.0),
                          child: Row(
                            children: [
                              Text(
                                'Slide to start',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.grey[500],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DottedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashWidth = 10.0;
    final dashSpace = 8.0;
    // Y positions for the two dotted lines
    final yPositions = [
      size.height * 0.35,
      size.height * 0.65,
    ];

    for (final y in yPositions) {
      double startX = 12; // horizontal padding

      while (startX < size.width - 12) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}