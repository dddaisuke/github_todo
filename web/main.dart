import 'dart:async';
import 'dart:html';

import 'package:intl/intl.dart';
import 'package:googleapis_auth/auth_browser.dart' as auth;
import 'package:googleapis/tasks/v1.dart';
import 'package:ctrl_alt_foo2/keys.dart';
import 'todo.dart';
import 'todo_model.dart';

// localhost:8080
// final identifier = new auth.ClientId("1046747984594-4dhl3udd450bdvtmtfsgcep0eqv7se2s.apps.googleusercontent.com", null);
//production
final identifier = new auth.ClientId("1046747984594-99j6vctr6dh1afg9ae111s8iabgn2l1d.apps.googleusercontent.com", null);

final scopes = [TasksApi.TasksScope];

TasksApi api = null;
TaskList selectedTaskList = null;

/**
 * A `hello world` application for Chrome Apps written in Dart.
 *
 * For more information, see:
 * - http://developer.chrome.com/apps/api_index.html
 * - https://github.com/dart-gde/chrome.dart
 */
void main() {
  InputElement loginButton = querySelector('#login_button');
  DivElement main = querySelector('#main');

  authorizedClient(loginButton, identifier, scopes).then((client) {
    main.remove();

    api = new TasksApi(client);
    TasklistsResourceApi resources = api.tasklists;
    resources.list().then((lists) {
      List<TaskList> items = lists.items;
      createTaskListSelector(items);
    });
  });
}

void createTaskListSelector(List<TaskList> items) {
  DivElement listTask = querySelector('#tasks_list');
  listTask.setInnerHtml('<h2>タスク一覧</h2>');

  Map<String, TaskList> list = new Map<String, TaskList>();
  SelectElement element = new SelectElement();
  window.console.info(element);
  element.children.add(createOptionElement(null, 'Please select', true));

  String name = window.localStorage['selectedListName'];

  for (TaskList item in items) {
    list[item.id] = item;

    OptionElement elem = createOptionElement(item.id, item.title, (item.title == name));
    element.children.add(elem);
  }
  element.onChange.listen((e) {
    listSelectorOnChange(list, element);
  });
  listTask.children.add(element);

  listSelectorOnChange(list, element);
}

void listSelectorOnChange(Map<String, TaskList> list, SelectElement element) {
  TaskList taskList = list[element.value];
  if (taskList == null) {
    return;
  }
  window.console.log(taskList.title);
  window.localStorage['selectedListName'] = taskList.title;
  selectedTaskList = taskList;
  Keys.shortcuts({
    'Ctrl+Z, ⌘+Z': ()=> _undoTask()
  });
  displayTasks();
}

OptionElement createOptionElement(String value, String title, bool selected) {
  OptionElement option = new OptionElement(value: value, selected: selected);
  option.setInnerHtml(title);
  return option;
}

void displayTasks() {
  DivElement divTasks = querySelector('#task_list');
  addRefreshButton(divTasks);
  loadTodo();
}

void startLoader(DivElement target) {
  DivElement divElement = new DivElement();
  divElement.setAttribute('id', 'ajax_loader');
  divElement.setInnerHtml("<img src='images/ajax-loader.gif'>");
  target.append(divElement);
}

void endLoader() {
  DivElement divElement = querySelector('#ajax_loader');
  divElement.remove();
}

void loadTodo() {
  DivElement divElement = querySelector('#todo_box');
  startLoader(divElement);

  TasksResourceApi resource = api.tasks;
  resource.list(selectedTaskList.id, maxResults: "100", showCompleted: false, showDeleted: false, showHidden: false).then((Tasks tasks) {
    endLoader();

    DivElement element = new DivElement();
    element.setAttribute('id', 'todo_list');
    divElement.append(element);

    List<Task> listTask = tasks.items;
    TodoModel model = new TodoModel(listTask);

    for (List<Todo> list in model.toArray()) {
      if (list.length == 1) {
        createTodo(element, list.first);
      } else {
        createGroupTodo(element, list);
      }
    }
  });
}

void addRefreshButton(DivElement divTasks) {
  divTasks.setInnerHtml("<img id='refresh_button' src='images/arrow72.png'>");
  divTasks.onClick.listen((_) {
    DivElement divElement = querySelector('#todo_list');
    divElement.remove();

    loadTodo();
  });
}

void createGroupTodo(DivElement parent, List<Todo> list) {
  DivElement div = new DivElement();
  div.setAttribute('class', 'items');
  CheckboxInputElement elementCheck = new CheckboxInputElement();
  elementCheck.onChange.listen((Event event) {
    if (elementCheck.checked) {
      for(Todo todo in list) {
        todo.task.status = 'completed';
        api.tasks.update(todo.task, selectedTaskList.id, todo.task.id);
      }
      div.remove();
    }
  });
  div.append(elementCheck);

  for(Todo todo in list) {
    createTodo(div, todo);
  }

  parent.append(div);
}

void createTodo(DivElement parent, Todo todo) {
  if (todo.status == 'completed') {
    return;
  }
  if (todo.description == null) {
    return;
  }

  DivElement div = new DivElement();
  div.setAttribute('class', 'item');

  CheckboxInputElement elementCheck = new CheckboxInputElement();
  elementCheck.onChange.listen((Event event) {
    if (elementCheck.checked) {
      todo.task.status = 'completed';
      api.tasks.update(todo.task, selectedTaskList.id, todo.task.id);
      div.remove();
    }
  });
  div.append(elementCheck);

  if (todo.due != null) {
    DateFormat formatter = new DateFormat('yyyy-MM-dd');
    String formatted = formatter.format(todo.due.toLocal());
    div.appendHtml('<div class="due">${formatted}</div>');
  }
  div.appendHtml('<div class="title">${todo.title}</div>');
  div.appendHtml('<div class="clearfix"></div>');

  DivElement divNotes = new DivElement();
  AnchorElement aLink = new AnchorElement(href: todo.url);
  aLink.target = "_blank";
  aLink.text = todo.description;
  divNotes.append(aLink);
  div.append(divNotes);

  parent.append(div);
}

void _undoTask() {
  window.console.log("undo task!!!");

  TasksResourceApi resource = api.tasks;
  resource.list(selectedTaskList.id, showCompleted: true, showDeleted: false, showHidden: false).then((Tasks tasks) {
    List<Task> listTask = tasks.items;
    List<Task> listCompletedTask = new List<Task>();
    for(Task task in listTask) {
      if(task.status == 'completed') {
        listCompletedTask.add(task);
      }
    }

    listCompletedTask.sort((a, b) => b.completed.compareTo(a.completed));

    for(Task task in listCompletedTask) {
      window.console.log("undo!!! " + task.title + task.completed.toString());
      DivElement parent = querySelector('#todo_list');
      task.status = "needsAction";
      task.completed = null;
      resource.update(task, selectedTaskList.id, task.id);
      createTodo(parent, new Todo(task));
      break;
    }
  });
}

// Obtain an authenticated HTTP client which can be used for accessing Google
// APIs.
Future authorizedClient(InputElement loginButton, auth.ClientId id, scopes) {
  return auth.createImplicitBrowserFlow(id, scopes)
      .then((auth.BrowserOAuth2Flow flow) {
        return flow.clientViaUserConsent(immediate: false).catchError((_) {
          return loginButton.onClick.first.then((_) {
            return flow.clientViaUserConsent(immediate: true);
          });
        }, test: (error) => error is auth.UserConsentException);
  });
}
