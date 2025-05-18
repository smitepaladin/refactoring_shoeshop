import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class DOrders extends StatefulWidget {
  const DOrders({super.key});
  

  @override
  State<DOrders> createState() => _DOrdersState();
}

class _DOrdersState extends State<DOrders> {
String dal = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    List data = [];
    int monthSales = 0;

  @override
  void initState() {
    super.initState();
    getJsonData();
  }

getJsonData()async{
  var response = await http.get(Uri.parse('http://127.0.0.1:8001/list'));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  
  setState(() {});
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("오더페이지 "),
      ),
      body: Center(
        child: data.isEmpty
        ? Center(
        child: Text('매출이 없습니다.'),
        )
        :       ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          int sales = data[index]['pprice'] * data[index]['ocount'];
          
          return Card(
            margin: EdgeInsets.all(10),
                child: Container(width: 50,
                height: 100,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Title(
                    color: Colors.black,
                    child: Text("날짜${data[index]['odate']}", 
                    style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red))),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Text("${data[index]['pbrand']} (${data[index]['ocount']})개"),
                          Text("총금액 ${sales}원,"),
                    ],)
    
                  ],),
                ),
                );
                },
                )
      ));
      
      

            
              
  }
  }
                
