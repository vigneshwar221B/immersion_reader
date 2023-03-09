import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:immersion_reader/data/profile/profile_content.dart';
import 'package:immersion_reader/storage/vocabulary_list_storage.dart';
import 'package:immersion_reader/managers/reader/local_asset_server_manager.dart';
import 'package:immersion_reader/widgets/popup_dictionary/popup_dictionary.dart';
import 'package:immersion_reader/widgets/reader/message_controller.dart';
import 'package:local_assets_server/local_assets_server.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../utils/reader/reader_js.dart';

class Reader extends StatefulWidget {
  final String? initialUrl;
  final bool isAddBook;

  const Reader(
      {super.key,
      this.initialUrl,
      this.isAddBook = false});

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  VocabularyListStorage? vocabularyListStorage;
  InAppWebViewController? webViewController;
  ProfileContent? currentProfileContent;
  late PopupDictionary popupDictionary;
  late MessageController messageController;

  Future<void> createPopupDictionary() async {
    vocabularyListStorage = await VocabularyListStorage.create();
    popupDictionary = PopupDictionary(
        parentContext: context);
    messageController = MessageController(
        popupDictionary: popupDictionary,
        exitCallback: () => Navigator.of(context).pop());
  }

  static const String addFileJs = """
      try {
        document.getElementsByClassName('xl:mr-1')[0].click();
        console.log("injected-open-file")
      } catch {}
      """;

  @override
  Widget build(BuildContext context) {
    LocalAssetsServer? localAssetsServer = LocalAssetsServerManager().server;
    if (localAssetsServer == null) {
      return const Center(
          child: CupertinoActivityIndicator(
        animating: true,
        radius: 24,
      ));
    }
    return SafeArea(
        child: FutureBuilder(
            future: createPopupDictionary(),
            builder: ((context, snapshot) {
              return InAppWebView(
                initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                        cacheEnabled: true, incognito: false)),
                initialUrlRequest: URLRequest(
                  url: Uri.parse(
                    widget.initialUrl ??
                        'http://localhost:${LocalAssetsServerManager.port}',
                  ),
                ),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStop: (controller, uri) async {
                  if (!messageController.hasInjectedPopupJs) {
                    await controller.evaluateJavascript(source: readerJs);
                  }
                  if (widget.isAddBook &&
                      !messageController.hasShownAddedDialog) {
                    await controller.evaluateJavascript(source: addFileJs);
                  }
                },
                onLoadError: (controller, url, code, message) {
                  debugPrint(message);
                },
                onLoadHttpError: (controller, url, statusCode, description) {
                  debugPrint('$statusCode:$description');
                },
                onTitleChanged: (controller, title) async {
                  await controller.evaluateJavascript(source: readerJs);
                  if (widget.isAddBook &&
                      !messageController.hasShownAddedDialog) {
                    await controller.evaluateJavascript(source: addFileJs);
                  }
                },
                onConsoleMessage: (controller, message) {
                  messageController.execute(message);
                },
              );
            })));
  }
}
