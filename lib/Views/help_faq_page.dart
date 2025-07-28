import 'package:flutter/material.dart';
import 'package:therapylink/utils/colors.dart';

class HelpFaqPage extends StatefulWidget {
  const HelpFaqPage({Key? key}) : super(key: key);

  @override
  State<HelpFaqPage> createState() => _HelpFaqPageState();
}

class _HelpFaqPageState extends State<HelpFaqPage> {
  final List<Map<String, String>> _faqList = [
    {
      'question': 'How do I reset my password?',
      'answer':
          'Go to the login page and tap on "Forgot Password". Follow the instructions sent to your email.'
    },
    {
      'question': 'How can I change my username?',
      'answer':
          'You can change your username in the Profile Info page by tapping on the edit icon.'
    },
    {
      'question': 'Is my data secure?',
      'answer':
          'Yes, we follow industry-standard practices to ensure your data is protected and private.'
    },
    {
      'question': 'How to contact support?',
      'answer':
          'You can send us feedback or reach out via the Send Feedback section in Settings.'
    },
    {
      'question': 'Can I use this app offline?',
      'answer':
          'Some features are available offline, but you\'ll need internet access for full functionality.'
    },
    {
      'question': 'How do I delete my account?',
      'answer':
          'Go to Settings > Account > Delete Account and follow the steps to confirm your deletion request.'
    },
    {
      'question': 'What platforms does this app support?',
      'answer': 'This app is available for both Android and iOS platforms.'
    },
    {
      'question': 'How do I report a bug or issue?',
      'answer':
          'You can report bugs through the Send Feedback section. Include as much detail as possible.'
    },
    {
      'question': 'Why am I not receiving notifications?',
      'answer':
          'Check your device settings to ensure notifications are enabled for this app.'
    },
    {
      'question': 'Can I sync data between devices?',
      'answer':
          'Yes, just log into the same account across devices and your data will sync automatically.'
    },
  ];

  List<bool> _expanded = [];

  @override
  void initState() {
    super.initState();
    _expanded = List.filled(_faqList.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgpurple,
      appBar: AppBar(
        backgroundColor: AppColors.bgpurple,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.help_outline, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Help & FAQ',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              "Frequently Asked Questions",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _faqList.length,
              itemBuilder: (context, index) {
                final faq = _faqList[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white70,
                      childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      title: Row(
                        children: [
                          const Icon(Icons.question_answer_outlined,
                              color: Colors.white70),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              faq['question']!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            faq['answer']!,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5),
                          ),
                        )
                      ],
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          _expanded[index] = expanded;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
