import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class DealerReturnDetail extends StatefulWidget {
  final Map<String, dynamic> orderMap;
  const DealerReturnDetail({super.key, required this.orderMap});

  @override
  State<DealerReturnDetail> createState() => _DealerReturnDetailState();
}

class _DealerReturnDetailState extends State<DealerReturnDetail> {
  late TextEditingController returnCountController;
  late TextEditingController reasonController;
  late TextEditingController statusController;
  late TextEditingController defectiveReasonController;

  @override
  void initState() {
    super.initState();
    returnCountController = TextEditingController(
        text: widget.orderMap['oreturncount']?.toString() ?? '');
    reasonController =
        TextEditingController(text: widget.orderMap['oreason'] ?? '');
    statusController =
        TextEditingController(text: widget.orderMap['oreturnstatus'] ?? '');
    defectiveReasonController = TextEditingController(
        text: widget.orderMap['odefectivereason'] ?? '');
  }

  Future<void> updateReturnInfo() async {
    final now = DateTime.now();
    final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/update_return'),
      body: {
        'oid': widget.orderMap['oid'].toString(),
        'oreturncount': returnCountController.text,
        'oreason': reasonController.text,
        'oreturnstatus': statusController.text,
        'odefectivereason': defectiveReasonController.text,
        'oreturndate': formattedDate,
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반품 정보가 저장되었습니다')),
      );
      Navigator.pop(context, true);
    } else {
      Get.snackbar("오류", "서버 응답 실패: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderMap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('반품 정보 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('상품명: ${order['pname']}'),
          Text('주문일: ${order['odate']}'),
            Text('주문수량: ${order['ocount']}개'),
            Text('원인 규명: ${order['odefectivereason'] ?? ''}'),
            const SizedBox(height: 20),
            TextField(
              controller: returnCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '반품 수량'),
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: '반품 사유'),
            ),
            TextField(
              controller: statusController,
              decoration: const InputDecoration(labelText: '반품 상태'),
            ),
            TextField(
              controller: defectiveReasonController,
              decoration: const InputDecoration(labelText: '원인 규명'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (){
                Get.back();
              },

            child: Text("취소"),style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,),),
            ElevatedButton(
              onPressed: updateReturnInfo,
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
