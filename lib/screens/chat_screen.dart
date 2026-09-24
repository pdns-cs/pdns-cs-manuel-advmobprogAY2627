import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 52.sp, color: Theme.of(context).colorScheme.primary),
              SizedBox(height: 16.h),
              Text(
                'Chat support is ready',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Text(
                'Use this screen for customer chat or messaging features.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
