import 'dart:collection';
import 'package:googleapis/tasks/v1.dart';
import 'todo.dart';
import 'dart:html';

class TodoModel {
  Map<String, List<Todo>> list = new Map<String, List<Todo>>();
  List<String> keys = new List();

  TodoModel(List<Task> listTask) {
    append(listTask);
  }

  void append(List<Task> listTask) {
    for (Task task in listTask.reversed) {
      Todo todo = new Todo(task);
      var uri = Uri.parse(todo.url);
      List listTodo = fetchTodoList(uri.host + uri.path);
      listTodo.add(todo);
    }
  }

  List fetchTodoList(String key) {
    if(!list.containsKey(key)) {
      keys.add(key);
      list[key] = new List();
    }
    return list[key];
  }

  List<List<Todo>> toArray() {
    List<List<Todo>> result = new List<List<Todo>>();
    for(String key in keys) {
      result.add(list[key]);
    }
    return result;
  }
}
