import 'package:flutter/material.dart';

class TextFieldForm extends StatelessWidget {
  final String hinttext;
  final TextEditingController mycontroller;
  final String? Function(String?)? validator;
  final bool obscureText;

  const TextFieldForm({
    super.key,
    required this.hinttext,
    required this.mycontroller,
    required this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: mycontroller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        hintText: hinttext,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      validator: validator,
    );
  }
}