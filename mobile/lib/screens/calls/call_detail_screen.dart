import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../main.dart';
import '../../models/call_models.dart';
import '../../services/calendar_items_api.dart';
import '../../services/calls_api.dart';
import '../../services/tasks_api.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';

class CallDetailScreen extends StatefulWidget { final String callId; const CallDetailScreen({super.key, required this.callId}); @override State<CallDetailScreen> createState()=>_CallDetailScreenState(); }
class _CallDetailScreenState extends State<CallDetailScreen>{CallDetail? d; Timer? timer; String? err;
@override void initState(){super.initState();load();}
@override void dispose(){timer?.cancel();super.dispose();}
Future<void> load() async {try{d=await CallsApi(context.read<AppState>().api).getCall(widget.callId);err=null;final s=d!.status;if(['uploaded','transcribing','analyzing'].contains(s)){timer??=Timer.periodic(const Duration(seconds: 2),(_)=>load());}else{timer?.cancel();timer=null;}}catch(e){err=getApiErrorMessage(e);} if(mounted)setState((){});} 
Future<void> updTask(String id,Map<String,dynamic> p) async {await TasksApi(context.read<AppState>().api).updateTask(id,p); await load();}
Future<void> updEvent(String id,Map<String,dynamic> p) async {await CalendarItemsApi(context.read<AppState>().api).updateCalendarItem(id,p); await load();}
@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Детали звонка')),body:err!=null?ErrorView(message:err!,onRetry:load):d==null?const LoadingView():ListView(padding:const EdgeInsets.all(12),children:[Text(d!.title??'Без названия',style:Theme.of(c).textTheme.titleLarge),Text(d!.contactName??'—'),Text(d!.phoneNumber??'—'),StatusBadge(status:d!.status),Text('Создан: ${DateFormat('dd.MM.yyyy HH:mm').format(d!.createdAt.toLocal())}'),if(d!.processedAt!=null) Text('Обработан: ${DateFormat('dd.MM.yyyy HH:mm').format(d!.processedAt!.toLocal())}'),if(d!.status=='uploaded') const Text('Файл загружен'),if(d!.status=='transcribing') const Text('Идёт расшифровка'),if(d!.status=='analyzing') const Text('Идёт анализ договорённостей'),if(d!.status=='failed') ...[Text(d!.errorMessage??'Ошибка обработки'),ElevatedButton(onPressed:() async {await CallsApi(context.read<AppState>().api).retry(widget.callId);await load();}, child:const Text('Повторить обработку'))],Card(child:ListTile(title:const Text('Кратко'),subtitle:Text(d!.summary??'Нет краткого описания'))),...d!.agreements.map((a)=>Card(child:ListTile(title:Text(a.text),subtitle:Text('Ответственный: ${a.owner}\nСрок: ${a.deadline?.toIso8601String()??'—'}\nУверенность: ${a.confidence?.toStringAsFixed(2)??'—'}\nЦитата: ${a.sourceQuote??'—'}')))),...d!.tasks.map((t)=>Card(child:ListTile(title:Text(t.title),subtitle:Text('${t.description??''}\n${t.status} • ${t.priority}\n${t.sourceQuote??''}'),trailing:Wrap(spacing:4,children:[TextButton(onPressed:()=>updTask(t.id,{'status':'confirmed','requires_confirmation':false}), child:const Text('Подтвердить')),TextButton(onPressed:()=>updTask(t.id,{'status':'done'}), child:const Text('Выполнено')),TextButton(onPressed:()=>updTask(t.id,{'status':'cancelled'}), child:const Text('Отменить'))])))),...d!.calendarItems.map((e)=>Card(child:ListTile(title:Text(e.title),subtitle:Text('${e.description??''}\n${e.status} ${e.requiresConfirmation ? '(требует подтверждения)' : ''}'),trailing:Wrap(children:[TextButton(onPressed:()=>updEvent(e.id,{'status':'confirmed','requires_confirmation':false}), child:const Text('Подтвердить')),TextButton(onPressed:()=>updEvent(e.id,{'status':'cancelled'}), child:const Text('Отменить'))])))),Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Неясности'),...d!.unclearPoints.map((u)=>Text('• ${u.text}'))]))),ExpansionTile(title:const Text('Транскрипт'),children:[Padding(padding:const EdgeInsets.all(12),child:Text(d!.transcript??'Транскрипт пока недоступен'))]) ]));
}
