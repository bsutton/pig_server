import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:settings_yaml/settings_yaml.dart';

class Config {
  factory Config() => _config ??= Config._(pathToConfigFile);

  factory Config.fromDebugPath() {
    _config = Config._(join('config', 'config.yaml'));
    return _config!;
  }

  Config._(String loadFrom) {
    _settings = SettingsYaml.load(pathToSettings: loadFrom);

    password = _settings.asString('password');
    pathToStaticContent = _settings.asString('path_to_static_content');
    letsEncryptLive = _settings.asString('lets_encrypt_live',
        defaultValue: '/opt/ihs/letsencrypt/live');
    fqdn = _settings.asString('fqdn');
    domainEmail = _settings.asString('domain_email');
    httpsPort = _settings.asInt('https_port', defaultValue: 443);
    httpPort = _settings.asInt('http_port', defaultValue: 80);
    production = _settings.asBool('production', defaultValue: false);
    useHttps = _settings.asBool('use_https', defaultValue: false);
    bindingAddress =
        _settings.asString('binding_address', defaultValue: '0.0.0.0');
    pathToLogfile = _settings.asString('logger_path', defaultValue: 'print');
  }
  static final pathToLog = join(rootPath, 'var', 'log', 'pig_server.log');

  static final pathToConfigFile =
      join(rootPath, 'opt', 'pigation', 'config', 'config.yaml');
  static Config? _config;

  late final SettingsYaml _settings;

  String? _password;
  String? _pathToStaticContent;

  /// Path to the lets encrypt certiicates normally
  /// /etc/letsencrypt/live
  String? _letsEncryptLive;

  bool? _production;

  String? _fqdn;

  String? _domainEmail;

  // if false we handle request via http and don't
  // start the https service.
  bool _useHttps = false;
  final int _httpPort = 80;
  final int _httpsPort = 443;
  final String _bindingAddress = '0.0.0.0';

  final String _pathToLogfile = pathToLog;

  Future<void> save() async => _settings.save();

  /// Returns the path the [Config] was loaded from.
  String get loadedFrom => _settings.filePath;

  bool get useHttps => _useHttps;

  set useHttps(bool useHttps) {
    _useHttps = useHttps;
    _settings['use_https'] = useHttps;
  }

  static void init() {
    final dir = dirname(Config.pathToConfigFile);
    if (!exists(dir)) {
      createDir(dir, recursive: true);
    }
    touch(Config.pathToConfigFile, create: true);
  }
}
