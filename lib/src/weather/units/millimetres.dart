import 'package:fixed/fixed.dart';

class Millimetres {
  final Fixed millimetres;

  Millimetres(String millimetres) : millimetres = Fixed.parse(millimetres);

  @override
  String toString() => 'Millimetres=$millimetres';
}
