import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:therapylink/utils/colors.dart';

class JournalingPage extends StatefulWidget {
  final String? entryId;
  final String? initialText;

  const JournalingPage({super.key, this.entryId, this.initialText});

  @override
  State<JournalingPage> createState() => _JournalingPageState();
}

class _JournalingPageState extends State<JournalingPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;

    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMM d, yyyy • hh:mm a').format(now);
    final data = {
      'text': _controller.text.trim(),
      'timestamp': now,
      'formattedDate': formattedDate,
    };

    final entryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('journalEntries');

    if (widget.entryId != null) {
      await entryRef.doc(widget.entryId).update({'text': _controller.text.trim()});
    } else {
      await entryRef.add(data);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.entryId != null ? "Entry updated." : "Entry saved.")),
    );

    Navigator.pop(context);
  }

  void _onEmojiSelected(Emoji emoji) {
    final cursorPos = _controller.selection.base.offset;
    final newText = _controller.text.replaceRange(
      cursorPos,
      cursorPos,
      emoji.emoji,
    );
    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: cursorPos + emoji.emoji.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());
    final time = DateFormat('hh:mm a').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entryId != null ? "Edit Entry" : "Journal of Thoughts",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.bgpurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Today is $date", style: const TextStyle(fontSize: 16, color: Colors.white70)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Time: $time", style: const TextStyle(fontSize: 16, color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Start writing your thoughts...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _showEmojiPicker = !_showEmojiPicker);
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _saveEntry,
                  icon: Icon(widget.entryId != null ? Icons.edit : Icons.save, color: Colors.white),
                  label: Text(widget.entryId != null ? "Update" : "Save Entry",
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bgpurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
                  config: const Config(
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax: 28,
                      columns: 7,
                    ),
                    skinToneConfig: SkinToneConfig(),
                    categoryViewConfig: CategoryViewConfig(),
                    bottomActionBarConfig: BottomActionBarConfig(),
                    searchViewConfig: SearchViewConfig(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
