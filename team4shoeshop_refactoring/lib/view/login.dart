import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:team4shoeshop_refactoring/view/adminlogin.dart';
import 'package:team4shoeshop_refactoring/view/joincustomer.dart';
import 'package:team4shoeshop_refactoring/view/shoeslistpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    initStorage();
  }

  void initStorage() {
    box.write('p_userId', "");
    box.write('p_password', "");
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> login() async {
    final id = userIdController.text.trim();
    final pw = passwordController.text.trim();

    if (id.isEmpty || pw.isEmpty) {
      errorSnackBar();
      return;
    }

    final url = Uri.parse("http://127.0.0.1:8000/login");
    final request = http.MultipartRequest('POST', url);
    request.fields['cid'] = id;
    request.fields['cpassword'] = pw;

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final data = json.decode(resBody);

      if (data["result"] == "success") {
        box.write('p_userId', id);
        _showDialog(data["cname"]);
      } else {
        Get.snackbar(
          '로그인 실패',
          'ID 또는 비밀번호가 잘못되었습니다.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("오류", "서버 오류: $e");
    }
  }

  void _showDialog(String name) {
    Get.defaultDialog(
      title: '환영합니다',
      middleText: '$name 님, 환영합니다.',
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      barrierDismissible: false,
      actions: [
        TextButton(
          onPressed: () {
            saveStorage();
            Get.back();
            Get.to(() => const Shoeslistpage());
          },
          child: const Text('Exit'),
        ),
      ],
    );
  }

  void saveStorage() {
    box.write('p_userId', userIdController.text);
  }

  void errorSnackBar() {
    Get.snackbar(
      '경고',
      '사용자 ID와 암호를 입력하세요',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      colorText: Theme.of(context).colorScheme.onError,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'images/bcdmart.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: userIdController,
                  decoration: InputDecoration(
                    labelText: '사용자 ID를 입력하세요',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '패스워드를 입력하세요',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: login,
                    icon: const Icon(Icons.login),
                    label: const Text('로그인', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Get.to(() => const Joincustomer()),
                      icon: const Icon(Icons.person_add),
                      label: const Text('회원가입'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Get.off(() => const Adminlogin()),
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('관리자 페이지'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}