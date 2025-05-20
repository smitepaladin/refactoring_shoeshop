import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:remedi_kopo/remedi_kopo.dart';
import 'package:team4shoeshop_refactoring/view/login.dart';

class Joincustomer extends StatefulWidget {
  const Joincustomer({super.key});

  @override
  State<Joincustomer> createState() => _JoincustomerState();
}

class _JoincustomerState extends State<Joincustomer> {
  final TextEditingController cidController = TextEditingController();
  final TextEditingController cnameController = TextEditingController();
  final TextEditingController cpasswordController = TextEditingController();
  final TextEditingController cphoneController = TextEditingController();
  final TextEditingController cemailController = TextEditingController();
  final TextEditingController detailAddressController = TextEditingController();
  final TextEditingController caddressController = TextEditingController();

  String basicAddress = '';
  bool isCidChecked = false;

  void _combineAddress() {
    final detail = detailAddressController.text.trim();
    final full = '$basicAddress ${detail.isNotEmpty ? detail : ''}'.trim();
    caddressController.text = full;
  }

  Future<void> _searchAddress() async {
    KopoModel? model = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RemediKopo()),
    );

    if (model != null && model.address != null) {
      setState(() {
        basicAddress = model.address!;
        _combineAddress();
      });
    }
  }

  Future<void> checkCidDuplicate() async {
    final cid = cidController.text.trim();
    if (cid.isEmpty) {
      Get.snackbar('오류', 'ID를 입력하세요', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      final url = Uri.parse("http://127.0.0.1:8000/check_customer_id?cid=$cid");
      final response = await http.get(url);
      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data["result"] == "exists") {
        Get.snackbar('중복된 ID', '이미 사용 중인 ID입니다.', backgroundColor: Colors.orange, colorText: Colors.white);
        setState(() => isCidChecked = false);
      } else {
        Get.snackbar('사용 가능', '사용 가능한 ID입니다.', backgroundColor: Colors.green, colorText: Colors.white);
        setState(() => isCidChecked = true);
      }
    } catch (e) {
      Get.snackbar("오류", "서버 오류: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _join() async {
    if (!isCidChecked) {
      Get.snackbar('확인 필요', 'ID 중복 확인을 먼저 해주세요.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (cidController.text.trim().isEmpty ||
        cnameController.text.trim().isEmpty ||
        cpasswordController.text.trim().isEmpty) {
      Get.snackbar('오류', 'ID, 이름, 비밀번호는 필수 입력입니다.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final url = Uri.parse("http://127.0.0.1:8000/insert_customer");
    final request = http.MultipartRequest('POST', url);

    request.fields['cid'] = cidController.text.trim();
    request.fields['cname'] = cnameController.text.trim();
    request.fields['cpassword'] = cpasswordController.text.trim();
    request.fields['cphone'] = cphoneController.text.trim();
    request.fields['cemail'] = cemailController.text.trim();
    request.fields['caddress'] = caddressController.text.trim();

    try {
      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final data = json.decode(resBody);

      if (data["result"] == "OK") {
        Get.snackbar("성공", "회원가입이 완료되었습니다.", backgroundColor: Colors.green, colorText: Colors.white);
        Future.delayed(const Duration(seconds: 1), () {
          Get.offAll(() => const LoginPage());
        });
      } else {
        Get.snackbar("실패", "회원가입에 실패했습니다.", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("오류", "서버 오류: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(cidController, '아이디', Icons.person_outline,
                      onChanged: (_) => setState(() => isCidChecked = false)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: checkCidDuplicate, child: const Text('중복 확인')),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(cnameController, '이름', Icons.badge),
            const SizedBox(height: 16),
            _buildTextField(cpasswordController, '비밀번호', Icons.lock_outline, obscure: true),
            const SizedBox(height: 16),
            TextField(
              controller: cphoneController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                PhoneNumberFormatter(),
              ],
              decoration: _inputDecoration('전화번호', Icons.phone_android),
            ),
            const SizedBox(height: 16),
            _buildTextField(cemailController, '이메일', Icons.email_outlined),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    basicAddress.isNotEmpty ? basicAddress : '주소를 선택하세요.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  onPressed: _searchAddress,
                  icon: const Icon(Icons.search),
                  label: const Text('주소 검색'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(detailAddressController, '상세 주소', Icons.home_outlined,
                onChanged: (_) => _combineAddress()),
            const SizedBox(height: 16),
            TextField(
              controller: caddressController,
              readOnly: true,
              decoration: _inputDecoration('최종 주소 (자동완성)', Icons.location_on, fillColor: Colors.grey[200]!),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _join,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('가입하기', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscure = false, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Color? fillColor}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: fillColor ?? Colors.grey[100],
    );
  }
}

// 전화번호 하이픈 자동 포맷터
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 2 || i == 6) buffer.write('-');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted.length > 13 ? formatted.substring(0, 13) : formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}