import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:team4shoeshop_refactoring/view/edit_profile_page.dart';
import 'buy.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final box = GetStorage();
  List<Map<String, dynamic>> items = [];
  Set<int> selectedOids = {};

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final cid = box.read('p_userId');
    final url = Uri.parse("http://127.0.0.1:8000/cart_items?cid=$cid");
    final response = await http.get(url);

    try {
      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data["result"] is List) {
        setState(() {
          items = List<Map<String, dynamic>>.from(data["result"]);
          selectedOids.clear();
        });
      }
    } catch (e) {
      print("JSON 파싱 에러: $e");
    }
  }

  void toggleSelection(int oid) {
    setState(() {
      if (selectedOids.contains(oid)) {
        selectedOids.remove(oid);
      } else {
        selectedOids.add(oid);
      }
    });
  }

  Future<void> deleteItem(int oid) async {
    final url = Uri.parse("http://127.0.0.1:8000/delete_cart_item/$oid");
    final response = await http.delete(url);
    final data = json.decode(utf8.decode(response.bodyBytes));
    if (data["result"] == "OK") {
      Get.snackbar("삭제 완료", "장바구니에서 삭제되었습니다.");
      fetchCartItems();
    } else {
      Get.snackbar("실패", "삭제 실패");
    }
  }

  Future<void> goToBuy() async {
    if (selectedOids.isEmpty) {
      Get.snackbar("선택 없음", "구매할 항목을 선택해주세요.");
      return;
    }

    final selectedItems = items.where((item) => selectedOids.contains(item["oid"])).toList();
    final cid = box.read('p_userId');

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

    Get.to(() => const BuyPage(), arguments: {
      "items": selectedItems,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("장바구니")),
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text("장바구니가 비어있습니다."))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      // final imageUrl = item["image_url"] + "?t=${DateTime.now().millisecondsSinceEpoch}";
                      final isSelected = selectedOids.contains(item["oid"]);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (_) => toggleSelection(item["oid"]),
                          ),
                          title: Text(item["pname"]),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("색상: ${item["pcolor"]}"),
                              Text("사이즈: ${item["psize"]}"),
                              Text("수량: ${item["count"]}"),
                              Text("가격: ${item["pprice"] * item["count"]}원"),
                              Text("대리점: ${item["ename"]}"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => deleteItem(item["oid"]),
                          ),
                          isThreeLine: true,
                          contentPadding: const EdgeInsets.all(8),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: goToBuy,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("선택한 상품 결제하기"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}