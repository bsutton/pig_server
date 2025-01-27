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
    pathToLetsEncryptLive = _settings.asString('path_to_lets_encrypt_live',
        defaultValue: '/opt/pigation/letsencrypt/live');
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
  /// /opt/pigation/letsencrypt/live
  String? _pathToLetsEncryptLive;
  bool? _production;
  String? _fqdn;
  String? _domainEmail;
  // if false we handle request via http and don't
  // start the https service.
  bool _useHttps = false;
  int _httpPort = 80;
  int _httpsPort = 443;
  String _bindingAddress = '0.0.0.0';
  String _pathToLogfile = pathToLog;

  Future<void> save() async => _settings.save();

  String get loadedFrom => _settings.filePath;

  set useHttps(bool useHttps) {
    _useHttps = useHttps;
    _settings['use_https'] = useHttps;
  }

  bool get useHttps => _useHttps;

  // Getter and Setter for password
  String? get password => _password;
  set password(String? value) {
    _password = value;
    _settings['password'] = value;
  }

  // Getter and Setter for pathToStaticContent
  String? get pathToStaticContent => _pathToStaticContent;
  set pathToStaticContent(String? value) {
    _pathToStaticContent = value;
    _settings['path_to_static_content'] = value;
  }

  // Getter and Setter for letsEncryptLive
  String? get pathToLetsEncryptLive => _pathToLetsEncryptLive;
  set pathToLetsEncryptLive(String? value) {
    _pathToLetsEncryptLive = value;
    _settings['path_to_lets_encrypt_live'] = value;
  }

  // Getter and Setter for production
  bool? get production => _production;
  set production(bool? value) {
    _production = value;
    _settings['production'] = value;
  }

  // Getter and Setter for fqdn
  String? get fqdn => _fqdn;
  set fqdn(String? value) {
    _fqdn = value;
    _settings['fqdn'] = value;
  }

  // Getter and Setter for domainEmail
  String? get domainEmail => _domainEmail;
  set domainEmail(String? value) {
    _domainEmail = value;
    _settings['domain_email'] = value;
  }

  // Getter and Setter for httpPort
  int get httpPort => _httpPort;
  set httpPort(int value) {
    _httpPort = value;
    _settings['http_port'] = value;
  }

  // Getter and Setter for httpsPort
  int get httpsPort => _httpsPort;
  set httpsPort(int value) {
    _httpsPort = value;
    _settings['https_port'] = value;
  }

  // Getter and Setter for bindingAddress
  String get bindingAddress => _bindingAddress;
  set bindingAddress(String value) {
    _bindingAddress = value;
    _settings['binding_address'] = value;
  }

  // Getter and Setter for pathToLogfile
  String get pathToLogfile => _pathToLogfile;
  set pathToLogfile(String value) {
    _pathToLogfile = value;
    _settings['logger_path'] = value;
  }

  static void init() {
    final dir = dirname(Config.pathToConfigFile);
    if (!exists(dir)) {
      createDir(dir, recursive: true);
    }
    touch(Config.pathToConfigFile, create: true);
  }
}
