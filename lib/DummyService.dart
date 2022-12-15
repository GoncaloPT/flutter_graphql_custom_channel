import 'dart:async';
import 'dart:convert';

import 'package:graphql/client.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


/// This is the most important class for the demonstration
class GraphQLClientFactory {
  final fakeUrl = "wss://blabla";
  final fakeHttpUrl = "https://countries.trevorblades.com/";

  /// Important part of the demonstration is here
  GraphQLClient build() {
    final wsLink = WebSocketLink(fakeUrl,
        subProtocol: GraphQLProtocol.graphqlTransportWs,
        config: SocketClientConfig(
            autoReconnect: false,
            /// using connectFn to pass a  [WebSocketChannel]
            /// which we hold 2 stream controllers to "spy" and react
            /// to every data that "flows" both ways
            connectFn: (url, protocols) async {
              StreamController<List<int>> downstreamController =
                  StreamController();
              // data we which to send to the backend
              StreamController<List<int>> upstreamController =
                  StreamController();
              upstreamController.stream
                  .asBroadcastStream()
                  .listen((event) async {
                // in here we should be trying to send the first ack
                Object obj = event;
                String? base64Event = '';
                try {
                  base64Event = String.fromCharCodes(
                      base64.decode(String.fromCharCodes(event)));
                } catch (err) {
                  base64Event = "$err";
                }
                String asString = String.fromCharCodes(event);
                print('======================================================');
                print('PRINTING POSSIBLE CONVERSIONS FROM UPSTREAM MESSAGE ');
                print('originalEvent: $event');
                print('base64Event: $base64Event');
                print('obj: $obj ');
                print('obj: $asString ');
                print('======================================================');
                //await websocketSession.sendByteData(event);
              });
              final customChannel = StreamChannel.withGuarantees(
                downstreamController.stream,
                upstreamController.sink,
                allowSinkErrors: false,
              );
              return WebSocketChannel(
                customChannel,
                serverSide: false,
                pingInterval: Duration(seconds: 1),
                //protocol: GraphQLProtocol.graphqlTransportWs,
              );
            }));
    final httpLink = HttpLink(
      fakeHttpUrl,
      defaultHeaders: {
        "Accept": "application/json",
      },
    );
    return GraphQLClient(
      link: Link.from([
        Link.split((req) => req.isSubscription, wsLink, httpLink),
      ]),
      cache: GraphQLCache(),
    );
  }
}

/// Ignore the service for demonstration purposes
class DummyService {
  final GraphQLClient client;
  final StreamController<String> streamController = StreamController();

  DummyService(GraphQLClientFactory factory) : client = factory.build();

  Stream<String> getCountries() {
    client.query(QueryOptions(document: gql(r'''
      query {
        countries {
          name
        }
      }
      '''))).then((result) {
      streamController.add(result.data!['countries'][0]['name'] as String);
    });

    return streamController.stream;
  }

  /// Just to open a websocket, it is enough for the demonstration
  Stream<String> getCountries2() {
    return client
        .subscribe(
      SubscriptionOptions(document: gql(r'''
        subscription {
          countries {
            name
          }
        }
        ''')),
    )
        .map((result) => result.data!['countries'][0]['name'] as String);
  }
}
