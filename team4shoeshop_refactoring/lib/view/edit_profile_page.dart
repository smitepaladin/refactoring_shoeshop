import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:remedi_kopo/remedi_kopo.dart';
import 'package:team4shoeshop_refactoring/view/shoeslistpage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final box = GetStorage();

  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController(); // 최종 주소
  final detailAddressController = TextEditingController(); // 상세 주소
  final cardNumController = TextEditingController();
  final cardCvcController = TextEditingController();
  final cardDateController = TextEditingController();

  String userId = '';
  String basicAddress = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userId = box.read('p_userId') ?? '';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (userId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8000/customer_info?cid=$userId');
    final response = await http.get(url);
    final data = json.decode(utf8.decode(response.bodyBytes));

    if (data['result'] == 'OK') {
      nameController.text = data['cname'] ?? '';
      passwordController.text = data['cpassword'] ?? '';
      phoneController.text = data['cphone'] ?? '';
      emailController.text = data['cemail'] ?? '';
      addressController.text = data['caddress'] ?? '';

      // 초기 로딩 시 address에서 기본주소 추출
      final parts = addressController.text.split(' ');
      basicAddress = parts.take(3).join(' '); // 대략 주소 앞 3단어로 추정
      detailAddressController.text = addressController.text.replaceFirst(basicAddress, '').trim();

      cardNumController.text = (data['ccardnum'] ?? 0) != 0
          ? formatCardNumber(data['ccardnum'].toString())
          : '';
      cardCvcController.text = (data['ccardcvc'] ?? 0).toString();
      cardDateController.text = (data['ccarddate'] ?? 0).toString();
    }

    setState(() => isLoading = false);
  }

  void _combineAddress() {
    final detail = detailAddressController.text.trim();
    final full = '$basicAddress ${detail.isNotEmpty ? detail : ''}'.trim();
    addressController.text = full;
  }

  Future<void> _searchAddress() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => RemediKopo()));
    if (result is KopoModel && result.address != null) {
      setState(() {
        basicAddress = result.address!;
        _combineAddress();
      });
    }
  }

  Future<void> _updateProfile() async {
    final url = Uri.parse('http://127.0.0.1:8000/update_customer');
    final request = http.MultipartRequest('POST', url);

    final cardDateText = cardDateController.text.trim();
    if (cardDateText.length != 4 ||
        int.tryParse(cardDateText.substring(2)) == null ||
        int.parse(cardDateText.substring(2)) < 1 ||
        int.parse(cardDateText.substring(2)) > 12) {
      Get.snackbar("입력 오류", "유효기간은 YYMM 형식의 4자리 숫자여야 하며, MM은 01~12입니다.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    request.fields['cid'] = userId;
    request.fields['cname'] = nameController.text.trim();
    request.fields['cpassword'] = passwordController.text.trim();
    request.fields['cphone'] = phoneController.text.trim();
    request.fields['cemail'] = emailController.text.trim();
    request.fields['caddress'] = addressController.text.trim();
    request.fields['ccardnum'] =
        cardNumController.text.replaceAll('-', '').trim().isEmpty
            ? '0'
            : cardNumController.text.replaceAll('-', '');
    request.fields['ccardcvc'] = cardCvcController.text.trim().isEmpty
        ? '0'
        : cardCvcController.text.trim();
    request.fields['ccarddate'] = cardDateText;

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = json.decode(body);

      if (data['result'] == 'OK') {
        Get.snackbar("수정 완료", "회원정보가 저장되었습니다.",
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2));
        Future.delayed(const Duration(seconds: 1), () {
          Get.offAll(() => const Shoeslistpage());
        });
      } else {
        Get.snackbar("오류", "수정 실패", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("에러", "서버 오류: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool readOnly = false,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        keyboardType: keyboard,
        inputFormatters: formatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.edit),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  String formatCardNumber(String number) {
    number = number.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      buffer.write(number[i]);
      if ((i + 1) % 4 == 0 && i + 1 != number.length) buffer.write('-');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원정보 수정")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildField(nameController, '이름'),
                  _buildField(passwordController, '비밀번호', obscure: true),
                  _buildField(
                    phoneController,
                    '전화번호',
                    keyboard: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      PhoneNumberFormatter(),
                    ],
                  ),
                  _buildField(emailController, '이메일'),
                  const SizedBox(height: 16),

                  /// 주소 검색 버튼
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          basicAddress.isNotEmpty
                              ? basicAddress
                              : '주소를 선택해주세요',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _searchAddress,
                        icon: const Icon(Icons.search),
                        label: const Text('주소 검색'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildField(detailAddressController, '상세 주소',
                      onChanged: (_) => _combineAddress()),
                  _buildField(addressController, '최종 주소 (자동완성)', readOnly: true),

                  const Divider(height: 32),
                  _buildField(
                    cardNumController,
                    '카드번호',
                    keyboard: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      CardNumberFormatter(),
                    ],
                  ),
                  _buildField(
                    cardCvcController,
                    'CVC',
                    keyboard: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                  _buildField(
                    cardDateController,
                    '유효기간 (YYMM)',
                    keyboard: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _updateProfile,
                      icon: const Icon(Icons.check),
                      label: const Text('수정 완료', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

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

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i + 1 != digits.length) buffer.write('-');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted.length > 19 ? formatted.substring(0, 19) : formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}