import 'package:flutter/material.dart';
import '../data/models/task_model.dart';
import '../data/models/offer_model.dart';
import '../data/services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';
  final Set<String> _appliedTaskIds = {};
  final Set<String> _myOngoingTaskIds = {};
  final Map<String, OfferModel> _myOffers = {};

  // Task Post Wizard State
  String wizardCategory = 'delivery';
  String wizardTitle = '';
  String wizardDescription = '';
  int wizardQuantity = 1;
  String wizardSpecialInstructions = '';
  List<String> wizardPhotos = [];
  String wizardPickupAddress = 'Office, Bole, Addis Ababa';
  String wizardDropoffAddress = 'Kazanchis, Addis Ababa';
  String wizardScheduleType = 'today';
  String wizardScheduleText = 'Today · 4:00 PM - 6:00 PM';
  int wizardBudget = 450;
  String wizardPricingType = 'fixed';

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  List<TaskModel> get filteredTasks {
    if (_selectedCategory == 'all') return _tasks;
    return _tasks.where((t) => t.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
  }

  List<TaskModel> get activeTasks {
    return _tasks.where((t) => t.status != 'PAID' && t.status != 'COMPLETED' && t.status != 'CANCELLED').toList();
  }

  String? _currentUserId;
  String? _currentUserName;

  void setCurrentUser(String? userId, String? userName) {
    _currentUserId = userId;
    _currentUserName = userName;
    notifyListeners();
  }

  bool _isTaskAssignedToMe(TaskModel t) {
    final uid = _currentUserId;
    final uname = (_currentUserName ?? '').trim().toLowerCase();

    final assignedId = t.assignedTaskerId?.trim();
    final assignedName = (t.assignedTaskerName ?? '').trim().toLowerCase();

    // 1. If assignedId matches current user ID
    if (uid != null && uid.isNotEmpty) {
      if (assignedId != null && (assignedId == uid || 'tasker_$uid' == assignedId || uid == 'tasker_$assignedId')) {
        return true;
      }
    }
    // 2. If assignedName matches current user Name
    if (uname.isNotEmpty && assignedName.isNotEmpty) {
      if (assignedName == uname || assignedName.contains(uname) || uname.contains(assignedName)) {
        return true;
      }
    }
    // 3. If assigned locally or in this session
    if (_myOngoingTaskIds.contains(t.id) || _myOngoingTaskIds.contains('task_${t.id}')) {
      return true;
    }
    // 4. Default fallback when no user is logged in yet
    if ((uid == null || uid.isEmpty || uid == 'tasker_daniel') &&
        (assignedId == 'tasker_daniel' || assignedName.contains('daniel'))) {
      return true;
    }
    return false;
  }

  List<TaskModel> get ongoingTasks {
    return _tasks.where((t) {
      final st = t.status.toUpperCase();
      final isOngoing = st == 'ACCEPTED' || st == 'ASSIGNED' || st == 'IN_PROGRESS' || st == 'SUBMITTED' || st == 'PAYMENT_PENDING';
      return isOngoing && _isTaskAssignedToMe(t);
    }).toList();
  }

  int get ongoingTasksCount => ongoingTasks.length;

  List<TaskModel> get inProgressTasks {
    return _tasks.where((t) => t.status.toUpperCase() == 'IN_PROGRESS' && _isTaskAssignedToMe(t)).toList();
  }

  List<TaskModel> get assignedTasks {
    return _tasks.where((t) => (t.status.toUpperCase() == 'ACCEPTED' || t.status.toUpperCase() == 'ASSIGNED') && _isTaskAssignedToMe(t)).toList();
  }

  List<TaskModel> get submittedTasks {
    return _tasks.where((t) => (t.status.toUpperCase() == 'SUBMITTED' || t.status.toUpperCase() == 'PAYMENT_PENDING') && _isTaskAssignedToMe(t)).toList();
  }

  List<TaskModel> get completedTasks {
    return _tasks.where((t) => (t.status.toUpperCase() == 'PAID' || t.status.toUpperCase() == 'COMPLETED') && _isTaskAssignedToMe(t)).toList();
  }

  List<TaskModel> get openTasks {
    return _tasks.where((t) {
      final st = t.status.toUpperCase();
      return st == 'OPEN' || st == 'OFFERING';
    }).toList();
  }

  final Map<String, DateTime> _taskStartTimes = {};
  final Map<String, DateTime> _taskCompletedTimes = {};

  DateTime? getTaskStartTime(String taskId) {
    final cleanId = taskId.startsWith('task_') ? taskId.replaceFirst('task_', '') : taskId;
    return _taskStartTimes[taskId] ?? _taskStartTimes['task_$cleanId'] ?? _taskStartTimes[cleanId];
  }

  void setTaskStartTime(String taskId, DateTime time) {
    final cleanId = taskId.startsWith('task_') ? taskId.replaceFirst('task_', '') : taskId;
    _taskStartTimes[taskId] = time;
    _taskStartTimes['task_$cleanId'] = time;
    _taskStartTimes[cleanId] = time;
  }

  DateTime? getTaskCompletedTime(String taskId) {
    final cleanId = taskId.startsWith('task_') ? taskId.replaceFirst('task_', '') : taskId;
    return _taskCompletedTimes[taskId] ?? _taskCompletedTimes['task_$cleanId'] ?? _taskCompletedTimes[cleanId];
  }

  void setTaskCompletedTime(String taskId, DateTime time) {
    final cleanId = taskId.startsWith('task_') ? taskId.replaceFirst('task_', '') : taskId;
    _taskCompletedTimes[taskId] = time;
    _taskCompletedTimes['task_$cleanId'] = time;
    _taskCompletedTimes[cleanId] = time;
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> fetchTasks({String? roleMode}) async {
    _isLoading = true;
    notifyListeners();

    final fetched = await _api.getTasksFeed(roleMode: roleMode);
    _tasks = fetched.map((t) {
      if (t.startedAt != null) {
        setTaskStartTime(t.id, t.startedAt!);
      }
      if (t.completedAt != null) {
        setTaskCompletedTime(t.id, t.completedAt!);
      }
      final savedStart = getTaskStartTime(t.id);
      final savedCompleted = getTaskCompletedTime(t.id);

      final isMyOngoing = _myOngoingTaskIds.contains(t.id) || _myOngoingTaskIds.contains('task_${t.id}');
      final effectiveStatus = (isMyOngoing && t.status == 'OPEN') ? 'ACCEPTED' : t.status;
      final effectiveTaskerId = (isMyOngoing && (t.assignedTaskerId == null || t.assignedTaskerId!.isEmpty)) 
          ? _currentUserId 
          : t.assignedTaskerId;
      final effectiveTaskerName = (isMyOngoing && (t.assignedTaskerName == null || t.assignedTaskerName!.isEmpty)) 
          ? _currentUserName 
          : t.assignedTaskerName;

      return t.copyWith(
        status: effectiveStatus,
        assignedTaskerId: effectiveTaskerId,
        assignedTaskerName: effectiveTaskerName,
        startedAt: t.startedAt ?? savedStart,
        completedAt: t.completedAt ?? savedCompleted,
      );
    }).toList();

    _isLoading = false;
    notifyListeners();
  }

  void resetWizard() {
    wizardCategory = 'delivery';
    wizardTitle = '';
    wizardDescription = '';
    wizardQuantity = 1;
    wizardSpecialInstructions = '';
    wizardPhotos = [];
    wizardPickupAddress = 'Office, Bole, Addis Ababa';
    wizardDropoffAddress = 'Kazanchis, Addis Ababa';
    wizardScheduleType = 'today';
    wizardScheduleText = 'Today · 4:00 PM - 6:00 PM';
    wizardBudget = 450;
    wizardPricingType = 'fixed';
    notifyListeners();
  }

  Future<TaskModel?> submitWizardTask() async {
    _isLoading = true;
    notifyListeners();

    final taskData = {
      'title': wizardTitle.isNotEmpty ? wizardTitle : 'Pick up documents',
      'category': wizardCategory,
      'description': wizardDescription.isNotEmpty
          ? wizardDescription
          : 'Pick up the documents from the office and deliver to the address. Please handle with care.',
      'quantity': wizardQuantity,
      'specialInstructions': wizardSpecialInstructions,
      'pickupLocation': {'address': wizardPickupAddress, 'coordinates': [38.7865, 8.9982]},
      'dropoffLocation': {'address': wizardDropoffAddress, 'coordinates': [38.7636, 9.0125]},
      'schedule': {
        'type': wizardScheduleType,
        'windowText': wizardScheduleText,
      },
      'budget': wizardBudget,
      'pricingType': wizardPricingType,
    };

    final newTask = await _api.createTask(taskData);
    _isLoading = false;

    if (newTask != null) {
      _tasks.insert(0, newTask);
      notifyListeners();
    }
    return newTask;
  }

  Future<bool> acceptTask(String taskId) async {
    _myOngoingTaskIds.add(taskId);
    final cleanId = taskId.startsWith('task_') ? taskId.replaceFirst('task_', '') : taskId;
    _myOngoingTaskIds.add('task_$cleanId');
    _myOngoingTaskIds.add(cleanId);

    final index = _tasks.indexWhere((t) => t.id == taskId || t.id == 'task_$cleanId' || t.id == cleanId);
    if (index != -1) {
      final t = _tasks[index];
      _tasks[index] = t.copyWith(
        status: 'ACCEPTED',
        assignedTaskerId: _currentUserId ?? 'tasker_current',
        assignedTaskerName: _currentUserName ?? 'Assigned Tasker',
      );
      notifyListeners();
    }
    final success = await _api.acceptTask(taskId, taskerId: _currentUserId, taskerName: _currentUserName);
    return success;
  }

  bool hasApplied(String taskId) {
    return _appliedTaskIds.contains(taskId) ||
        _appliedTaskIds.contains('task_$taskId') ||
        _myOffers.containsKey(taskId) ||
        _myOffers.containsKey('task_$taskId');
  }

  OfferModel? getMyOffer(String taskId) {
    return _myOffers[taskId] ?? _myOffers['task_$taskId'];
  }

  void recordOffer(String taskId, OfferModel offer) {
    _appliedTaskIds.add(taskId);
    _myOffers[taskId] = offer;
    notifyListeners();
  }

  Future<OfferModel?> submitOffer(String taskId, int amount, String note, {String? taskerId, String? taskerName}) async {
    final offer = await _api.createOffer(taskId, amount, note, taskerId: taskerId, taskerName: taskerName);
    if (offer != null) {
      _appliedTaskIds.add(taskId);
      _myOffers[taskId] = offer;
    }
    notifyListeners();
    return offer;
  }

  Future<bool> acceptOffer(String taskId, String offerId, String taskerName, {String? taskerId, int? budget}) async {
    final cleanId = taskId.startsWith('task_') ? taskId.replaceFirst('task_', '') : taskId;
    final index = _tasks.indexWhere((t) => t.id == taskId || t.id == 'task_$cleanId' || t.id == cleanId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: 'ACCEPTED',
        assignedTaskerId: taskerId ?? _tasks[index].assignedTaskerId,
        assignedTaskerName: taskerName,
        pricing: budget != null ? TaskPricing(budget: budget, suggestedPrice: budget) : _tasks[index].pricing,
      );
      notifyListeners();
    }
    final success = await _api.acceptOffer(taskId, offerId, taskerId: taskerId, taskerName: taskerName, budget: budget);
    return success;
  }

  Future<bool> startTask(String taskId) async {
    _myOngoingTaskIds.add(taskId);
    final cleanId = taskId.startsWith('task_') ? taskId.replaceFirst('task_', '') : taskId;
    _myOngoingTaskIds.add('task_$cleanId');
    _myOngoingTaskIds.add(cleanId);

    final now = DateTime.now();
    setTaskStartTime(taskId, now);

    final index = _tasks.indexWhere((t) => t.id == taskId || t.id == 'task_$cleanId' || t.id == cleanId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: 'IN_PROGRESS',
        startedAt: now,
        assignedTaskerId: _currentUserId ?? _tasks[index].assignedTaskerId,
        assignedTaskerName: _currentUserName ?? _tasks[index].assignedTaskerName,
      );
      notifyListeners();
    }

    final success = await _api.startTask(taskId);
    return success;
  }

  Future<bool> submitProof(String taskId, List<String> photos, String notes) async {
    _myOngoingTaskIds.add(taskId);
    final cleanId = taskId.startsWith('task_') ? taskId.replaceFirst('task_', '') : taskId;
    _myOngoingTaskIds.add('task_$cleanId');
    _myOngoingTaskIds.add(cleanId);

    final now = DateTime.now();
    setTaskCompletedTime(taskId, now);

    final index = _tasks.indexWhere((t) => t.id == taskId || t.id == 'task_$cleanId' || t.id == cleanId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: 'SUBMITTED',
        completedAt: now,
        proofPhotos: photos,
        proofNotes: notes,
        assignedTaskerId: _currentUserId ?? _tasks[index].assignedTaskerId,
        assignedTaskerName: _currentUserName ?? _tasks[index].assignedTaskerName,
      );
      notifyListeners();
    }
    final success = await _api.submitProof(taskId, photos, notes);
    return success;
  }

  Future<bool> approveTask(String taskId) async {
    final cleanId = taskId.startsWith('task_') ? taskId.replaceFirst('task_', '') : taskId;
    final index = _tasks.indexWhere((t) => t.id == taskId || t.id == 'task_$cleanId' || t.id == cleanId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: 'PAID',
        completedAt: DateTime.now(),
      );
      notifyListeners();
    }
    final success = await _api.approveTask(taskId);
    return success;
  }
}
