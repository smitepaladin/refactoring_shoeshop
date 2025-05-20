import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:team4shoeshop_refactoring/view/edit_profile_page.dart';
import 'buy.dart';

class ShoesDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final int selectedSize;

  const ShoesDetailPage({
    required this.product,
    required this.selectedSize,
    super.key,
  });

  @override
  State<ShoesDetailPage> createState() => _ShoesDetailPageState();
}

class _ShoesDetailPageState extends State<ShoesDetailPage> {
  final box = GetStorage();
  int quantity = 1;
  List<Map<String, dynamic>> dealers = [];
  String? selectedDealer;

  @override
  void initState() {
    super.initState();
    fetchDealers();
  }

  Future<void> fetchDealers() async {
    final response = await http.get(Uri.parse("http://127.0.0.1:8000/employee_list"));
    final data = json.decode(utf8.decode(response.bodyBytes));
    if (data["result"] is List) {
      setState(() {
        dealers = List<Map<String, dynamic>>.from(data["result"]);
        if (dealers.isNotEmpty) {
          selectedDealer = dealers.first["eid"];
        }
      });
    }
  }

  Future<void> addToCart() async {
    final cid = box.read("p_userId");
    if (cid == null || selectedDealer == null) return;

    final request = http.MultipartRequest("POST", Uri.parse("http://127.0.0.1:8000/add_to_cart"));
    request.fields["cid"] = cid;
    request.fields["pid"] = widget.product["pid"];
    request.fields["count"] = quantity.toString();
    request.fields["oeid"] = selectedDealer!;

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = json.decode(body);

    if (data["result"] == "OK") {
      Get.snackbar("성공", "장바구니에 추가되었습니다.");
    } else {
      Get.snackbar("실패", "장바구니 추가 실패");
    }
  }

  Future<void> goToBuy() async {
    final cid = box.read("p_userId");
    if (cid == null || selectedDealer == null) return;

    final res = await http.get(Uri.parse("http://127.0.0.1:8000/customer_info?cid=$cid"));
    final data = json.decode(utf8.decode(res.bodyBytes));

    if (data["result"] != "OK" ||
        data["ccardnum"] == null ||
        data["ccardcvc"] == null ||
        data["ccarddate"] == null) {
      Get.snackbar("카드 정보 없음", "회원정보 수정이 필요합니다.");
      await Future.delayed(const Duration(seconds: 1));
      Get.to(() => EditProfilePage());
      return;
    }

    final dealerName = dealers.firstWhere((e) => e["eid"] == selectedDealer)["ename"];

    Get.to(() => const BuyPage(), arguments: {
      "product": widget.product,
      "quantity": quantity,
      "storeId": selectedDealer,
      "storeName": dealerName,
      "selectedSize": widget.selectedSize,
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imageUrl = "http://127.0.0.1:8000/view/${p['pid']}?t=${DateTime.now().millisecondsSinceEpoch}";
    final pstock = (p["pstock"] is int) ? p["pstock"] : int.tryParse(p["pstock"].toString()) ?? 0;
    final isOutOfStock = pstock == 0;

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(title: const Text("상품 상세")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: Text("이미지 없음")),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(p["pname"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("브랜드: ${p["pbrand"]}", style: const TextStyle(fontSize: 14)),
            Text("${p["pprice"]}원", style: const TextStyle(color: Colors.red)),
            Text("색상: ${p["pcolor"]}"),
            Text("사이즈: ${widget.selectedSize}"),
            const SizedBox(height: 12),
            if (isOutOfStock)
              const Text("❌ 품절된 상품입니다", style: TextStyle(color: Colors.red)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("수량", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: quantity,
                  items: List.generate(pstock, (i) => i + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text("$e")))
                      .toList(),
                  onChanged: isOutOfStock ? null : (v) => setState(() => quantity = v!),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("대리점", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedDealer,
                  items: dealers.map((dealer) {
                    return DropdownMenuItem<String>(
                      value: dealer["eid"],
                      child: Text(dealer["ename"]),
                    );
                  }).toList(),
                  onChanged: isOutOfStock ? null : (val) => setState(() => selectedDealer = val),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isOutOfStock ? null : addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOutOfStock ? Colors.grey : Colors.purple[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("장바구니"),
                ),
                ElevatedButton(
                  onPressed: isOutOfStock ? null : goToBuy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOutOfStock ? Colors.grey : Colors.amberAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("구매하기"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}