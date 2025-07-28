import 'package:flutter/material.dart';
import 'package:therapylink/utils/colors.dart';

class Question {
  final String text;
  final List<String> options;
  final List<int> scores;
  Question(this.text, this.options, this.scores);
}

class TestPage extends StatefulWidget {
  final String testName;
  const TestPage({super.key, required this.testName});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage>
    with SingleTickerProviderStateMixin {
  List<Question> questions = [];
  int currentIndex = 0;
  int totalScore = 0;
  int? selectedOption;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    questions = _getQuestions(widget.testName);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  List<Question> _getQuestions(String testName) {
    if (testName.contains("Beck")) {
      return [
        Question("1. Sadness", ["I do not feel sad", "I feel sad", "I am sad all the time", "I am so sad or unhappy that I can't stand it"], [0, 1, 2, 3]),
        Question("2. Pessimism", ["I am not discouraged about my future", "I feel discouraged about my future", "I feel I have nothing to look forward to", "I feel my future is hopeless"], [0, 1, 2, 3]),
        Question("3. Past Failure", ["I do not feel like a failure", "I have failed more than I should have", "I feel I have failed more than most people", "I feel I am a complete failure"], [0, 1, 2, 3]),
        Question("4. Loss of Pleasure", ["I get as much pleasure as I used to", "I do not enjoy things as much", "I get very little pleasure from the things I used to enjoy", "I can’t get any pleasure from things I used to enjoy"], [0, 1, 2, 3]),
        Question("5. Guilty Feelings", ["I don’t feel particularly guilty", "I feel guilty over many things", "I feel quite guilty most of the time", "I feel guilty all of the time"], [0, 1, 2, 3]),
        Question("6. Punishment Feelings", ["I don’t feel I am being punished", "I feel I may be punished", "I expect to be punished", "I feel I am being punished"], [0, 1, 2, 3]),
        Question("7. Self-Dislike", ["I feel the same about myself as ever", "I have lost confidence in myself", "I am disappointed in myself", "I dislike myself"], [0, 1, 2, 3]),
        Question("8. Self-Criticalness", ["I don’t criticize myself", "I am more critical of myself", "I criticize myself for all my faults", "I blame myself for everything bad"], [0, 1, 2, 3]),
        Question("9. Suicidal Thoughts", ["I don’t have thoughts of killing myself", "I have thoughts of killing myself but wouldn’t carry them out", "I would like to kill myself", "I would kill myself if I had the chance"], [0, 1, 2, 3]),
        Question("10. Crying", ["I don’t cry anymore than usual", "I cry more now than before", "I cry over every little thing", "I feel like crying but can’t"], [0, 1, 2, 3]),
        Question("11. Agitation", ["I am no more restless than usual", "I am more restless than usual", "I am so restless it is hard to stay still", "I am so restless I have to be moving constantly"], [0, 1, 2, 3]),
        Question("12. Loss of Interest", ["I have not lost interest in other people or activities", "I am less interested in other people", "I have lost most of my interest in other people", "I have lost all interest in other people"], [0, 1, 2, 3]),
        Question("13. Indecisiveness", ["I make decisions as well as before", "I find it more difficult to make decisions", "I have much greater difficulty in making decisions", "I can’t make decisions at all anymore"], [0, 1, 2, 3]),
        Question("14. Worthlessness", ["I do not feel I am worthless", "I don’t consider myself as worthwhile as before", "I feel more worthless compared to others", "I feel utterly worthless"], [0, 1, 2, 3]),
        Question("15. Loss of Energy", ["I have as much energy as before", "I have less energy than before", "I don’t have enough energy to do much", "I don’t have enough energy to do anything"], [0, 1, 2, 3]),
        Question("16. Changes in Sleeping Pattern", ["I sleep as well as usual", "I wake up more tired", "I wake up several hours earlier", "I wake up early and cannot get back to sleep"], [0, 1, 2, 3]),
        Question("17. Irritability", ["I am no more irritable than usual", "I am more irritable than usual", "I am much more irritable than usual", "I am irritable all the time"], [0, 1, 2, 3]),
        Question("18. Changes in Appetite", ["My appetite has not changed", "My appetite is somewhat less", "My appetite is much less", "I have no appetite at all"], [0, 1, 2, 3]),
        Question("19. Concentration Difficulty", ["I can concentrate as well as ever", "I can’t concentrate as well", "It’s hard to keep my mind on anything", "I can’t concentrate on anything"], [0, 1, 2, 3]),
        Question("20. Tiredness or Fatigue", ["I am no more tired than usual", "I get tired more easily", "I am too tired to do many of my usual activities", "I am too tired to do most things"], [0, 1, 2, 3]),
        Question("21. Loss of Interest in Sex", ["I have not noticed any recent change", "I am less interested than before", "I am much less interested in sex", "I have lost interest completely"], [0, 1, 2, 3]),
      ];
    } else if (testName.contains("GAD")) {
      return [
        Question("1. Feeling nervous, anxious, or on edge?", ["Not at all", "Several days", "More than half the days", "Nearly every day"], [0, 1, 2, 3]),
        Question("2. Not being able to stop or control worrying?", ["Not at all", "Several days", "More than half the days", "Nearly every day"], [0, 1, 2, 3]),
        Question("3. Worrying too much about different things?", ["Not at all", "Several days", "More than half the days", "Nearly every day"], [0, 1, 2, 3]),
        Question("4. Trouble relaxing?", ["Not at all", "Several days", "More than half the days", "Nearly every day"], [0, 1, 2, 3]),
        Question("5. Being so restless that it’s hard to sit still?", ["Not at all", "Several days", "More than half the days", "Nearly every day"], [0, 1, 2, 3]),
        Question("6. Becoming easily annoyed or irritable?", ["Not at all", "Several days", "More than half the days", "Nearly every day"], [0, 1, 2, 3]),
        Question("7. Feeling afraid as if something awful might happen?", ["Not at all", "Several days", "More than half the days", "Nearly every day"], [0, 1, 2, 3]),
      ];
    } else if (testName.contains("Stress")) {
      return [
        Question("1. In the last month, how often have you been upset because of something that happened unexpectedly?", ["Never", "Almost never", "Sometimes", "Fairly often", "Very often"], [0, 1, 2, 3, 4]),
        Question("2. Felt that you were unable to control the important things in your life?", ["Never", "Almost never", "Sometimes", "Fairly often", "Very often"], [0, 1, 2, 3, 4]),
        Question("3. Felt nervous and stressed?", ["Never", "Almost never", "Sometimes", "Fairly often", "Very often"], [0, 1, 2, 3, 4]),
        Question("4. Dealt successfully with irritating life hassles?", ["Never", "Almost never", "Sometimes", "Fairly often", "Very often"], [4, 3, 2, 1, 0]),
        Question("5. Felt that you were effectively coping with important changes?", ["Never", "Almost never", "Sometimes", "Fairly often", "Very often"], [4, 3, 2, 1, 0]),
        Question("6. Felt confident about your ability to handle personal problems?", ["Never", "Almost never", "Sometimes", "Fairly often", "Very often"], [4, 3, 2, 1, 0]),
        Question("7. Felt that things were going your way?", ["Never", "Almost never", "Sometimes", "Fairly often", "Very often"], [4, 3, 2, 1, 0]),
        Question("8. Found that you could not cope with all the things you had to do?", ["Never", "Almost never", "Sometimes", "Fairly often", "Very often"], [0, 1, 2, 3, 4]),
        Question("9. Been able to control irritations in your life?", ["Never", "Almost never", "Sometimes", "Fairly often", "Very often"], [4, 3, 2, 1, 0]),
        Question("10. Felt that you were on top of things?", ["Never", "Almost never", "Sometimes", "Fairly often", "Very often"], [4, 3, 2, 1, 0]),
      ];
    } else if (testName.contains("Rosenberg")) {
      return [
        Question("1. On the whole, I am satisfied with myself.", ["Strongly disagree", "Disagree", "Agree", "Strongly agree"], [0, 1, 2, 3]),
        Question("2. At times I think I am no good at all.", ["Strongly disagree", "Disagree", "Agree", "Strongly agree"], [3, 2, 1, 0]),
        Question("3. I feel that I have a number of good qualities.", ["Strongly disagree", "Disagree", "Agree", "Strongly agree"], [0, 1, 2, 3]),
        Question("4. I am able to do things as well as most other people.", ["Strongly disagree", "Disagree", "Agree", "Strongly agree"], [0, 1, 2, 3]),
        Question("5. I feel I do not have much to be proud of.", ["Strongly disagree", "Disagree", "Agree", "Strongly agree"], [3, 2, 1, 0]),
        Question("6. I take a positive attitude toward myself.", ["Strongly disagree", "Disagree", "Agree", "Strongly agree"], [0, 1, 2, 3]),
        Question("7. Overall, I feel that I am a failure.", ["Strongly disagree", "Disagree", "Agree", "Strongly agree"], [3, 2, 1, 0]),
        Question("8. I feel that I’m a person of worth.", ["Strongly disagree", "Disagree", "Agree", "Strongly agree"], [0, 1, 2, 3]),
        Question("9. I wish I could have more respect for myself.", ["Strongly disagree", "Disagree", "Agree", "Strongly agree"], [3, 2, 1, 0]),
        Question("10. All in all, I am inclined to feel that I am a failure.", ["Strongly disagree", "Disagree", "Agree", "Strongly agree"], [3, 2, 1, 0]),
      ];
    } else if (testName.contains("Resilience")) {
      return [
        Question("1. Able to adapt to change", ["Not true at all", "Rarely true", "Sometimes true", "Often true", "True nearly all the time"], [0, 1, 2, 3, 4]),
        Question("2. Can deal with whatever comes", ["Not true at all", "Rarely true", "Sometimes true", "Often true", "True nearly all the time"], [0, 1, 2, 3, 4]),
        Question("3. Try to see the humorous side of things", ["Not true at all", "Rarely true", "Sometimes true", "Often true", "True nearly all the time"], [0, 1, 2, 3, 4]),
        Question("4. Coping with stress strengthens me", ["Not true at all", "Rarely true", "Sometimes true", "Often true", "True nearly all the time"], [0, 1, 2, 3, 4]),
        Question("5. Tend to bounce back after illness or hardship", ["Not true at all", "Rarely true", "Sometimes true", "Often true", "True nearly all the time"], [0, 1, 2, 3, 4]),
        Question("6. Can achieve goals despite obstacles", ["Not true at all", "Rarely true", "Sometimes true", "Often true", "True nearly all the time"], [0, 1, 2, 3, 4]),
        Question("7. Can stay focused under pressure", ["Not true at all", "Rarely true", "Sometimes true", "Often true", "True nearly all the time"], [0, 1, 2, 3, 4]),
        Question("8. Not easily discouraged by failure", ["Not true at all", "Rarely true", "Sometimes true", "Often true", "True nearly all the time"], [0, 1, 2, 3, 4]),
        Question("9. Think of self as strong person", ["Not true at all", "Rarely true", "Sometimes true", "Often true", "True nearly all the time"], [0, 1, 2, 3, 4]),
        Question("10. Make unpopular or difficult decisions", ["Not true at all", "Rarely true", "Sometimes true", "Often true", "True nearly all the time"], [0, 1, 2, 3, 4]),
      ];
    }
    return [];
  }

  void _nextQuestion() {
    if (selectedOption == null) return;
    setState(() {
      totalScore += questions[currentIndex].scores[selectedOption!];
    });

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = null;
      });
      _controller.reset();
      _controller.forward();
    } else {
      _showResultPage();
    }
  }

  void _showResultPage() {
    String resultText = "";
    if (widget.testName.contains("Beck")) {
      if (totalScore <= 13) resultText = "Minimal depression";
      else if (totalScore <= 19) resultText = "Mild depression";
      else if (totalScore <= 28) resultText = "Moderate depression";
      else resultText = "Severe depression";
    } else if (widget.testName.contains("GAD")) {
      if (totalScore <= 4) resultText = "Minimal anxiety";
      else if (totalScore <= 9) resultText = "Mild anxiety";
      else if (totalScore <= 14) resultText = "Moderate anxiety";
      else resultText = "Severe anxiety";
    } else if (widget.testName.contains("Stress")) {
      if (totalScore <= 13) resultText = "Low stress";
      else if (totalScore <= 26) resultText = "Moderate stress";
      else resultText = "High stress";
    } else if (widget.testName.contains("Rosenberg")) {
      if (totalScore >= 26) resultText = "High self-esteem";
      else if (totalScore >= 15) resultText = "Normal self-esteem";
      else resultText = "Low self-esteem";
    } else if (widget.testName.contains("Resilience")) {
      if (totalScore >= 30) resultText = "High resilience";
      else if (totalScore >= 20) resultText = "Moderate resilience";
      else resultText = "Low resilience";
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          testName: widget.testName,
          score: totalScore,
          resultText: resultText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress =
        (currentIndex + 1) / (questions.isNotEmpty ? questions.length : 1);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.testName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.bgpurple,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              Color.fromARGB(255, 55, 13, 104),
              AppColors.backgroundGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(AppColors.bgpink),
              ),
            ),
            const SizedBox(height: 20),
            SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Question ${currentIndex + 1}/${questions.length}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    questions[currentIndex].text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(
                    questions[currentIndex].options.length,
                    (index) => GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedOption = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selectedOption == index
                              ? AppColors.bgpink.withOpacity(0.8)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedOption == index
                                ? Colors.white
                                : Colors.white38,
                          ),
                        ),
                        child: Text(
                          questions[currentIndex].options[index],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: selectedOption != null ? _nextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgpink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  currentIndex == questions.length - 1 ? "Finish" : "Next",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String testName;
  final int score;
  final String resultText;

  const ResultPage(
      {super.key,
      required this.testName,
      required this.score,
      required this.resultText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Your Result", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.bgpurple,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundGradientStart,
              Color.fromARGB(255, 55, 13, 104),
              AppColors.backgroundGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              testName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Score: $score",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              resultText,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bgpink,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Back to Tests",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
