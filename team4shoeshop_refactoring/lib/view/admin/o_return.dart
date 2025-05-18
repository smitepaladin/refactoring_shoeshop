import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OReturn extends StatefulWidget {
  const OReturn({super.key});

  @override
  State<OReturn> createState() => _OReturnState();
}

class _OReturnState extends State<OReturn> {
 List data = [];

  @override
  void initState() {
    super.initState();
    getReturnData();
  }

getReturnData() async {
  var response = await http.get(Uri.parse('http://127.0.0.1:8001/dreturns'));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  setState(() {});
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("반품 내역"),
      ),
      body: data.isEmpty
          ? const Center(child: Text("반품 내역이 없습니다."))
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("상품명: ${item['pname']}"),
                        Text("주문일: ${item['odate']}"),
                        Text("반품일: ${item['oreturndate']}"),
                        Text("반품 수량: ${item['oreturncount']}"),
                        Text("반품 상태: ${item['oreturnstatus']}"),
                        Text("사유: ${item['oreason']}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}