
import 'package:flutter/material.dart';

import '../model/channel_config_model.dart';
class EvaluationSelectorDialog extends StatefulWidget {
  final List<ImEvaluationDefine> options;
  final String title;

  const EvaluationSelectorDialog({
    super.key,
    required this.options,
    this.title = "请选择",
  });

  @override
  State<EvaluationSelectorDialog> createState() => _EvaluationSelectorDialogState();
}

class _EvaluationSelectorDialogState extends State<EvaluationSelectorDialog> {
  ImEvaluationDefine? _selectedItem;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.options.map((option) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Radio<ImEvaluationDefine>(
                    value: option,
                    groupValue: _selectedItem,
                    onChanged: (ImEvaluationDefine? value) {
                      setState(() {
                        _selectedItem = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  title: Text(
                    option.pressValue,
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedItem == option
                          ? Colors.blue
                          : Colors.black87,
                      fontWeight: _selectedItem == option
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tileColor: _selectedItem == option
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedItem = option;
                    });
                  },
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "取消",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedItem == null
                      ? null
                      : () {
                    Navigator.of(context).pop(_selectedItem);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("确定"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}