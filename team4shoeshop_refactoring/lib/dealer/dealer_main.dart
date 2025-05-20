import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:team4shoeshop_refactoring/dealer/dealer_widget/dealer_widget.dart';

class DealerMain extends StatefulWidget {
  const DealerMain({super.key});

  @override
  State<DealerMain> createState() => _DealerMainState();
}

class _DealerMainState extends State<DealerMain> {
  final box = GetStorage();
  List data = [];
  List<Map<String, dynamic>> groupedData = [];
  String eid = '';
  String dadminname = '';
  String dal = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
  int totalsales = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100), () async {
      eid = box.read('adminId') ?? '';
      if (eid.isNotEmpty) {
        fetchDistrictName();
        fetchOrderData();
      }
      setState(() {});
    });
  }

  void fetchDistrictName() {
    http.get(Uri.parse('http://127.0.0.1:8000/district?eid=$eid')).then((response) {
      final result = json.decode(utf8.decode(response.bodyBytes));
      dadminname = result['ename'] ?? '';
      setState(() {});
    });
  }

void fetchOrderData() {
  http.get(Uri.parse('http://127.0.0.1:8000/list')).then((response) {
    final all = json.decode(utf8.decode(response.bodyBytes))['results'] ?? [];

    data = all.where((item) {
      return item['oeid'].toString() == eid &&
          item['oreturndate'] == null &&
          (item['odate'] ?? '').toString().startsWith(dal);
    }).toList();

    
    totalsales = 0;
    for (var item in data) {
      final price = (item['pprice'] ?? 0) as int;
      final count = (item['ocount'] ?? 0) as int;
      totalsales += price * count;
    }

    Map<String, List<Map<String, dynamic>>> tempMap = {};
    for (var item in data) {
      String date = (item['odate'] ?? '').toString().substring(0, 10);
      String name = item['pname'] ?? '';
      int count = item['ocount'] ?? 0;
      int price = item['pprice'] ?? 0;
      int total = price * count;

      tempMap.putIfAbsent(date, () => []);
      tempMap[date]!.add({
        'name': name,
        'count': count,
        'total': total,
      });
    }

    groupedData = tempMap.entries.map((e) => {
      'date': e.key,
      'products': e.value,
    }).toList();

    setState(() {});
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("[$dadminname] $dal 매출 현황"),
      ),
      drawer: DealerDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              "이번 달 총 매출: ${totalsales ~/ 10000} 만원",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: groupedData.isEmpty
                ? const Center(child: Text('이번 달 매출이 없습니다.'))
                : ListView.builder(
                    itemCount: groupedData.length,
                    itemBuilder: (context, index) {
                      final day = groupedData[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 8),
                                  Text(day['date']?.toString() ?? '', style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...List<Widget>.from(day['products'].map((product) {
                                final name = product['name'] ?? '';
                                final count = product['count'] ?? 0;
                                final total = product['total'] ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("$name ($count개)"),
                                      Text("${(total / 10000).toStringAsFixed(1)} 만원"),
                                    ],
                                  ),
                                );
                              }))
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
