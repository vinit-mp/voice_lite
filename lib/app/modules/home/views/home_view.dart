import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VoIP Call'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Text(
                  controller.isInCall ? 'In Call' : 'Not in Call',
                  style: TextStyle(fontSize: 24),
                )),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() => ElevatedButton(
                      onPressed:
                          controller.isInCall ? null : controller.startCall,
                      child: Text('Start Call'),
                    )),
                SizedBox(width: 20),
                Obx(() => ElevatedButton(
                      onPressed:
                          controller.isInCall ? controller.endCall : null,
                      child: Text('End Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    )),
              ],
            ),
            SizedBox(height: 20),
            Obx(() => IconButton(
                  icon: Icon(
                    controller.isMuted ? Icons.mic_off : Icons.mic,
                    size: 32,
                  ),
                  onPressed: controller.isInCall ? controller.toggleMute : null,
                )),
          ],
        ),
      ),
    );
  }
}
