import 'package:dogwalkz/services/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  final String walkId;
  final String currentUserName;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfilePicture;

  const ChatPage({
    super.key,
    required this.walkId,
    required this.currentUserName,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfilePicture,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _supabase = Supabase.instance.client;
  List<types.Message> _messages = [];
  late final Stream<List<types.Message>> _messagesStream;
  @override
  void initState() {
    super.initState();
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('walk_id', widget.walkId)
        .order('created_at')
        .map(
          (snapshot) =>
              snapshot
                  .map(
                    (data) => types.TextMessage(
                      author: types.User(
                        id: data['sender_id'],
                        firstName:
                            data['sender_id'] == widget.currentUserId
                                ? 'You'
                                : widget.otherUserName,
                        imageUrl:
                            data['sender_id'] == widget.currentUserId
                                ? null
                                : widget.otherUserProfilePicture,
                      ),
                      createdAt:
                          DateTime.parse(
                            data['created_at'],
                          ).millisecondsSinceEpoch,
                      id: data['id'],
                      text: data['content'],
                    ),
                  )
                  .toList(),
        );
  }

  void _handleSendPressed(types.PartialText message) async {
    final newMessage = types.TextMessage(
      author: types.User(id: widget.currentUserId),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, newMessage);
    });

    await _supabase.from('messages').insert({
      'id': newMessage.id,
      'walk_id': widget.walkId,
      'sender_id': widget.currentUserId,
      'receiver_id': widget.otherUserId,
      'content': message.text,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Send notification to the receiver
    await NotificationService.sendNewMessageNotification(
      receiverId: widget.otherUserId,
      walkId: widget.walkId,
      senderName: widget.currentUserName ?? 'null',
    );
  }

  ///Builds the chat page`s UI
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
      // prevents overflow issue when keyboard is open, allowing the keyboard to be closed first, before the page is popped
      onWillPop: () async {
        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;

        if (isKeyboardOpen) {
          FocusScope.of(context).unfocus();
          await Future.delayed(Duration(milliseconds: 300));
        }

        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/Background.png', fit: BoxFit.cover),
            ),
            Container(
              height: screenHeight * 0.16,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                child: AppBar(
                  centerTitle: true,
                  title: Text(
                    widget.otherUserName,
                    style: GoogleFonts.comicNeue(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.brown,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
              ),
            ),
            Container(
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.16),
                child: StreamBuilder<List<types.Message>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      _messages = snapshot.data!;
                    }
                    // Necessary to overide the default input decoration of the chat, which is taken from our main theme
                    return Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: const InputDecorationTheme(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                        ),
                      ),
                      child: Chat(
                        messages: _messages,
                        onSendPressed: _handleSendPressed,
                        user: types.User(id: widget.currentUserId),
                        theme: DefaultChatTheme(
                          primaryColor: Colors.brown,
                          backgroundColor: Colors.transparent,
                          secondaryColor: const Color(0xFFBCEEFF),

                          inputBackgroundColor: Colors.grey.withOpacity(0.1),
                          inputTextColor: Colors.brown,
                          inputTextStyle: GoogleFonts.comicNeue(
                            fontSize: 18,
                            height: 1.5,
                          ),
                          inputPadding: const EdgeInsets.all(16),

                          inputMargin: const EdgeInsets.all(16),
                          inputBorderRadius: BorderRadius.circular(16),

                          inputContainerDecoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.brown.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.1),
                          ),

                          receivedMessageBodyTextStyle: GoogleFonts.comicNeue(
                            color: Colors.brown,
                          ),
                          sentMessageBodyTextStyle: GoogleFonts.comicNeue(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              top: (screenHeight * 0.16) - 40,
              left: screenWidth / 2 - 60,
              child: GestureDetector(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),

                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.brown.shade100,
                        backgroundImage:
                            widget.otherUserProfilePicture != null
                                ? NetworkImage(widget.otherUserProfilePicture!)
                                : null,
                        child:
                            widget.otherUserProfilePicture == null
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.brown,
                                )
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
