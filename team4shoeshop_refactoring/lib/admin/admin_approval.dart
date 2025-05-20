import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:team4shoeshop_refactoring/admin/admin_add_approval.dart';
import 'package:team4shoeshop_refactoring/admin/widget/admin_drawer.dart';

class AdminApproval extends StatefulWidget {
  const AdminApproval({super.key});

  @override
  State<AdminApproval> createState() => _AdminApprovalState();
}

class _AdminApprovalState extends State<AdminApproval> {
  // late DatabaseHandler handler;
  final box = GetStorage();
  List aData = [];
  
  @override
  void initState() {
    super.initState();
    // handler = DatabaseHandler();
    getJSONData();
  }

    getJSONData()async{
    var response = await http.get(Uri.parse("http://127.0.0.1:8000/a_select"));
    aData.clear();
    aData.addAll(json.decode(utf8.decode(response.bodyBytes))['approvals']);
    setState(() {});
    // print(aData); // 데이터 잘 들어오는지 확인용
  }

  // ----------------------

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: Text(
          '품의 및 결재',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async{
              final adminPermission = box.read('adminPermission');
              if(adminPermission == 1){
                await Get.to(AdminAddApproval());
                await getJSONData();
                setState(() {});
              }else{
                Get.snackbar(
                  '권한 불일치', '권한이 없습니다.',
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.redAccent
                );
              }
            }, 
            icon: Icon(Icons.add),
          ),
        ],
    ),
    drawer: AdminDrawer(),
    body: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.blue[50],
            ),
            child: Center(
              child: Text("""문서 번호 | 문서 상태 | 브랜드
상품명 | 색상 | 사이즈 | 발주 수량
작성일 | 작성자 | 현재 재고""",
              textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
                    itemCount: aData.length,
                    itemBuilder: (context, index) {
                      final approval = aData[index];
                      // print(approval[0]);
                      // print(approval[1]);
                      final aid = approval['aid'];
                      // print(aid);
                      final status = approval['astatus'];
                      return Slidable(
                        endActionPane: ActionPane(
                          motion: BehindMotion(), 
                          children: [
                            SlidableAction(
                              backgroundColor: Colors.redAccent,
                              icon: Icons.block,
                              label: '반려',
                              onPressed: (context) {
                                final adminPermission = box.read('adminPermission');
                                if(adminPermission==1){
                                  Get.snackbar(
                                    '권한 불일치', '권한이 없습니다.',
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Colors.redAccent
                                  );
                                }else{
                                  selectDelete(aid);
                                }
                              }, 
                            ),
                          ],
                        ),
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          color: status=='임원승인'?Colors.grey:Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    """${approval['aid']} | ${approval['astatus']} | ${approval['pbrand']}
${approval['pname']} | ${approval['pcolor']} | ${approval['psize']} | ${approval['abaljoo']}
${approval['adate']} | ${approval['aeid']} | ${approval['pstock']}""",
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final adminPermission = box.read('adminPermission');
                                    if(status=='대기'){
                                      if(adminPermission==2){
                                        Get.defaultDialog(
                                          backgroundColor: Colors.purple[100],
                                          title: '해당 건을 결재하시겠습니까?',
                                          titleStyle: TextStyle(
                                            fontSize: 18
                                          ),
                                          content: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                                child: ElevatedButton(
                                                  onPressed: () => Get.back(), 
                                                  child: Text('취소'),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                                child: ElevatedButton(
                                                  onPressed: () async{
                                                    await update2Approval(approval);
                                                    setState(() {});
                                                    Get.back();
                                                    Get.snackbar(
                                                      '결재 완료', '문서를 결재했습니다.',
                                                      backgroundColor: Colors.purple[100]
                                                    );
                                                  }, 
                                                  child: Text('결재'),
                                                ),
                                              ),
                                            ],
                                          )
                                        );
                                      }else{
                                        Get.snackbar(
                                          '권한 불일치', '권한이 없습니다.',
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Colors.redAccent
                                        );
                                      }
                                    }
                                    if(status=='팀장승인'){
                                      if(adminPermission==3){
                                        Get.defaultDialog(
                                          backgroundColor: Colors.purple[100],
                                          title: '해당 건을 결재하시겠습니까?',
                                          titleStyle: TextStyle(
                                            fontSize: 18
                                          ),
                                          content: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                                child: ElevatedButton(
                                                  onPressed: () => Get.back(), 
                                                  child: Text('취소'),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                                child: ElevatedButton(
                                                  onPressed: () async{
                                                    await update3Approval(approval);
                                                    setState(() {});
                                                    Get.back();
                                                    Get.snackbar(
                                                      '결재 완료', '문서를 결재했습니다.',
                                                      backgroundColor: Colors.purple[100]
                                                    );
                                                  }, 
                                                  child: Text('결재'),
                                                ),
                                              ),
                                            ],
                                          )
                                        );
                                      }else{
                                        Get.snackbar(
                                          '권한 불일치', '권한이 없습니다.',
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Colors.redAccent
                                        );
                                      }
                                    }
                                  }, 
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: status=='임원승인'?Colors.grey:Colors.white
                                  ),
                                  child: Text('결재'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
} // build

  selectDelete(aid){
    showCupertinoModalPopup(
      context: context, 
      barrierDismissible: false,
      builder: (context) => CupertinoActionSheet(
        title: Text('경고',
        style: TextStyle(
          color: Colors.red
        ),),
        message: Text('선택한 항목을 삭제하시겠습니까?',
        style: TextStyle(
          color: Colors.red
        ),),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              deleteApproval(aid); // 리스트에서 삭제
              setState(() {}); // 삭제된 거 화면에 반영
              Get.back(); // 액션시트 치우기
            }, 
            child: Text('삭제',
            style: TextStyle(
              color: Colors.red
            ),),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back(), 
          child: Text('취소'),
        ),
      ),
    );
  }

// Future<List<String>> getApproval() async {
//   final Database db = await handler.initializeDB();
//   final result = await db.rawQuery('select a.aid, a.astatus, p.pbrand, p.pname, p.pcolor, p.psize, a.abaljoo, a.adate, p.pstock from product p, approval a where a.apid=p.pid order by aid');
//   return result.map((e) => "문서 번호 : ${e['aid']} | ${e['astatus']} | ${e['pbrand']}\n${e['pname']} | ${e['pcolor']} | ${e['psize']} | ${e['abaljoo']}\n${e['adate']} | 현재 재고 : ${e['pstock']}").toList();
// }

  //   Future<int> update2Approval(int aid) async{
  //   int result = 0;
  //   final Database db = await handler.initializeDB();
  //   result = await db.rawUpdate(
  //     'update approval set astatus = ?, ateamappdate = ? where aid = ?',
  //     ['팀장승인', "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",aid]
  //   );
  //   return result;
  // }
  
  update2Approval(approval)async{
    var request = http.MultipartRequest("POST", Uri.parse('http://127.0.0.1:8000/a_update_2'));

    request.fields['astatus'] = "팀장승인";
    request.fields['ateamappdate'] = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    request.fields['aid'] = approval['aid'].toString();
    await request.send();
    getJSONData();
  }

  update3Approval(approval)async{
    var request = http.MultipartRequest("POST", Uri.parse('http://127.0.0.1:8000/a_update_3'));

    request.fields['astatus'] = '임원승인';
    request.fields['achiefappdate'] = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    request.fields['abaljoo'] = approval['abaljoo'].toString();
    request.fields['aid'] = approval['aid'].toString();
    // request.fields['pid'] = approval['pid'].toString();
    await request.send();
    getJSONData();
  }
//       Future<int> update3Approval(int aid) async{
//     int result = 0;
//     final Database db = await handler.initializeDB();
//     result = await db.rawUpdate(
//       'update approval set astatus = ?, achiefappdate = ? where aid = ?',
//       ['임원승인', "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",aid]
//     );
//     return result;
//   }

  // Future<int> updateStock(int aid) async{
  //   int result = 0;
  //   final Database db = await handler.initializeDB();
  //   result = await db.rawUpdate(
  //     'update approval set astatus = ?, achiefappdate = ? where aid = ?',
  //     ['임원승인', "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",aid]
  //   );
  //   return result;
  // }

  // Future<void> updateApprovalAndStockWithErrorHandling(int aid) async {
  // final db = await handler.initializeDB();

  //   // 1. approval 테이블에서 apid, abaljoo 가져오기
  //   final approval = await db.query(
  //     'approval',
  //     columns: ['apid', 'abaljoo'],
  //     where: 'aid = ?',
  //     whereArgs: [aid],
  //   );

  //   if (approval.isEmpty) {
  //     throw Exception('해당 approval(aid: $aid)을 찾을 수 없습니다.');
  //   }

  //   final pid = approval.first['apid'] as String;
  //   final abaljoo = approval.first['abaljoo'] as int;

  //   // 2. approval 상태 및 achiefappdate 업데이트
  //   final approvalUpdate = await db.rawUpdate(
  //     'UPDATE approval SET astatus = ?, achiefappdate = ? WHERE aid = ?',
  //     [
  //       '임원승인',
  //       "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
  //       aid
  //     ],
  //   );

  //   if (approvalUpdate == 0) {
  //     throw Exception('Approval 테이블 업데이트 실패');
  //   }

  //   // 3. product 테이블의 pstock 증가
  //   final stockUpdate = await db.rawUpdate(
  //     'UPDATE product SET pstock = pstock + ? WHERE pid = ?',
  //     [abaljoo, pid],
  //   );

  //   if (stockUpdate == 0) {
  //     throw Exception('Product 테이블 업데이트 실패');
  //   }
  // }

  //   Future<void> deleteApproval(aid) async{
  //   final Database db = await handler.initializeDB();
  //   await db.rawDelete('delete from approval where aid = ?', [aid]);
  // }

    deleteApproval(int aid){
    getJSONDataDelete(aid);
    getJSONData();
  }

    getJSONDataDelete(int aid)async{
    var response = await http.delete(Uri.parse("http://127.0.0.1:8000/a_delete/$aid"));
    json.decode(utf8.decode(response.bodyBytes))['result'];
    // if(result != "OK"){
    //   errorSnackBar();
    // }
    // print(data); // 데이터 잘 들어오는지 확인용
  }

    errorSnackBar(){
    Get.snackbar(
      "경고", 
      "입력 중 문제가 발생했습니다",
      colorText: Theme.of(context).colorScheme.onError,
      backgroundColor: Theme.of(context).colorScheme.error,
      );
  }

  showDialog(){
    Get.defaultDialog(
      title: '입력 결과',
      middleText: '입력이 완료되었습니다.',
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      barrierDismissible: false,
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
            Get.back();
          }, 
          child: Text('나가기'),
        ),
      ]
    );
  }
  
} // class