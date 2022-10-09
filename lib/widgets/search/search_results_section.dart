import 'package:flutter/cupertino.dart';
import 'package:immersion_reader/data/search/search_result.dart';
import 'package:immersion_reader/japanese/vocabulary.dart';

class SearchResultsSection extends StatefulWidget {
  final SearchResult searchResult;
  final BuildContext parentContext;
  const SearchResultsSection(
      {super.key, required this.searchResult, required this.parentContext});

  @override
  State<SearchResultsSection> createState() => _SearchResultsSectionState();
}

class _SearchResultsSectionState extends State<SearchResultsSection> {
  final textColor = const CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.darkBackgroundGray,
    darkColor: CupertinoColors.lightBackgroundGray,
  );

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CupertinoListSection(header: const Text('Exact Matches'), children: [
        ...widget.searchResult.exactMatches.map((Vocabulary vocabulary) {
          return VocabularyTile(
              vocabulary: vocabulary,
              parentContext: widget.parentContext,
              textColor: textColor);
        })
      ]),
      CupertinoListSection(header: const Text('Additional Matches'), children: [
        ...widget.searchResult.additionalMatches.map((Vocabulary vocabulary) {
          return VocabularyTile(
              vocabulary: vocabulary,
              parentContext: widget.parentContext,
              textColor: textColor);
        })
      ])
    ]);
  }
}

class VocabularyTile extends StatelessWidget {
  final Vocabulary vocabulary;
  final CupertinoDynamicColor textColor;
  final BuildContext parentContext;
  const VocabularyTile(
      {super.key,
      required this.vocabulary,
      required this.textColor,
      required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CupertinoListTile(
          title: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                      text: vocabulary.expression ?? '',
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const WidgetSpan(
                            child: SizedBox(
                          width: 20,
                        )),
                        TextSpan(
                            text: vocabulary.reading ?? '',
                            style: const TextStyle(
                                color: CupertinoColors.inactiveGray))
                      ])))),
      Padding(
          padding: const EdgeInsetsDirectional.only(
              start: 20.0, end: 14.0, bottom: 5.0),
          child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(vocabulary.getCompleteGlossary(),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: CupertinoDynamicColor.resolve(
                            textColor, parentContext),
                      )))))
    ]);
  }
}
