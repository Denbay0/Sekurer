import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/task_models.dart';
import '../../services/tasks_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';

class PlannerScreen extends StatefulWidget { const PlannerScreen({super.key}); @override State<PlannerScreen> createState()=>_PlannerScreenState(); }
class _PlannerScreenState extends State<PlannerScreen>{List<TaskModel>? tasks; String f='all'; @override void initState(){super.initState();load();}
Future<void> load() async {tasks=await TasksApi(context.read<AppState>().api).listTasks(); if(mounted)setState((){});} 
bool isToday(DateTime d){final n=DateTime.now(); return d.year==n.year&&d.month==n.month&&d.day==n.day;}
@override Widget build(BuildContext c){if(tasks==null)return const LoadingView(); final data=tasks!.where((x){if(f=='draft')return x.status=='draft';if(f=='confirmed')return x.status=='confirmed';if(f=='done')return x.status=='done';return true;}).toList(); final done=data.where((e)=>e.status=='done').toList(); final noDue=data.where((e)=>e.status!='done'&&e.dueDate==null).toList(); final today=data.where((e)=>e.status!='done'&&e.dueDate!=null&&isToday(e.dueDate!)).toList(); final tomorrow=data.where((e)=>e.status!='done'&&e.dueDate!=null&&isToday(e.dueDate!.subtract(const Duration(days:1)))).toList(); final later=data.where((e)=>e.status!='done'&&e.dueDate!=null&&!today.contains(e)&&!tomorrow.contains(e)).toList();
Widget group(String t,List<TaskModel> items)=>items.isEmpty?const SizedBox.shrink():Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Padding(padding:const EdgeInsets.all(8),child:Text(t,style:Theme.of(c).textTheme.titleMedium)),...items.map(card)]);
return SingleChildScrollView(child:Column(children:[Wrap(spacing:6,children:[for(final e in const {'all':'Все','draft':'Черновики','confirmed':'Подтверждённые','done':'Выполненные'}.entries) ChoiceChip(label:Text(e.value),selected:f==e.key,onSelected:(_)=>setState(()=>f=e.key))]),if(data.isEmpty) const EmptyState(title:'Нет задач', subtitle:'Задачи появятся после анализа звонка'),group('Сегодня',today),group('Завтра',tomorrow),group('Позже',later),group('Без срока',noDue),group('Выполненные',done)]));}
Widget card(TaskModel x)=>Card(child:ListTile(title:Text(x.title),subtitle:Text('${x.dueDate?.toIso8601String().split('T').first ?? 'без срока'} • ${x.priority} • ${x.status}${x.sourceQuote!=null ? '\n${x.sourceQuote}' : ''}'),trailing:Wrap(children:[TextButton(onPressed:()=>upd(x.id,{'status':'confirmed','requires_confirmation':false}), child:const Text('Подтвердить')),TextButton(onPressed:()=>upd(x.id,{'status':'done'}), child:const Text('Выполнено')),TextButton(onPressed:()=>upd(x.id,{'status':'cancelled'}), child:const Text('Отменить'))])));
Future<void> upd(String id,Map<String,dynamic> p) async {await TasksApi(context.read<AppState>().api).updateTask(id,p); await load();}
}
