import 'package:googleapis/tasks/v1.dart';

class Todo {
  String url;
  String title;
  String description;
  String status;
  DateTime due;
  Task task;

  Todo(Task _task) {
    List<String> notes = _task.notes.split('\n');
    url = notes.first;
    description = _task.notes.substring(url.length);
    title = _task.title;
    status = _task.status;
    due = _task.due;
    task = _task;
  }
}
