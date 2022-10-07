import 'package:flutter/material.dart';

class Subject extends StatelessWidget {
  String text;
  Subject({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
        color: Colors.black,
      ))),
      child: Row(children: <Widget>[
        Text(
          this.text,
          style: TextStyle(fontWeight: FontWeight.bold),
        )
      ]),
    );
  }
}
