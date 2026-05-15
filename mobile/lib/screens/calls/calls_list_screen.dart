import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../main.dart';
import '../../models/call_models.dart';
import '../../services/calls_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';
import 'call_detail_screen.dart';
import 'upload_call_screen.dart';

class CallsListScreen extends StatefulWidget { const CallsListScreen({super.key}); @override State<CallsListScreen> createState()=>_CallsListScreenState(); }
class _CallsListScreenState extends State<CallsListScreen>{List<CallListItem>? data; String? err;
@override void initState(){super.initState();load();}
Future<void> load() async {try{data=await CallsApi(context.read<AppState>().api).listCalls();err=null;}catch(e){err=getApiErrorMessage(e);} if(mounted)setState((){});} 
@override Widget build(BuildContext c)=>Scaffold(floatingActionButton:FloatingActionButton(onPressed:() async {await Navigator.push(c,MaterialPageRoute(builder:(_)=>const UploadCallScreen())); await load();},child:const Icon(Icons.add)),body:RefreshIndicator(onRefresh:load,child:err!=null?ListView(children:[SizedBox(height:500,child:ErrorView(message:err!,onRetry:load))]):(data==null?const LoadingView():data!.isEmpty?const EmptyState(title:'Записей пока нет', subtitle:'Добавьте запись звонка'):ListView.builder(itemCount:data!.length,itemBuilder:(_,i){final it=data![i]; return Card(child:ListTile(title:Text(it.title??'Без названия'),subtitle:Text('${it.contactName??'—'} • ${DateFormat('dd.MM.yyyy HH:mm').format(it.createdAt.toLocal())}'),trailing:StatusBadge(status:it.status),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CallDetailScreen(callId:it.id)))));})))));
}
