import 'package:flutter_dotenv/flutter_dotenv.dart';

// API base URL, loaded from assets/.env at startup.
var host = dotenv.env['HOST'];