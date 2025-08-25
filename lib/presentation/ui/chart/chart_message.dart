import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:qychatapp/presentation/utils/dio/dio_client.dart';

class ChatMessageScreen extends StatefulWidget {
  @override
  State<ChatMessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<ChatMessageScreen> {
  final _formKey = GlobalKey<FormState>();

  // 控制器
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // 验证手机号码格式
  bool _isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  // 提交表单
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      var uploadData = await DioClient().leaveMessage(
          "${_nameController.text}",
        "${_phoneController.text}",
        "${_summaryController.text}",
        "${_descriptionController.text}",
      );

      if (uploadData != {}) {
        // 表单验证通过
        showToast("留言提交成功！");
        context.pop();
      }


      // 模拟提交成功后的操作
      // Future.delayed(Duration(seconds: 1), () {
      //   // 清空表单
      //   _nameController.clear();
      //   _phoneController.clear();
      //   _summaryController.clear();
      //   _descriptionController.clear();
      //
      //   // 重置表单状态
      //   _formKey.currentState!.reset();
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('留言反馈'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  '请填写您的留言信息',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              // 姓名输入框
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '您的姓名 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入您的姓名';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // 手机号码输入框
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '手机号码 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入手机号码';
                  }
                  if (!_isValidPhone(value)) {
                    return '请输入有效的手机号码';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // 问题简述输入框
              TextFormField(
                controller: _summaryController,
                decoration: InputDecoration(
                  labelText: '问题简述 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入问题简述';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // 问题描述输入框
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: '问题描述',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
              ),
              SizedBox(height: 30),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '提交留言',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
