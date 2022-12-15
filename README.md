# flutter_graphql_custom_channel

Demonstration of the issue created for graphQL dart libraty

## What to see

- Look into DummyService.dart 
- Run the project and see the prints

## Conclusions
It is not clear how to use connectFn to pass a different WebSocketChannel to graphQL.  
The sink used by graqhQL seems to be declared as dynamic, and it is feed with String values, but the WebSocketChannel
mandates the usage of List<int>.  
The data that we can capture in the sink is of an unkown format, and therefore useless.  

Some evidence of this can be seen in the prints produced by running this project:  
```
flutter: ======================================================
flutter: PRINTING POSSIBLE CONVERSIONS FROM UPSTREAM MESSAGE
flutter: originalEvent: [129, 154, 77, 223, 32, 209]
flutter: base64Event: FormatException: Invalid character (at character 1)
Mß Ñ
^
flutter: obj: [129, 154, 77, 223, 32, 209]
flutter: obj: Mß Ñ
```
