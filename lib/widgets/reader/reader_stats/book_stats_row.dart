import 'package:flutter/cupertino.dart';
import 'package:immersion_reader/data/profile/profile_content_stats.dart';
import 'package:immersion_reader/data/reader/book.dart';
import 'package:immersion_reader/utils/system_theme.dart';
import 'package:immersion_reader/widgets/my_books/book_widget.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BookStatsRow extends StatelessWidget {
  final ProfileContentStats contentStats;
  const BookStatsRow({super.key, required this.contentStats});

  @override
  Widget build(BuildContext context) {
    Widget statsRow(
        {required String label,
        required String value,
        required IconData icon}) {
      return Column(children: [
        Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(width: 2, color: const Color(0xFFDCD8FF))),
            child: FaIcon(
              icon,
              color: const Color(0xFF9B99E9),
              size: 20,
            )),
        Text(value,
            style:
                TextStyle(color: CupertinoColors.label.resolveFrom(context))),
        Text(label,
            style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context))),
      ]);
    }

    Widget progressWidget() {
      double? percentageRead = contentStats.getReadPercentage();
      if (percentageRead == null) {
        return const SizedBox(width: 150);
      }
      return SleekCircularSlider(
          min: 0,
          max: 100,
          initialValue: percentageRead,
          appearance: CircularSliderAppearance(
              size: 150,
              angleRange: 360,
              startAngle: 270,
              infoProperties: InfoProperties(
                  mainLabelStyle: TextStyle(
                      fontSize: 30,
                      fontWeight: isDarkMode() ? FontWeight.w300 : FontWeight.w100,
                      color: CupertinoColors.label.resolveFrom(context))),
              customWidths: CustomSliderWidths(progressBarWidth: 8),
              customColors: CustomSliderColors(
                  progressBarColor: const Color(0xFFDCD8FF),
                  dotColor: const Color(0xFFDCD8FF),
                  hideShadow: true,
                  trackColor: CupertinoColors.systemGroupedBackground)));
    }

    return Column(children: [
      SizedBox(
          height: 200,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            FutureBuilder<Book>(
              future: contentStats.profileContent.getBook(),
              builder: (context, snapshot) {
                return BookWidget(
                    book: snapshot.hasData
                        ? snapshot.data!
                        : Book(title: contentStats.profileContent.title),
                    width: 130,
                    onTap: (mediaIdentifier) {});
              },
            ),
            progressWidget(),
          ])),
      const SizedBox(height: 12),
      Align(
          alignment: Alignment.bottomLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              statsRow(
                  label: 'characters read',
                  value: contentStats.charactersReadPerSecond(),
                  icon: FontAwesomeIcons.font),
              statsRow(
                  label: 'character/sec',
                  value: contentStats.charactersReadPerSecond(),
                  icon: FontAwesomeIcons.bolt),
              statsRow(
                  label: 'words mined',
                  value: contentStats.profileContent.vocabularyMined.toString(),
                  icon: FontAwesomeIcons.solidStar),
            ],
          ))
    ]);
  }
}
