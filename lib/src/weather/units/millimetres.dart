import 'package:fixed/fixed.dart';

class Millimetres {
  Millimetres(String millimetres) : millimetres = Fixed.parse(millimetres);
  final Fixed millimetres;

  @override
  String toString() => 'Millimetres=$millimetres';
}
