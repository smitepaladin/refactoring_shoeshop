import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:team4shoeshop_refactoring/dealer/dealer_return_datail.dart';
import 'package:team4shoeshop_refactoring/dealer/dealer_widget/dealer_widget.dart';


class DealerReturn extends StatefulWidget {
  const DealerReturn({super.key});

  @override
  State<DealerReturn> createState() => _DealerReturnState();
}

class _DealerReturnState extends State<DealerReturn> {
  final box = GetStorage();
  List<Map<String, dynamic>> orders = [];
  String eid = '';

  @override
  void initState() {
    super.initState();
    eid = box.read('adminId') ?? '';
    if (eid.isNotEmpty) {
      fetchOrders();
    }
  }

  Future<void> fetchOrders() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/list'));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes))['results'] ?? [];

      final filtered = data
      .where((item) => item['oeid'].toString() == eid)
      .cast<Map<String, dynamic>>()
      .toList();
      setState(() {
        orders = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("반품 요청 관리"),
      ),
      drawer: DealerDrawer(),
      body: orders.isEmpty
          ? const Center(child: Text("주문 내역이 없습니다."))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final item = orders[index];
                final price = item['pprice'] ?? 0;
                final count = item['ocount'] ?? 0;
                final total = price * count;

                return Card(
                  margin: const EdgeInsets.all(10),
                  color:  item['oreturndate'] != null ? Colors.red[300] : null,
                  child: ListTile(
                    title: Text("상품: ${item['pname']} / ${item['ocount']}개"),
                    subtitle: Text("주문일: ${item['odate']}"),
                    trailing: Text("₩$total"),
                    onTap: () async {
                      final result = await Get.to(() => DealerReturnDetail(orderMap: item));
                      if (result == true) {
                        fetchOrders(); 
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
