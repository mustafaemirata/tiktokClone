import 'package:flutter/material.dart';

class InputText extends StatelessWidget {
  final TextEditingController textEditingController;
  final IconData? icon;
  final String? assetRefrence;
  final String labelString;
  final bool isObscure;

  const InputText({
    super.key,
    required this.textEditingController,
    this.icon,
    this.assetRefrence,
    required this.labelString,
    required this.isObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingController,
      decoration: InputDecoration(
        labelText: labelString,
        prefixIcon: icon != null
            ? Icon(icon)
            : Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(assetRefrence!, width: 10),
              ),
        labelStyle: TextStyle(fontSize: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey),
        ),
         focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
      obscureText: isObscure,
    );
  }
}
