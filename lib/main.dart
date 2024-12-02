import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: NepalMapScreen(),
      ),
    );
  }
}

class NepalMapScreen extends StatefulWidget {
  const NepalMapScreen({super.key});

  @override
  State<NepalMapScreen> createState() => _NepalMapScreenState();
}

class _NepalMapScreenState extends State<NepalMapScreen> {
  District? currentDistrict;

  List<District> districts = [];

  @override
  void initState() {
    super.initState();
    loadDistricts();
  }

  loadDistricts() async {
    districts = await loadSvgImage(svgImage: 'assets/bagmati_provience.svg');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bagmati provience'),
      ),
      body: Column(
        children: [
          if (currentDistrict != null) ...[Text(currentDistrict!.id)],
          Expanded(
            child: InteractiveViewer(
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(16.0),
              minScale: 1.0,
              constrained: false,
              child: SizedBox(
                width: size.width < 1200 ? 1200 : size.width,
                height: size.height < 800 ? 800 : size.height,
                child: Stack(
                  children: [
                    for (var district in districts) ...[
                      _getBorder(district: district),
                      _getClippedImage(
                        clipper: DistrictPathClipper(
                          svgPath: district.path,
                        ),
                        color: currentDistrict?.id == district.id
                            ? Colors.green
                            : Color(int.parse('FFD7D3D2', radix: 16)),
                        district: district,
                        onDistrictSelected: onDistrictSelected,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onDistrictSelected(District district) {
    currentDistrict = district;
    setState(() {});
  }

  Widget _getBorder({required District district}) {
    final path = parseSvgPathData(district.path);
    return CustomPaint(
      painter: DistrictBorderPainter(path: path),
    );
  }

  Widget _getClippedImage({
    required DistrictPathClipper clipper,
    required Color color,
    required District district,
    final Function(District district)? onDistrictSelected,
  }) {
    return ClipPath(
      clipper: clipper,
      child: GestureDetector(
        onTap: () => onDistrictSelected?.call(district),
        child: Container(
          color: color,
        ),
      ),
    );
  }
}

Future<List<District>> loadSvgImage({required String svgImage}) async {
  List<District> maps = [];
  String generalString = await rootBundle.loadString(svgImage);

  XmlDocument document = XmlDocument.parse(generalString);

  final paths = document.findAllElements('path');

  for (var element in paths) {
    String partId = element.getAttribute('id') ?? '';
    if (partId.isEmpty || partId == 'Outline') {
      continue;
    }
    String partPath = element.getAttribute('d').toString();

    maps.add(District(id: partId, path: partPath));
  }

  return maps;
}

class District {
  final String id;
  final String path;

  District({
    required this.id,
    required this.path,
  });
}

class DistrictPathClipper extends CustomClipper<Path> {
  DistrictPathClipper({
    required this.svgPath,
  });

  String svgPath;

  @override
  Path getClip(Size size) {
    var path = parseSvgPathData(svgPath);
    final Matrix4 matrix4 = Matrix4.identity();

    matrix4.scale(1.1, 1.1);

    return path.transform(matrix4.storage); //.shift(const Offset(-220, 0));
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return false;
  }
}

class DistrictBorderPainter extends CustomPainter {
  final Path path;
  late final Paint borderPaint;
  final Matrix4 matrix4 = Matrix4.identity();
  DistrictBorderPainter({super.repaint, required this.path}) {
    matrix4.scale(1.1, 1.1);
    borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black;
  }
  @override
  void paint(Canvas canvas, Size size) {
    final path = this.path.transform(matrix4.storage);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
