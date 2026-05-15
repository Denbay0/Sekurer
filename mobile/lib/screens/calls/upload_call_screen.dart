import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../main.dart';
import '../../services/calls_api.dart';
import 'call_detail_screen.dart';

class UploadCallScreen extends StatefulWidget { const UploadCallScreen({super.key}); @override State<UploadCallScreen> createState()=>_UploadCallScreenState(); }
class _UploadCallScreenState extends State<UploadCallScreen>{final t=TextEditingController(),cn=TextEditingController(),pn=TextEditingController(); File? f; String? err; bool loading=false; @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Добавить запись')),body:Padding(padding:const EdgeInsets.all(16),child:ListView(children:[TextField(controller:t,decoration:const InputDecoration(labelText:'Название')),TextField(controller:cn,decoration:const InputDecoration(labelText:'Контакт')),TextField(controller:pn,decoration:const InputDecoration(labelText:'Телефон')),const SizedBox(height:8),OutlinedButton(onPressed:() async {final r=await FilePicker.platform.pickFiles(type: FileType.custom,allowedExtensions:['mp3','m4a','wav','aac','ogg','webm']); if(r!=null&&r.files.single.path!=null)setState(()=>f=File(r.files.single.path!));}, child:Text(f==null?'Выбрать аудиофайл':f!.path.split('/').last)),if(err!=null) Text(err!,style:const TextStyle(color:Colors.red)),const SizedBox(height:12),ElevatedButton(onPressed:loading?null:() async {if(f==null){setState(()=>err='Выберите файл');return;} setState((){loading=true;err=null;}); try{final id=await CallsApi(context.read<AppState>().api).uploadCall(f!,title:t.text,contactName:cn.text,phoneNumber:pn.text); if(!c.mounted)return; Navigator.pushReplacement(c,MaterialPageRoute(builder:(_)=>CallDetailScreen(callId:id)));} catch(e){setState(()=>err=getApiErrorMessage(e));} if(mounted)setState(()=>loading=false);}, child:Text(loading?'Загрузка...':'Загрузить'))])));}
