<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

A simple project handling cache management in a Flutter app. 
This is using Riverpod, Sembast & GraphQL.

## Features

There's tons of things to do, as it's just an export of my repository system. 
For the moment, explore the package to see what you can do with it :)

## Getting started

In your Material App, simply add 
```dart
 @override
 void initState() {
    super.initState();
    ref.read(configurationProvider).init(
        Configuration(
            graphqlEndpoint: ...,
            basicUsername: ...,
            basicPassword: ...,
        ),
    );
 }
```

## Additional information

Work in progress.
