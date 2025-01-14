import 'dart:io';

bool isRaspberryPi() {
  final cpuInfoFile = File('/proc/cpuinfo');
  if (!cpuInfoFile.existsSync()) {
    return false; // Not a Linux system or missing the file
  }

  final cpuInfo = cpuInfoFile.readAsStringSync();
  return cpuInfo.contains('BCM') || cpuInfo.contains('Raspberry Pi');
}
