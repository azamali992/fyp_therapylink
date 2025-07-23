library default_connector;
import 'package:firebase_data_connect/firebase_data_connect.dart';

// Removed invalid import for CallerSDKType.







class DefaultConnector {
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'default',
    'fyptherapylink',
  );

  final FirebaseDataConnect dataConnect;

  DefaultConnector({required this.dataConnect});
  static DefaultConnector get instance {
    return DefaultConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig));
  }
}

