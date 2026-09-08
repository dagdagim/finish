import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/finish_button.dart';
import '../../../core/widgets/finish_text_field.dart';
import '../../../core/widgets/simulated_map_widget.dart';
import '../../../core/widgets/animated_checkmark.dart';
import '../../../providers/task_provider.dart';
import '../../../data/services/location_service.dart';
import '../../common/location_picker_screen.dart';

class PostTaskWizardScreen extends StatefulWidget {
  const PostTaskWizardScreen({super.key});

  @override
  State<PostTaskWizardScreen> createState() => _PostTaskWizardScreenState();
}

class _PostTaskWizardScreenState extends State<PostTaskWizardScreen> {
  int _currentStep = 1;
  final int _totalSteps = 6;
  bool _isSuccess = false;

  // Step 2 Controllers & State
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _instructionsController;
  late TextEditingController _quantityController;
  late TextEditingController _recipientNameController;
  late TextEditingController _recipientPhoneController;
  late TextEditingController _estimatedGoodsCostController;

  // Delivery specific fields
  String _selectedPackageType = 'box';
  String _selectedVehicleType = 'motorcycle';
  bool _requirePhotoProof = true;
  bool _isFragile = false;

  // Cleaning specific fields
  String _selectedCleaningSpace = 'home_2bed';
  String _selectedCleaningType = 'standard';
  String _selectedSupplyOption = 'customer_supplies';
  final Set<String> _selectedCleaningAddons = {'sofa', 'carpet'};
  String _selectedSofaType = 'sofa_3seater';
  String _selectedCarpetType = 'carpet_medium';
  bool _includeMattressWash = false;
  bool _includeCurtainSteam = false;
  bool _includeWindowsGlass = false;

  // Shopping specific fields & Item List
  String _selectedShoppingType = 'groceries';
  String _selectedStorePreference = 'any_store';
  bool _requireItemizedReceipt = true;
  bool _allowSubstitutions = true;
  final List<Map<String, String>> _shoppingItems = [
    {'name': 'Fresh Milk (1L)', 'qty': '2 bottles'},
    {'name': 'Whole Wheat Bread', 'qty': '1 loaf'},
    {'name': 'Eggs', 'qty': '1 crate (30 pcs)'},
  ];
  late TextEditingController _newItemNameController;
  late TextEditingController _newItemQtyController;

  // Moving specific fields
  String _selectedMoveSize = 'studio_1bed';
  String _selectedFloorLevel = 'ground';
  bool _hasElevator = true;
  bool _needHelpers = true;
  bool _needPackingMaterials = false;

  // Assembly specific fields
  String _selectedAssemblyType = 'furniture_desk';
  bool _hasAssemblyManual = true;
  bool _taskerBringsTools = true;
  bool _needBoxDisposal = false;

  // Tech specific fields
  String _selectedTechDevice = 'pc_laptop';
  String _selectedTechService = 'hardware_repair';
  bool _isUrgentTech = false;

  // Plumbing specific fields
  String _selectedPlumbingIssue = 'leak';
  String _selectedPlumbingUrgency = 'urgent';
  bool _partsProvided = false;

  // Electrical specific fields
  String _selectedElectricalJob = 'short_circuit';
  bool _breakerAccessible = true;
  bool _needLadder = false;

  // Handyman specific fields
  String _selectedHandymanType = 'tv_mount';
  bool _hasBracketsAndScrews = true;
  bool _ladderRequired = true;

  // Step 3 Location Controllers & Dynamic Distance State
  late TextEditingController _pickupController;
  late TextEditingController _pickupUnitController;
  late TextEditingController _dropoffController;
  late TextEditingController _dropoffUnitController;
  bool _isRemoteTask = false;
  double _routeDistanceKm = 4.8;

  // Step 4 Schedule State
  String _selectedTimeOfDay = 'afternoon';
  String _selectedScheduleDatePreset = 'today';

  // Step 5 Budget & Breakdown State
  late TextEditingController _budgetController;
  bool _showFareBreakdown = true;

  final List<Map<String, dynamic>> _wizardCategories = const [
    {
      'id': 'delivery',
      'label': 'Delivery',
      'icon': Icons.local_shipping_outlined,
      'color': Color(0xFF087F5B),
      'subtitle': 'Couriers, Parcels & Food',
    },
    {
      'id': 'cleaning',
      'label': 'Cleaning',
      'icon': Icons.cleaning_services_outlined,
      'color': Color(0xFF0284C7),
      'subtitle': 'Home, Office & Deep Clean',
    },
    {
      'id': 'shopping',
      'label': 'Shopping',
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFD97706),
      'subtitle': 'Groceries, Stores & Errands',
    },
    {
      'id': 'moving',
      'label': 'Moving',
      'icon': Icons.inventory_2_outlined,
      'color': Color(0xFF7C3AED),
      'subtitle': 'Trucks, Lifting & Packing',
    },
    {
      'id': 'assembly',
      'label': 'Assembly',
      'icon': Icons.build_outlined,
      'color': Color(0xFFEA580C),
      'subtitle': 'Furniture & Equipment',
    },
    {
      'id': 'tech',
      'label': 'Technology',
      'icon': Icons.laptop_chromebook_outlined,
      'color': Color(0xFF2563EB),
      'subtitle': 'PC, Phone & Wifi Fixes',
    },
    {
      'id': 'plumbing',
      'label': 'Plumbing',
      'icon': Icons.plumbing_outlined,
      'color': Color(0xFF0D9488),
      'subtitle': 'Leaks, Pipes & Drains',
    },
    {
      'id': 'electrical',
      'label': 'Electrical',
      'icon': Icons.electrical_services_outlined,
      'color': Color(0xFFB45309),
      'subtitle': 'Wiring, Lights & Switches',
    },
    {
      'id': 'handyman',
      'label': 'Handyman',
      'icon': Icons.handyman_outlined,
      'color': Color(0xFF475569),
      'subtitle': 'Mounting & General Fixes',
    },
    {
      'id': 'other',
      'label': 'Other',
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFF6366F1),
      'subtitle': 'Custom & Specialized Tasks',
    },
  ];

  @override
  void initState() {
    super.initState();
    final taskProvider = context.read<TaskProvider>();
    _titleController = TextEditingController(
      text: taskProvider.wizardTitle.isNotEmpty ? taskProvider.wizardTitle : '',
    );
    _descController = TextEditingController(
      text: taskProvider.wizardDescription.isNotEmpty ? taskProvider.wizardDescription : '',
    );
    _instructionsController = TextEditingController(text: taskProvider.wizardSpecialInstructions);
    _quantityController = TextEditingController(text: taskProvider.wizardQuantity.toString());
    _recipientNameController = TextEditingController();
    _recipientPhoneController = TextEditingController();
    _estimatedGoodsCostController = TextEditingController(text: '800');

    _newItemNameController = TextEditingController();
    _newItemQtyController = TextEditingController(text: '1');

    _pickupController = TextEditingController(
      text: taskProvider.wizardPickupAddress.isNotEmpty
          ? taskProvider.wizardPickupAddress
          : 'Bole Medhanialem, Addis Ababa',
    );
    _pickupUnitController = TextEditingController();
    _dropoffController = TextEditingController(
      text: taskProvider.wizardDropoffAddress.isNotEmpty
          ? taskProvider.wizardDropoffAddress
          : 'Sarbet, Addis Ababa',
    );
    _dropoffUnitController = TextEditingController();

    _routeDistanceKm = _estimateDistanceBetween(_pickupController.text, _dropoffController.text);

    final initialPrice = _calculateDetailedPricing(taskProvider.wizardCategory)['total'] as int;
    _budgetController = TextEditingController(text: initialPrice.toString());
    taskProvider.wizardBudget = initialPrice;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _instructionsController.dispose();
    _quantityController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _estimatedGoodsCostController.dispose();
    _newItemNameController.dispose();
    _newItemQtyController.dispose();
    _pickupController.dispose();
    _pickupUnitController.dispose();
    _dropoffController.dispose();
    _dropoffUnitController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _pickLocationOnMap({required bool isDropoff}) async {
    final initial = isDropoff ? _dropoffController.text : _pickupController.text;
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: isDropoff ? 'Select Drop-off on Map' : 'Select Pickup Location on Map',
          initialAddress: initial,
          isDropoff: isDropoff,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isDropoff) {
          _dropoffController.text = result.address;
          if (result.unitNotes != null && result.unitNotes!.isNotEmpty) {
            _dropoffUnitController.text = result.unitNotes!;
          }
        } else {
          _pickupController.text = result.address;
          if (result.unitNotes != null && result.unitNotes!.isNotEmpty) {
            _pickupUnitController.text = result.unitNotes!;
          }
        }
        _routeDistanceKm = _estimateDistanceBetween(_pickupController.text, _dropoffController.text);
        final cat = context.read<TaskProvider>().wizardCategory;
        _syncBudgetWithCalculation(cat);
      });
    }
  }

  // Expanded Realistic Addis Ababa Distance Calculation Engine
  double _estimateDistanceBetween(String pickup, String dropoff) {
    final p = pickup.toLowerCase();
    final d = dropoff.toLowerCase();

    final Map<String, List<double>> zones = {
      'bole': [38.7891, 8.9953],
      'medhanialem': [38.7891, 8.9953],
      'kazanchis': [38.7636, 9.0125],
      'sarbet': [38.7369, 8.9961],
      'piassa': [38.7525, 9.0354],
      'cmc': [38.8654, 9.0152],
      'ayat': [38.8754, 9.0252],
      'meskel': [38.7618, 9.0105],
      'megenagna': [38.8021, 9.0195],
      'old airport': [38.7420, 8.9850],
      'gotera': [38.7562, 8.9868],
      'kera': [38.7562, 8.9868],
      'gerji': [38.8140, 8.9980],
      '4 kilo': [38.7605, 9.0322],
      '22': [38.7830, 9.0160],
      'tor hailoch': [38.7230, 9.0060],
      'mexico': [38.7450, 9.0110],
      'lideta': [38.7370, 9.0120],
      'summit': [38.8520, 9.0050],
      'lebu': [38.7050, 8.9550],
      'jomo': [38.7050, 8.9550],
    };

    List<double>? pCoord;
    List<double>? dCoord;

    for (final entry in zones.entries) {
      if (p.contains(entry.key)) pCoord = entry.value;
      if (d.contains(entry.key)) dCoord = entry.value;
    }

    if (pCoord != null && dCoord != null) {
      final dx = (pCoord[0] - dCoord[0]) * 110.0;
      final dy = (pCoord[1] - dCoord[1]) * 111.0;
      final straight = math.sqrt(dx * dx + dy * dy);
      final km = straight * 1.38; // Road routing factor
      return km < 1.2 ? 1.5 : double.parse(km.toStringAsFixed(1));
    }

    return 4.8;
  }

  // Dynamic Pricing Calculation Engine with Distance Increment
  Map<String, dynamic> _calculateDetailedPricing(String category) {
    final cat = category.toLowerCase();
    String baseLabel = 'Base Service';
    int basePrice = 400;
    final List<Map<String, dynamic>> modifiers = [];

    switch (cat) {
      case 'delivery':
        if (_selectedPackageType == 'documents') {
          baseLabel = 'Documents & Letters';
          basePrice = 250;
        } else if (_selectedPackageType == 'food') {
          baseLabel = 'Food & Meal Takeout';
          basePrice = 350;
        } else if (_selectedPackageType == 'heavy') {
          baseLabel = 'Large / Bulky Cargo (>10kg)';
          basePrice = 750;
        } else {
          baseLabel = 'Standard Box / Parcel (<10kg)';
          basePrice = 450;
        }

        // Distance Price Increment (Over 3.0 km base allowance)
        if (!_isRemoteTask && _routeDistanceKm > 3.0) {
          final extraKm = _routeDistanceKm - 3.0;
          final distFee = (extraKm * 20).round();
          modifiers.add({
            'label': 'Distance (${_routeDistanceKm.toStringAsFixed(1)} km · ${extraKm.toStringAsFixed(1)} km extra)',
            'amount': distFee,
          });
        }

        if (_selectedVehicleType == 'car') {
          modifiers.add({'label': 'Car / Van Cargo Transport', 'amount': 150});
        }
        if (_isFragile) {
          modifiers.add({'label': 'Fragile & Safe Packing Handling', 'amount': 50});
        }
        break;

      case 'cleaning':
        if (_selectedCleaningSpace == 'home_1bed') {
          baseLabel = '1-Bed / Studio Apartment';
          basePrice = 400;
        } else if (_selectedCleaningSpace == 'office') {
          baseLabel = 'Commercial Office Space';
          basePrice = 900;
        } else if (_selectedCleaningSpace == 'villa') {
          baseLabel = 'Villa / Large Residence';
          basePrice = 1400;
        } else {
          baseLabel = '2-3 Bed House';
          basePrice = 600;
        }

        if (_selectedCleaningType == 'deep') {
          modifiers.add({'label': 'Deep Clean Hardness', 'amount': 200});
        } else if (_selectedCleaningType == 'move_out') {
          modifiers.add({'label': 'Move-In / Move-Out Clean Hardness', 'amount': 350});
        }

        if (_selectedCleaningAddons.contains('sofa')) {
          if (_selectedSofaType == 'sofa_1pc') {
            modifiers.add({'label': 'Sofa Wash (1-Seat Armchair)', 'amount': 150});
          } else if (_selectedSofaType == 'sofa_lshape') {
            modifiers.add({'label': 'Sofa Wash (L-Shape Sectional)', 'amount': 500});
          } else {
            modifiers.add({'label': 'Sofa Wash (3-Seater Couch)', 'amount': 300});
          }
        }

        if (_selectedCleaningAddons.contains('carpet')) {
          if (_selectedCarpetType == 'carpet_small') {
            modifiers.add({'label': 'Carpet & Rug Wash (Small / Doormats)', 'amount': 150});
          } else if (_selectedCarpetType == 'carpet_large') {
            modifiers.add({'label': 'Carpet Wash (Large / Wall-to-Wall)', 'amount': 500});
          } else {
            modifiers.add({'label': 'Carpet Wash (Living Room Area Rug)', 'amount': 300});
          }
        }

        if (_includeMattressWash) {
          modifiers.add({'label': 'Mattress Steam & Deep Wash', 'amount': 250});
        }
        if (_includeCurtainSteam) {
          modifiers.add({'label': 'Curtains & Drapes Steam Wash', 'amount': 200});
        }
        if (_includeWindowsGlass) {
          modifiers.add({'label': 'Window & Balcony Glass Polish', 'amount': 150});
        }

        if (_selectedSupplyOption == 'tasker_supplies') {
          modifiers.add({'label': 'Tasker Supplies & Detergents', 'amount': 150});
        }
        break;

      case 'moving':
        if (_selectedMoveSize == 'few_items') {
          baseLabel = 'Few Items / Boxes (1-4 pcs)';
          basePrice = 500;
        } else if (_selectedMoveSize == 'home_2_3bed') {
          baseLabel = '2-3 Bed House Load';
          basePrice = 2500;
        } else if (_selectedMoveSize == 'large_villa') {
          baseLabel = 'Villa / Large Office Cargo';
          basePrice = 4500;
        } else {
          baseLabel = 'Studio / 1-Bed Load';
          basePrice = 1200;
        }

        // Distance Price Increment for Moving Trucks (Over 3.0 km base allowance)
        if (!_isRemoteTask && _routeDistanceKm > 3.0) {
          final extraKm = _routeDistanceKm - 3.0;
          final distFee = (extraKm * 60).round();
          modifiers.add({
            'label': 'Transport Distance (${_routeDistanceKm.toStringAsFixed(1)} km · ${extraKm.toStringAsFixed(1)} km extra)',
            'amount': distFee,
          });
        }

        if (_selectedFloorLevel == 'floor_1_2') {
          final amt = _hasElevator ? 50 : 150;
          modifiers.add({'label': '1st-2nd Floor Access ${_hasElevator ? "(Lift)" : "(Stairs)"}', 'amount': amt});
        } else if (_selectedFloorLevel == 'floor_3_plus') {
          final amt = _hasElevator ? 100 : 300;
          modifiers.add({'label': '3rd+ Floor Access ${_hasElevator ? "(Lift)" : "(Stairs Hardness)"}', 'amount': amt});
        }

        if (_needHelpers) {
          modifiers.add({'label': 'Heavy Lifting Assistant Crew', 'amount': 400});
        }
        if (_needPackingMaterials) {
          modifiers.add({'label': 'Bubble Wrap & Boxes', 'amount': 200});
        }
        break;

      case 'shopping':
        if (_selectedShoppingType == 'pharmacy') {
          baseLabel = 'Pharmacy & Prescriptions';
          basePrice = 250;
        } else if (_selectedShoppingType == 'hardware') {
          baseLabel = 'Hardware & Building Supplies';
          basePrice = 350;
        } else {
          baseLabel = 'Groceries & Supermarket';
          basePrice = 300;
        }

        if (!_isRemoteTask && _routeDistanceKm > 3.0) {
          final extraKm = _routeDistanceKm - 3.0;
          final distFee = (extraKm * 15).round();
          modifiers.add({
            'label': 'Delivery Distance (${_routeDistanceKm.toStringAsFixed(1)} km · ${extraKm.toStringAsFixed(1)} km extra)',
            'amount': distFee,
          });
        }

        if (_selectedStorePreference == 'shoa') {
          modifiers.add({'label': 'Shoa Supermarket Queue & Service', 'amount': 50});
        } else if (_selectedStorePreference == 'fresh_corner') {
          modifiers.add({'label': 'Fresh Corner Specialty Store', 'amount': 50});
        }

        if (_shoppingItems.length > 3) {
          final extra = (_shoppingItems.length - 3) * 20;
          modifiers.add({'label': '${_shoppingItems.length} Items Shopping Volume', 'amount': extra});
        }
        break;

      case 'assembly':
        if (_selectedAssemblyType == 'furniture_bed') {
          baseLabel = 'Bed & Wardrobe Assembly';
          basePrice = 600;
        } else if (_selectedAssemblyType == 'table_dining') {
          baseLabel = 'Dining Table & Shelves';
          basePrice = 450;
        } else if (_selectedAssemblyType == 'fitness_gym') {
          baseLabel = 'Gym & Fitness Equipment';
          basePrice = 800;
        } else {
          baseLabel = 'Desks & Study Chairs';
          basePrice = 350;
        }

        if (!_hasAssemblyManual) {
          modifiers.add({'label': 'No Manual / Complex Assembly', 'amount': 100});
        }
        if (_taskerBringsTools) {
          modifiers.add({'label': 'Tasker Power Drill & Tool Kit', 'amount': 50});
        }
        if (_needBoxDisposal) {
          modifiers.add({'label': 'Cardboard Packaging Disposal', 'amount': 100});
        }
        break;

      case 'tech':
        if (_selectedTechDevice == 'wifi_network') {
          baseLabel = 'Wi-Fi & Router Setup';
          basePrice = 350;
        } else if (_selectedTechDevice == 'printer_periph') {
          baseLabel = 'Printer & Peripherals';
          basePrice = 300;
        } else if (_selectedTechDevice == 'smart_tv') {
          baseLabel = 'Smart TV & Sound System';
          basePrice = 350;
        } else {
          baseLabel = 'PC / Laptop Support';
          basePrice = 400;
        }

        if (_selectedTechService == 'hardware_repair') {
          modifiers.add({'label': 'Hardware Disassembly Repair', 'amount': 150});
        } else if (_selectedTechService == 'network_setup') {
          modifiers.add({'label': 'Network Security Setup', 'amount': 100});
        }

        if (_isUrgentTech) {
          modifiers.add({'label': 'Emergency / Immediate IT Dispatch', 'amount': 150});
        }
        break;

      case 'plumbing':
        if (_selectedPlumbingIssue == 'clogged_drain') {
          baseLabel = 'Clogged Drain & Sewer';
          basePrice = 500;
        } else if (_selectedPlumbingIssue == 'fixture_install') {
          baseLabel = 'Faucet & Shower Replacement';
          basePrice = 600;
        } else if (_selectedPlumbingIssue == 'tank_heater') {
          baseLabel = 'Water Tank & Boiler Heater';
          basePrice = 1000;
        } else {
          baseLabel = 'Pipe Leak & Drip Fix';
          basePrice = 400;
        }

        if (_selectedPlumbingUrgency == 'urgent') {
          modifiers.add({'label': 'Active Leak Emergency Level', 'amount': 150});
        }
        if (!_partsProvided) {
          modifiers.add({'label': 'Tasker Sources Spare Parts', 'amount': 100});
        }
        break;

      case 'electrical':
        if (_selectedElectricalJob == 'lighting') {
          baseLabel = 'Lighting & Chandelier Setup';
          basePrice = 350;
        } else if (_selectedElectricalJob == 'sockets') {
          baseLabel = 'Sockets & Switch Points';
          basePrice = 300;
        } else if (_selectedElectricalJob == 'generator') {
          baseLabel = 'Generator & Inverter Wiring';
          basePrice = 800;
        } else {
          baseLabel = 'Short Circuit & Breaker Tripping';
          basePrice = 450;
        }

        if (!_breakerAccessible) {
          modifiers.add({'label': 'Complex Circuit Diagnostics', 'amount': 100});
        }
        if (_needLadder) {
          modifiers.add({'label': 'High Ceiling / Tall Ladder Work', 'amount': 100});
        }
        break;

      case 'handyman':
        if (_selectedHandymanType == 'curtains_art') {
          baseLabel = 'Curtains, Art & Mirror Mount';
          basePrice = 300;
        } else if (_selectedHandymanType == 'doors_locks') {
          baseLabel = 'Doors, Handles & Lock Fix';
          basePrice = 400;
        } else if (_selectedHandymanType == 'wall_repairs') {
          baseLabel = 'Drywall Patch & Plaster';
          basePrice = 500;
        } else {
          baseLabel = 'TV Wall Bracket Mount';
          basePrice = 350;
        }

        if (!_hasBracketsAndScrews) {
          modifiers.add({'label': 'Heavy Wall Anchors & Hardware', 'amount': 100});
        }
        if (_ladderRequired) {
          modifiers.add({'label': 'Heavy Duty Drill & Ladder Setup', 'amount': 100});
        }
        break;

      default:
        baseLabel = 'Custom Task Scope';
        basePrice = 450;
        if (_taskerBringsTools) {
          modifiers.add({'label': 'Tasker Provides Equipment', 'amount': 100});
        }
    }

    // Schedule / Urgency Level Surcharge
    final taskProvider = context.read<TaskProvider>();
    final sched = taskProvider.wizardScheduleType;
    if (sched == 'asap') {
      modifiers.add({'label': 'ASAP Express Priority Dispatch (<1 hr)', 'amount': 150});
    } else if (sched == 'today') {
      modifiers.add({'label': 'Same-Day Afternoon Arrival Window', 'amount': 50});
    } else if (sched == 'scheduled' && _selectedTimeOfDay == 'night') {
      modifiers.add({'label': 'Night Shift / Emergency Slot (9:00 PM+)', 'amount': 100});
    }

    int total = basePrice;
    for (final m in modifiers) {
      total += (m['amount'] as int);
    }

    return {
      'baseLabel': baseLabel,
      'basePrice': basePrice,
      'modifiers': modifiers,
      'total': total,
    };
  }

  void _syncBudgetWithCalculation(String cat) {
    final pricing = _calculateDetailedPricing(cat);
    final total = pricing['total'] as int;
    _budgetController.text = total.toString();
    context.read<TaskProvider>().wizardBudget = total;
  }

  String _getAutoGeneratedTitle(String cat) {
    switch (cat) {
      case 'delivery':
        return 'Delivery of ${_selectedPackageType.replaceAll('_', ' ').toUpperCase()} Package via ${_selectedVehicleType.toUpperCase()}';
      case 'cleaning':
        final sofa = _selectedCleaningAddons.contains('sofa') ? ' + Sofa Wash' : '';
        final carpet = _selectedCleaningAddons.contains('carpet') ? ' + Carpet Wash' : '';
        return 'Cleaning: ${_selectedCleaningSpace.replaceAll('_', ' ').toUpperCase()} (${_selectedCleaningType.toUpperCase()}$sofa$carpet)';
      case 'shopping':
        return 'Shopping: ${_shoppingItems.length} items (${_selectedShoppingType.toUpperCase()}) from ${_selectedStorePreference.replaceAll('_', ' ').toUpperCase()}';
      case 'moving':
        final el = _hasElevator ? 'Elevator' : 'Stairs';
        return 'Moving: ${_selectedMoveSize.replaceAll('_', ' ').toUpperCase()} · Floor $_selectedFloorLevel ($el)';
      case 'assembly':
        return 'Assembly: ${_selectedAssemblyType.replaceAll('_', ' ').toUpperCase()}';
      case 'tech':
        return 'IT Tech: ${_selectedTechDevice.toUpperCase()} (${_selectedTechService.replaceAll('_', ' ').toUpperCase()})';
      case 'plumbing':
        return 'Plumbing: ${_selectedPlumbingIssue.replaceAll('_', ' ').toUpperCase()}';
      case 'electrical':
        return 'Electrical: ${_selectedElectricalJob.replaceAll('_', ' ').toUpperCase()}';
      case 'handyman':
        return 'Handyman: ${_selectedHandymanType.replaceAll('_', ' ').toUpperCase()}';
      default:
        return 'Custom Service Request';
    }
  }

  String _getAutoGeneratedDescription(String cat) {
    switch (cat) {
      case 'delivery':
        final frag = _isFragile ? 'Item is fragile, handle with extra care.' : 'Standard parcel.';
        final rec = _recipientNameController.text.isNotEmpty
            ? 'Deliver to ${_recipientNameController.text} (${_recipientPhoneController.text}).'
            : '';
        final proof = _requirePhotoProof ? 'Photo proof required on delivery handover.' : '';
        return 'Requesting delivery of $_selectedPackageType package using $_selectedVehicleType transport. $frag $rec $proof'.replaceAll(RegExp(r'\s+'), ' ').trim();
      case 'cleaning':
        final sofa = _selectedCleaningAddons.contains('sofa') ? 'Includes sofa wash ($_selectedSofaType).' : '';
        final carpet = _selectedCleaningAddons.contains('carpet') ? 'Includes carpet wash ($_selectedCarpetType).' : '';
        final mat = _includeMattressWash ? 'Includes mattress steam cleaning.' : '';
        final cur = _includeCurtainSteam ? 'Includes curtains steam cleaning.' : '';
        final win = _includeWindowsGlass ? 'Includes windows & glass polishing.' : '';
        final sup = _selectedSupplyOption == 'tasker_supplies' ? 'Tasker provides cleaning supplies & equipment.' : 'Customer provides cleaning supplies.';
        return 'Professional $_selectedCleaningType cleaning for ${_selectedCleaningSpace.replaceAll('_', ' ')}. $sofa $carpet $mat $cur $win $sup'.replaceAll(RegExp(r'\s+'), ' ').trim();
      case 'shopping':
        final itemsStr = _shoppingItems.map((e) => '${e['name']} (${e['qty']})').join(', ');
        final goods = _estimatedGoodsCostController.text.isNotEmpty ? 'Estimated goods cost: ${_estimatedGoodsCostController.text} ETB.' : '';
        final rec = _requireItemizedReceipt ? 'Original store receipt required.' : '';
        final sub = _allowSubstitutions ? 'Substitutions permitted after confirmation.' : '';
        return 'Purchase and delivery from ${_selectedStorePreference.replaceAll('_', ' ')}. Items ($itemsStr). $goods $rec $sub'.replaceAll(RegExp(r'\s+'), ' ').trim();
      case 'moving':
        final el = _hasElevator ? 'Elevator available' : 'Stairs only (no elevator)';
        final help = _needHelpers ? '1 lifting helper requested.' : 'Driver only.';
        final pack = _needPackingMaterials ? 'Tasker supplies packing materials & boxes.' : 'Items pre-packed.';
        return 'Moving & relocation assistance for ${_selectedMoveSize.replaceAll('_', ' ')}. Located on Floor $_selectedFloorLevel ($el). $help $pack'.replaceAll(RegExp(r'\s+'), ' ').trim();
      case 'assembly':
        final man = _hasAssemblyManual ? 'Assembly manual available.' : 'No manual, experienced assembly needed.';
        final tools = _taskerBringsTools ? 'Tasker must bring power drill and tool kit.' : 'Customer supplies tools.';
        final disp = _needBoxDisposal ? 'Cardboard packaging disposal required.' : '';
        return 'Assembly and setup for ${_selectedAssemblyType.replaceAll('_', ' ')}. $man $tools $disp'.replaceAll(RegExp(r'\s+'), ' ').trim();
      case 'tech':
        final urg = _isUrgentTech ? 'Urgent priority IT fix needed.' : 'Standard scheduling.';
        return 'Tech and IT support for ${_selectedTechDevice.replaceAll('_', ' ')}. Scope: ${_selectedTechService.replaceAll('_', ' ')}. $urg'.replaceAll(RegExp(r'\s+'), ' ').trim();
      case 'plumbing':
        final parts = _partsProvided ? 'Replacement parts on site.' : 'Tasker should assess and source parts.';
        return 'Plumbing repair for ${_selectedPlumbingIssue.replaceAll('_', ' ')}. Urgency: $_selectedPlumbingUrgency. $parts'.replaceAll(RegExp(r'\s+'), ' ').trim();
      case 'electrical':
        final acc = _breakerAccessible ? 'Circuit breaker is accessible.' : 'Breaker inspection required.';
        final lad = _needLadder ? 'Tasker must bring tall ladder.' : '';
        return 'Electrical service for ${_selectedElectricalJob.replaceAll('_', ' ')}. $acc $lad'.replaceAll(RegExp(r'\s+'), ' ').trim();
      case 'handyman':
        final hw = _hasBracketsAndScrews ? 'Mounting hardware provided.' : 'Tasker provides mounting screws and brackets.';
        final lad = _ladderRequired ? 'Tall ladder required.' : '';
        return 'Handyman job: ${_selectedHandymanType.replaceAll('_', ' ')}. $hw $lad'.replaceAll(RegExp(r'\s+'), ' ').trim();
      default:
        return 'Custom service task request in Addis Ababa. Tasker provides standard tools and equipment.';
    }
  }

  void _nextStep() {
    final taskProvider = context.read<TaskProvider>();
    final cat = taskProvider.wizardCategory.toLowerCase();

    if (_currentStep == 2) {
      // Auto-fill title if user left it blank
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = _getAutoGeneratedTitle(cat);
      }

      // Auto-fill description if user left it blank
      if (_descController.text.trim().isEmpty) {
        _descController.text = _getAutoGeneratedDescription(cat);
      }

      String fullInstructions = _instructionsController.text.trim();
      final details = <String>[];

      if (cat == 'delivery') {
        details.add('Package Type: ${_selectedPackageType.toUpperCase()}');
        details.add('Vehicle: ${_selectedVehicleType.toUpperCase()}');
        if (_isFragile) details.add('Handling: FRAGILE');
        if (_recipientNameController.text.isNotEmpty) {
          details.add('Recipient: ${_recipientNameController.text} (${_recipientPhoneController.text})');
        }
        if (_requirePhotoProof) details.add('Handover Proof: PHOTO REQUIRED');
      } else if (cat == 'cleaning') {
        details.add('Property Size: ${_selectedCleaningSpace.replaceAll("_", " ").toUpperCase()}');
        details.add('Clean Depth: ${_selectedCleaningType.toUpperCase()}');
        details.add('Supplies: ${_selectedSupplyOption == "tasker_supplies" ? "TASKER BRINGS" : "CUSTOMER HAS"}');
        if (_selectedCleaningAddons.contains('sofa')) details.add('Sofa Wash: ${_selectedSofaType.replaceAll("_", " ").toUpperCase()}');
        if (_selectedCleaningAddons.contains('carpet')) details.add('Carpet Wash: ${_selectedCarpetType.replaceAll("_", " ").toUpperCase()}');
        if (_includeMattressWash) details.add('Mattress Steam: INCLUDED');
        if (_includeCurtainSteam) details.add('Curtains Steam: INCLUDED');
        if (_includeWindowsGlass) details.add('Glass Polish: INCLUDED');
      } else if (cat == 'shopping') {
        details.add('Shopping Scope: ${_selectedShoppingType.toUpperCase()}');
        details.add('Target Store: ${_selectedStorePreference.replaceAll("_", " ").toUpperCase()}');
        if (_shoppingItems.isNotEmpty) {
          final itemsSummary = _shoppingItems.map((e) => '${e['name']} (${e['qty']})').join(', ');
          details.add('Items: $itemsSummary');
        }
        if (_estimatedGoodsCostController.text.isNotEmpty) {
          details.add('Goods Budget: ${_estimatedGoodsCostController.text} ETB');
        }
        if (_requireItemizedReceipt) details.add('Receipt: REQUIRED');
        if (_allowSubstitutions) details.add('Substitutions: ALLOWED ON CALL');
      } else if (cat == 'moving') {
        details.add('Move Size: ${_selectedMoveSize.replaceAll("_", " ").toUpperCase()}');
        details.add('Floor Level: FLOOR $_selectedFloorLevel');
        details.add('Elevator: ${_hasElevator ? "YES" : "NO"}');
        if (_needHelpers) details.add('Helpers: 1 HELPER REQUESTED');
        if (_needPackingMaterials) details.add('Packing Kit: MATERIALS NEEDED');
      } else if (cat == 'assembly') {
        details.add('Item: ${_selectedAssemblyType.replaceAll("_", " ").toUpperCase()}');
        details.add('Manual: ${_hasAssemblyManual ? "AVAILABLE" : "NOT AVAILABLE"}');
        details.add('Tools: ${_taskerBringsTools ? "TASKER BRINGS TOOLS" : "CUSTOMER HAS TOOLS"}');
      } else if (cat == 'tech') {
        details.add('Device: ${_selectedTechDevice.toUpperCase()}');
        details.add('Service: ${_selectedTechService.replaceAll("_", " ").toUpperCase()}');
        if (_isUrgentTech) details.add('Urgency: URGENT IT FIX');
      } else if (cat == 'plumbing') {
        details.add('Plumbing Issue: ${_selectedPlumbingIssue.replaceAll("_", " ").toUpperCase()}');
        details.add('Urgency: ${_selectedPlumbingUrgency.toUpperCase()}');
        details.add('Parts: ${_partsProvided ? "PARTS ON SITE" : "TASKER BRINGS PARTS"}');
      } else if (cat == 'electrical') {
        details.add('Electrical Job: ${_selectedElectricalJob.replaceAll("_", " ").toUpperCase()}');
        details.add('Breaker Access: ${_breakerAccessible ? "ACCESSIBLE" : "REQUIRES CHECK"}');
        if (_needLadder) details.add('Equipment: TALL LADDER NEEDED');
      } else if (cat == 'handyman') {
        details.add('Handyman Scope: ${_selectedHandymanType.replaceAll("_", " ").toUpperCase()}');
        details.add('Mounting Hardware: ${_hasBracketsAndScrews ? "AVAILABLE" : "TASKER BRINGS"}');
        if (_ladderRequired) details.add('Equipment: TALL LADDER NEEDED');
      } else if (cat == 'other') {
        details.add('Category: CUSTOM TASK');
        if (_taskerBringsTools) details.add('Equipment: TASKER BRINGS EQUIPMENT');
      }

      if (details.isNotEmpty) {
        final extra = details.join(' | ');
        fullInstructions = fullInstructions.isEmpty ? extra : '$fullInstructions\n($extra)';
      }

      taskProvider.wizardTitle = _titleController.text.trim();
      taskProvider.wizardDescription = _descController.text.trim();
      taskProvider.wizardSpecialInstructions = fullInstructions;
      taskProvider.wizardQuantity = int.tryParse(_quantityController.text) ?? 1;

      _syncBudgetWithCalculation(cat);
    } else if (_currentStep == 3) {
      if (_isRemoteTask) {
        taskProvider.wizardPickupAddress = 'Online / Remote Task';
        taskProvider.wizardDropoffAddress = 'Remote (No physical address)';
      } else {
        final pUnit = _pickupUnitController.text.trim();
        final dUnit = _dropoffUnitController.text.trim();
        taskProvider.wizardPickupAddress = pUnit.isEmpty ? _pickupController.text.trim() : '${_pickupController.text.trim()} ($pUnit)';
        taskProvider.wizardDropoffAddress = dUnit.isEmpty ? _dropoffController.text.trim() : '${_dropoffController.text.trim()} ($dUnit)';
      }
      _syncBudgetWithCalculation(cat);
    } else if (_currentStep == 5) {
      taskProvider.wizardBudget = int.tryParse(_budgetController.text) ?? 450;
    }

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitTask();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitTask() async {
    final taskProvider = context.read<TaskProvider>();
    final newTask = await taskProvider.submitWizardTask();

    if (newTask != null && mounted) {
      setState(() {
        _isSuccess = true;
      });
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Category';
      case 2:
        return 'Task Details';
      case 3:
        return 'Location & Route';
      case 4:
        return 'Schedule';
      case 5:
        return 'Budget';
      case 6:
        return 'Review';
      default:
        return 'Post Task';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessScreen();
    }

    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _prevStep,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              'Step $_currentStep of $_totalSteps',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              _getStepTitle(),
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _currentStep / _totalSteps,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                child: _buildStepContent(taskProvider),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: FinishButton(
                text: _currentStep == _totalSteps ? 'Post Task Now' : 'Continue',
                isLoading: taskProvider.isLoading,
                onPressed: _nextStep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(TaskProvider taskProvider) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Category(taskProvider);
      case 2:
        return _buildStep2Details(taskProvider);
      case 3:
        return _buildStep3Location(taskProvider);
      case 4:
        return _buildStep4Schedule(taskProvider);
      case 5:
        return _buildStep5Budget(taskProvider);
      case 6:
        return _buildStep6Review(taskProvider);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Category Selection
  Widget _buildStep1Category(TaskProvider taskProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What needs to be done?',
          style: AppTypography.displayLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select the category that best describes your task.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 18),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _wizardCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            final cat = _wizardCategories[index];
            final isSelected = taskProvider.wizardCategory == cat['id'];
            final color = cat['color'] as Color;

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  taskProvider.wizardCategory = cat['id'] as String;
                  _syncBudgetWithCalculation(cat['id'] as String);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? color.withOpacity(0.16) : Colors.black.withOpacity(0.02),
                      blurRadius: isSelected ? 10 : 4,
                      offset: isSelected ? const Offset(0, 4) : const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.18) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          cat['icon'] as IconData,
                          size: 22,
                          color: isSelected ? color : AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected ? color : AppColors.textDark,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 11.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              taskProvider.wizardCategory = 'other';
              _syncBudgetWithCalculation('other');
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: taskProvider.wizardCategory == 'other' ? const Color(0xFFEEF2FF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: taskProvider.wizardCategory == 'other' ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                width: taskProvider.wizardCategory == 'other' ? 1.8 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_task_rounded, size: 20, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Can't find your category?",
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4338CA),
                        ),
                      ),
                      Text(
                        'Tap here to post a custom or other service task',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF6366F1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: Dynamically Tailored Details with Hardness & Pricing Breakdown
  Widget _buildStep2Details(TaskProvider taskProvider) {
    final cat = taskProvider.wizardCategory.toLowerCase();

    Color headerBg;
    Color headerBorder;
    Color headerIconColor;
    Color headerTextColor;
    String headerTitle;
    String headerSubtitle;
    IconData headerIcon;

    switch (cat) {
      case 'delivery':
        headerBg = const Color(0xFFE6FCF5);
        headerBorder = const Color(0xFF63E6BE);
        headerIconColor = const Color(0xFF087F5B);
        headerTextColor = const Color(0xFF065F44);
        headerTitle = 'Delivery Task Details';
        headerSubtitle = 'Select package type, transport mode, and recipient info.';
        headerIcon = Icons.local_shipping_outlined;
        break;
      case 'cleaning':
        headerBg = const Color(0xFFF0F9FF);
        headerBorder = const Color(0xFF7DD3FC);
        headerIconColor = const Color(0xFF0284C7);
        headerTextColor = const Color(0xFF0369A1);
        headerTitle = 'Cleaning Task Details';
        headerSubtitle = 'Select property type, cleaning depth, and supply options.';
        headerIcon = Icons.cleaning_services_outlined;
        break;
      case 'shopping':
        headerBg = const Color(0xFFFFFBEB);
        headerBorder = const Color(0xFFFDE68A);
        headerIconColor = const Color(0xFFD97706);
        headerTextColor = const Color(0xFFB45309);
        headerTitle = 'Shopping & Errands Details';
        headerSubtitle = 'Specify shopping list, store preference, and goods budget.';
        headerIcon = Icons.shopping_bag_outlined;
        break;
      case 'moving':
        headerBg = const Color(0xFFF5F3FF);
        headerBorder = const Color(0xFFDDD6FE);
        headerIconColor = const Color(0xFF7C3AED);
        headerTextColor = const Color(0xFF6D28D9);
        headerTitle = 'Moving & Transport Details';
        headerSubtitle = 'Select load size, floor level, and lifting assistance.';
        headerIcon = Icons.inventory_2_outlined;
        break;
      case 'assembly':
        headerBg = const Color(0xFFFFF7ED);
        headerBorder = const Color(0xFFFED7AA);
        headerIconColor = const Color(0xFFEA580C);
        headerTextColor = const Color(0xFFC2410C);
        headerTitle = 'Assembly & Installation Details';
        headerSubtitle = 'Specify furniture items, manuals, and tool requirements.';
        headerIcon = Icons.build_outlined;
        break;
      case 'tech':
        headerBg = const Color(0xFFEFF6FF);
        headerBorder = const Color(0xFFBFDBFE);
        headerIconColor = const Color(0xFF2563EB);
        headerTextColor = const Color(0xFF1D4ED8);
        headerTitle = 'Technology & IT Support Details';
        headerSubtitle = 'Select device type, issue category, and urgency level.';
        headerIcon = Icons.laptop_chromebook_outlined;
        break;
      case 'plumbing':
        headerBg = const Color(0xFFF0FDFA);
        headerBorder = const Color(0xFF99F6E4);
        headerIconColor = const Color(0xFF0D9488);
        headerTextColor = const Color(0xFF0F766E);
        headerTitle = 'Plumbing & Pipe Details';
        headerSubtitle = 'Select leak/fixture type, emergency status, and spare parts.';
        headerIcon = Icons.plumbing_outlined;
        break;
      case 'electrical':
        headerBg = const Color(0xFFFFFBEB);
        headerBorder = const Color(0xFFFDE68A);
        headerIconColor = const Color(0xFFB45309);
        headerTextColor = const Color(0xFF92400E);
        headerTitle = 'Electrical & Wiring Details';
        headerSubtitle = 'Select circuit type, fixtures, and safety accessibility.';
        headerIcon = Icons.electrical_services_outlined;
        break;
      case 'handyman':
        headerBg = const Color(0xFFF8FAFC);
        headerBorder = const Color(0xFFCBD5E1);
        headerIconColor = const Color(0xFF475569);
        headerTextColor = const Color(0xFF334155);
        headerTitle = 'Handyman & Mounting Details';
        headerSubtitle = 'Specify mounting items, wall type, and hardware available.';
        headerIcon = Icons.handyman_outlined;
        break;
      case 'other':
      default:
        headerBg = const Color(0xFFEEF2FF);
        headerBorder = const Color(0xFFC7D2FE);
        headerIconColor = const Color(0xFF6366F1);
        headerTextColor = const Color(0xFF4338CA);
        headerTitle = 'Custom Task Details';
        headerSubtitle = 'Provide tailored instructions for your unique service request.';
        headerIcon = Icons.add_task_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: headerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: headerBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: headerIconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(headerIcon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerTitle,
                      style: AppTypography.labelLarge.copyWith(
                        color: headerTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      headerSubtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: headerIconColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (cat == 'delivery')
          _buildDeliverySpecializedSection()
        else if (cat == 'cleaning')
          _buildCleaningSpecializedSection()
        else if (cat == 'shopping')
          _buildShoppingSpecializedSection()
        else if (cat == 'moving')
          _buildMovingSpecializedSection()
        else if (cat == 'assembly')
          _buildAssemblySpecializedSection()
        else if (cat == 'tech')
          _buildTechSpecializedSection()
        else if (cat == 'plumbing')
          _buildPlumbingSpecializedSection()
        else if (cat == 'electrical')
          _buildElectricalSpecializedSection()
        else if (cat == 'handyman')
          _buildHandymanSpecializedSection()
        else
          _buildOtherSpecializedSection(),

        const SizedBox(height: 16),
        _buildLiveTotalPricingCard(cat, headerIconColor),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Title & Description',
              style: AppTypography.titleSmall.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _titleController.text = _getAutoGeneratedTitle(cat);
                  _descController.text = _getAutoGeneratedDescription(cat);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auto-filled title & description from your selected specifications!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_fix_high_rounded, size: 13, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      'Auto-fill from Scope',
                      style: AppTypography.labelMedium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Leave blank to automatically use your selected specifications above.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 11.5),
        ),
        const SizedBox(height: 12),

        FinishTextField(
          controller: _titleController,
          label: 'Task Title',
          hintText: _getAutoGeneratedTitle(cat),
        ),
        const SizedBox(height: 14),

        FinishTextField(
          controller: _descController,
          label: 'Description & Details',
          hintText: _getAutoGeneratedDescription(cat),
          maxLines: 3,
        ),
        const SizedBox(height: 14),

        FinishTextField(
          controller: _instructionsController,
          label: 'Special instructions (optional)',
          hintText: 'e.g. Call before arrival, gate code, parking notes',
        ),

        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Special instructions updated for taskers.')),
              );
            },
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
            label: Text(
              'Add another requirement or note',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Live Total Price & Hardness Breakdown Widget (Safe against overflow)
  Widget _buildLiveTotalPricingCard(String cat, Color themeColor) {
    final pricing = _calculateDetailedPricing(cat);
    final baseLabel = pricing['baseLabel'] as String;
    final basePrice = pricing['basePrice'] as int;
    final modifiers = pricing['modifiers'] as List<Map<String, dynamic>>;
    final total = pricing['total'] as int;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, size: 18, color: themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LIVE PRICE & HARDNESS BREAKDOWN',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: themeColor,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  baseLabel,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$basePrice ETB',
                style: AppTypography.labelMedium.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),

          for (final m in modifiers) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          m['label'] as String,
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${m['amount']} ETB',
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 18, color: Color(0xFFF3F4F6)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL ESTIMATED PRICE',
                      style: AppTypography.labelMedium.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Guaranteed fair market budget',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: themeColor.withOpacity(0.3)),
                ),
                child: Text(
                  '$total ETB',
                  style: AppTypography.titleSmall.copyWith(
                    color: themeColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. Delivery Section with Dynamic Price Updating by Package Type & Vehicle
  Widget _buildDeliverySpecializedSection() {
    final packageTypes = [
      {'id': 'documents', 'label': 'Documents', 'sub': 'Letters & Contracts', 'price': 250, 'icon': Icons.description_outlined},
      {'id': 'food', 'label': 'Food & Meal', 'sub': 'Takeout & Groceries', 'price': 350, 'icon': Icons.restaurant_outlined},
      {'id': 'box', 'label': 'Box / Parcel', 'sub': 'Under 10 kg', 'price': 450, 'icon': Icons.inventory_2_outlined},
      {'id': 'heavy', 'label': 'Large / Bulky', 'sub': 'Over 10 kg', 'price': 750, 'icon': Icons.takeout_dining_outlined},
    ];

    final vehicleTypes = [
      {'id': 'motorcycle', 'label': 'Motorcycle', 'extra': '+0 ETB', 'icon': Icons.two_wheeler_outlined},
      {'id': 'car', 'label': 'Car / Van', 'extra': '+150 ETB', 'icon': Icons.directions_car_outlined},
      {'id': 'any', 'label': 'Any Vehicle', 'extra': '+0 ETB', 'icon': Icons.check_circle_outline_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Package Type & Base Rates'),
        _buildGridSelector(packageTypes, _selectedPackageType, const Color(0xFF087F5B), const Color(0xFFE6FCF5), (id) {
          setState(() {
            _selectedPackageType = id;
            _syncBudgetWithCalculation('delivery');
          });
        }),
        const SizedBox(height: 14),

        _buildSectionHeader('Vehicle Preference & Capacity'),
        _buildRowSelector(vehicleTypes, _selectedVehicleType, const Color(0xFF087F5B), const Color(0xFFE6FCF5), (id) {
          setState(() {
            _selectedVehicleType = id;
            _syncBudgetWithCalculation('delivery');
          });
        }),
        const SizedBox(height: 14),

        _buildCheckboxRow('Package is fragile / Handle with care (+50 ETB)', _isFragile, const Color(0xFF087F5B), (v) {
          setState(() {
            _isFragile = v;
            _syncBudgetWithCalculation('delivery');
          });
        }),
        _buildCheckboxRow('Require photo handover proof upon delivery', _requirePhotoProof, const Color(0xFF087F5B), (v) {
          setState(() => _requirePhotoProof = v);
        }),
      ],
    );
  }

  // 2. Cleaning Section with Sofa, Carpet, Mattress & Glass Deep Wash
  Widget _buildCleaningSpecializedSection() {
    final spaces = [
      {'id': 'home_1bed', 'label': '1-Bed / Studio', 'sub': 'Apartment', 'price': 400, 'icon': Icons.apartment_outlined},
      {'id': 'home_2bed', 'label': '2-3 Bed House', 'sub': 'Standard Family', 'price': 600, 'icon': Icons.home_outlined},
      {'id': 'office', 'label': 'Office / Space', 'sub': 'Commercial unit', 'price': 900, 'icon': Icons.business_outlined},
      {'id': 'villa', 'label': 'Villa / Large', 'sub': 'Compound / 4+ Bed', 'price': 1400, 'icon': Icons.deck_outlined},
    ];

    final cleaningTypes = [
      {'id': 'standard', 'label': 'Standard Clean', 'extra': '+0 ETB', 'icon': Icons.cleaning_services_outlined},
      {'id': 'deep', 'label': 'Deep Clean', 'extra': '+200 ETB', 'icon': Icons.auto_awesome_outlined},
      {'id': 'move_out', 'label': 'Move-In / Out', 'extra': '+350 ETB', 'icon': Icons.all_inclusive_rounded},
    ];

    final sofaSizes = [
      {'id': 'sofa_1pc', 'label': '1-Seat Armchair', 'extra': '+150 ETB', 'icon': Icons.chair_outlined},
      {'id': 'sofa_3seater', 'label': '3-Seater Couch', 'extra': '+300 ETB', 'icon': Icons.weekend_outlined},
      {'id': 'sofa_lshape', 'label': 'L-Shape Sectional', 'extra': '+500 ETB', 'icon': Icons.chair_rounded},
    ];

    final carpetSizes = [
      {'id': 'carpet_small', 'label': 'Small Rug / Doormat', 'extra': '+150 ETB', 'icon': Icons.crop_portrait_outlined},
      {'id': 'carpet_medium', 'label': 'Living Room Rug', 'extra': '+300 ETB', 'icon': Icons.crop_square_rounded},
      {'id': 'carpet_large', 'label': 'Large Wall-to-Wall', 'extra': '+500 ETB', 'icon': Icons.fullscreen_rounded},
    ];

    final supplyOptions = [
      {'id': 'customer_supplies', 'label': 'I Have Supplies', 'extra': '+0 ETB', 'icon': Icons.inventory_2_outlined},
      {'id': 'tasker_supplies', 'label': 'Tasker Brings Supplies', 'extra': '+150 ETB', 'icon': Icons.sanitizer_outlined},
    ];

    final addonCategories = [
      {'id': 'sofa', 'label': 'Sofa & Couch Wash', 'icon': Icons.weekend_outlined},
      {'id': 'carpet', 'label': 'Carpet & Rug Wash', 'icon': Icons.layers_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Space / Property Size'),
        _buildGridSelector(spaces, _selectedCleaningSpace, const Color(0xFF0284C7), const Color(0xFFF0F9FF), (id) {
          setState(() {
            _selectedCleaningSpace = id;
            _syncBudgetWithCalculation('cleaning');
          });
        }),
        const SizedBox(height: 14),

        _buildSectionHeader('Cleaning Depth & Hardness Level'),
        _buildRowSelector(cleaningTypes, _selectedCleaningType, const Color(0xFF0284C7), const Color(0xFFF0F9FF), (id) {
          setState(() {
            _selectedCleaningType = id;
            _syncBudgetWithCalculation('cleaning');
          });
        }),
        const SizedBox(height: 16),

        // Sofa, Carpet & Upholstery Deep Cleaning Section
        _buildSectionHeader('Sofa, Carpet & Upholstery Add-ons'),
        Row(
          children: [
            for (final addon in addonCategories)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (_selectedCleaningAddons.contains(addon['id'])) {
                          _selectedCleaningAddons.remove(addon['id']);
                        } else {
                          _selectedCleaningAddons.add(addon['id'] as String);
                        }
                        _syncBudgetWithCalculation('cleaning');
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _selectedCleaningAddons.contains(addon['id']) ? const Color(0xFFE0F2FE) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedCleaningAddons.contains(addon['id']) ? const Color(0xFF0284C7) : const Color(0xFFE5E7EB),
                          width: _selectedCleaningAddons.contains(addon['id']) ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            addon['icon'] as IconData,
                            size: 16,
                            color: _selectedCleaningAddons.contains(addon['id']) ? const Color(0xFF0284C7) : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              addon['label'] as String,
                              style: AppTypography.labelMedium.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _selectedCleaningAddons.contains(addon['id']) ? const Color(0xFF0369A1) : AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedCleaningAddons.contains(addon['id']))
                            const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF0284C7)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (_selectedCleaningAddons.contains('sofa')) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0, top: 4.0),
            child: Text(
              'Select Sofa / Couch Size:',
              style: AppTypography.labelMedium.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0369A1)),
            ),
          ),
          _buildRowSelector(sofaSizes, _selectedSofaType, const Color(0xFF0284C7), const Color(0xFFF0F9FF), (id) {
            setState(() {
              _selectedSofaType = id;
              _syncBudgetWithCalculation('cleaning');
            });
          }),
          const SizedBox(height: 12),
        ],

        if (_selectedCleaningAddons.contains('carpet')) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0, top: 4.0),
            child: Text(
              'Select Carpet & Rug Size:',
              style: AppTypography.labelMedium.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0369A1)),
            ),
          ),
          _buildRowSelector(carpetSizes, _selectedCarpetType, const Color(0xFF0284C7), const Color(0xFFF0F9FF), (id) {
            setState(() {
              _selectedCarpetType = id;
              _syncBudgetWithCalculation('cleaning');
            });
          }),
          const SizedBox(height: 12),
        ],

        _buildCheckboxRow('Mattress Deep Steam Wash (+250 ETB)', _includeMattressWash, const Color(0xFF0284C7), (v) {
          setState(() {
            _includeMattressWash = v;
            _syncBudgetWithCalculation('cleaning');
          });
        }),
        _buildCheckboxRow('Curtains & Drapes Steam Cleaning (+200 ETB)', _includeCurtainSteam, const Color(0xFF0284C7), (v) {
          setState(() {
            _includeCurtainSteam = v;
            _syncBudgetWithCalculation('cleaning');
          });
        }),
        _buildCheckboxRow('Window & Balcony Glass Polish (+150 ETB)', _includeWindowsGlass, const Color(0xFF0284C7), (v) {
          setState(() {
            _includeWindowsGlass = v;
            _syncBudgetWithCalculation('cleaning');
          });
        }),
        const SizedBox(height: 14),

        _buildSectionHeader('Cleaning Supplies & Equipment'),
        _buildRowSelector(supplyOptions, _selectedSupplyOption, const Color(0xFF0284C7), const Color(0xFFF0F9FF), (id) {
          setState(() {
            _selectedSupplyOption = id;
            _syncBudgetWithCalculation('cleaning');
          });
        }),
      ],
    );
  }

  // 3. Shopping Section with Interactive Itemized Shopping List Builder
  Widget _buildShoppingSpecializedSection() {
    final shoppingTypes = [
      {'id': 'groceries', 'label': 'Groceries & Food', 'sub': 'Supermarket items', 'price': 300, 'icon': Icons.shopping_cart_outlined},
      {'id': 'pharmacy', 'label': 'Pharmacy & Meds', 'sub': 'Prescriptions & health', 'price': 250, 'icon': Icons.medication_outlined},
      {'id': 'hardware', 'label': 'Hardware & Tools', 'sub': 'Building & home repair', 'price': 350, 'icon': Icons.handyman_outlined},
      {'id': 'custom', 'label': 'Specialty Store', 'sub': 'Specific boutique/bakery', 'price': 300, 'icon': Icons.storefront_outlined},
    ];

    final storeOptions = [
      {'id': 'any_store', 'label': 'Any Store', 'extra': '+0 ETB', 'icon': Icons.store_outlined},
      {'id': 'shoa', 'label': 'Shoa Supermarket', 'extra': '+50 ETB', 'icon': Icons.shopping_bag_outlined},
      {'id': 'fresh_corner', 'label': 'Fresh Corner', 'extra': '+50 ETB', 'icon': Icons.eco_outlined},
    ];

    final quickSuggestions = [
      {'name': 'Mineral Water (5L)', 'qty': '2'},
      {'name': 'Cooking Oil (3L)', 'qty': '1'},
      {'name': 'Bananas', 'qty': '1 kg'},
      {'name': 'Coffee Beans / Powder', 'qty': '500g'},
      {'name': 'Paracetamol 500mg', 'qty': '1 box'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Shopping Category'),
        _buildGridSelector(shoppingTypes, _selectedShoppingType, const Color(0xFFD97706), const Color(0xFFFFFBEB), (id) {
          setState(() {
            _selectedShoppingType = id;
            _syncBudgetWithCalculation('shopping');
          });
        }),
        const SizedBox(height: 14),

        _buildSectionHeader('Store Preference'),
        _buildRowSelector(storeOptions, _selectedStorePreference, const Color(0xFFD97706), const Color(0xFFFFFBEB), (id) {
          setState(() {
            _selectedStorePreference = id;
            _syncBudgetWithCalculation('shopping');
          });
        }),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Items to Buy'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                '${_shoppingItems.length} items added',
                style: AppTypography.labelMedium.copyWith(
                  color: const Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _newItemNameController,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Item name (e.g. Fresh Milk, Apples)',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 24, color: const Color(0xFFE5E7EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _newItemQtyController,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Qty (e.g. 2 pcs, 1kg)',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      final name = _newItemNameController.text.trim();
                      final qty = _newItemQtyController.text.trim();
                      if (name.isNotEmpty) {
                        setState(() {
                          _shoppingItems.add({'name': name, 'qty': qty.isNotEmpty ? qty : '1'});
                          _newItemNameController.clear();
                          _newItemQtyController.text = '1';
                          _syncBudgetWithCalculation('shopping');
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 16, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            'Add',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final sug in quickSuggestions)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _shoppingItems.add({'name': sug['name']!, 'qty': sug['qty']!});
                        _syncBudgetWithCalculation('shopping');
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 12, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            '${sug['name']}',
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 10.5,
                              color: const Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_shoppingItems.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shoppingItems.length,
              separatorBuilder: (context, idx) => const Divider(height: 12, color: Color(0xFFF3F4F6)),
              itemBuilder: (context, idx) {
                final item = _shoppingItems[idx];
                return Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['name'] ?? '',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['qty'] ?? '1',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _shoppingItems.removeAt(idx);
                          _syncBudgetWithCalculation('shopping');
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        _buildSectionHeader('Estimated Goods Cost (ETB)'),
        TextField(
          controller: _estimatedGoodsCostController,
          keyboardType: TextInputType.number,
          style: AppTypography.titleSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'e.g. 800',
            suffixText: 'ETB',
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          ),
        ),
        const SizedBox(height: 10),
        _buildCheckboxRow('Require itemized store receipt', _requireItemizedReceipt, const Color(0xFFD97706), (v) {
          setState(() => _requireItemizedReceipt = v);
        }),
        _buildCheckboxRow('Call me for item brand substitutions', _allowSubstitutions, const Color(0xFFD97706), (v) {
          setState(() => _allowSubstitutions = v);
        }),
      ],
    );
  }

  // 4. Moving Section
  Widget _buildMovingSpecializedSection() {
    final moveSizes = [
      {'id': 'few_items', 'label': 'Few Items / Boxes', 'sub': '1-4 pieces', 'price': 500, 'icon': Icons.inventory_2_outlined},
      {'id': 'studio_1bed', 'label': 'Studio / 1-Bed', 'sub': 'Mini truck load', 'price': 1200, 'icon': Icons.local_shipping_outlined},
      {'id': 'home_2_3bed', 'label': '2-3 Bed House', 'sub': 'Medium ISUZU load', 'price': 2500, 'icon': Icons.fire_truck_outlined},
      {'id': 'large_villa', 'label': 'Villa / Office', 'sub': 'Multiple truck loads', 'price': 4500, 'icon': Icons.warehouse_outlined},
    ];

    final floors = [
      {'id': 'ground', 'label': 'Ground Floor', 'extra': '+0 ETB', 'icon': Icons.looks_one_outlined},
      {'id': 'floor_1_2', 'label': '1st - 2nd Floor', 'extra': '+150 ETB', 'icon': Icons.looks_two_outlined},
      {'id': 'floor_3_plus', 'label': '3rd Floor +', 'extra': '+300 ETB', 'icon': Icons.looks_3_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Move & Load Size'),
        _buildGridSelector(moveSizes, _selectedMoveSize, const Color(0xFF7C3AED), const Color(0xFFF5F3FF), (id) {
          setState(() {
            _selectedMoveSize = id;
            _syncBudgetWithCalculation('moving');
          });
        }),
        const SizedBox(height: 14),

        _buildSectionHeader('Floor & Building Access Hardness'),
        _buildRowSelector(floors, _selectedFloorLevel, const Color(0xFF7C3AED), const Color(0xFFF5F3FF), (id) {
          setState(() {
            _selectedFloorLevel = id;
            _syncBudgetWithCalculation('moving');
          });
        }),
        const SizedBox(height: 12),

        _buildCheckboxRow('Elevator / Lift is available (Reduces floor hardness)', _hasElevator, const Color(0xFF7C3AED), (v) {
          setState(() {
            _hasElevator = v;
            _syncBudgetWithCalculation('moving');
          });
        }),
        _buildCheckboxRow('Heavy lifting helper / crew needed (+400 ETB)', _needHelpers, const Color(0xFF7C3AED), (v) {
          setState(() {
            _needHelpers = v;
            _syncBudgetWithCalculation('moving');
          });
        }),
        _buildCheckboxRow('Packing materials / bubble wrap needed (+200 ETB)', _needPackingMaterials, const Color(0xFF7C3AED), (v) {
          setState(() {
            _needPackingMaterials = v;
            _syncBudgetWithCalculation('moving');
          });
        }),
      ],
    );
  }

  // 5. Assembly Section
  Widget _buildAssemblySpecializedSection() {
    final assemblyTypes = [
      {'id': 'furniture_desk', 'label': 'Desks & Chairs', 'sub': 'Office & study', 'price': 350, 'icon': Icons.chair_outlined},
      {'id': 'furniture_bed', 'label': 'Bed & Wardrobe', 'sub': 'Bedroom units', 'price': 600, 'icon': Icons.bed_outlined},
      {'id': 'table_dining', 'label': 'Dining & Shelves', 'sub': 'Living room', 'price': 450, 'icon': Icons.table_restaurant_outlined},
      {'id': 'fitness_gym', 'label': 'Gym Equipment', 'sub': 'Treadmill/bench', 'price': 800, 'icon': Icons.fitness_center_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Item to Assemble'),
        _buildGridSelector(assemblyTypes, _selectedAssemblyType, const Color(0xFFEA580C), const Color(0xFFFFF7ED), (id) {
          setState(() {
            _selectedAssemblyType = id;
            _syncBudgetWithCalculation('assembly');
          });
        }),
        const SizedBox(height: 14),

        _buildCheckboxRow('Assembly manual / instructions available (-100 ETB discount)', _hasAssemblyManual, const Color(0xFFEA580C), (v) {
          setState(() {
            _hasAssemblyManual = v;
            _syncBudgetWithCalculation('assembly');
          });
        }),
        _buildCheckboxRow('Tasker brings power drill & tool kit (+50 ETB)', _taskerBringsTools, const Color(0xFFEA580C), (v) {
          setState(() {
            _taskerBringsTools = v;
            _syncBudgetWithCalculation('assembly');
          });
        }),
        _buildCheckboxRow('Cardboard & packaging disposal needed (+100 ETB)', _needBoxDisposal, const Color(0xFFEA580C), (v) {
          setState(() {
            _needBoxDisposal = v;
            _syncBudgetWithCalculation('assembly');
          });
        }),
      ],
    );
  }

  // 6. Technology Section
  Widget _buildTechSpecializedSection() {
    final devices = [
      {'id': 'pc_laptop', 'label': 'PC / Laptop', 'sub': 'Mac & Windows', 'price': 400, 'icon': Icons.laptop_chromebook_outlined},
      {'id': 'wifi_network', 'label': 'Wi-Fi & Router', 'sub': 'Internet & Lan', 'price': 350, 'icon': Icons.wifi_rounded},
      {'id': 'printer_periph', 'label': 'Printer / Scanner', 'sub': 'Drivers & setup', 'price': 300, 'icon': Icons.print_outlined},
      {'id': 'smart_tv', 'label': 'Smart TV & Audio', 'sub': 'Mounting & apps', 'price': 350, 'icon': Icons.tv_rounded},
    ];

    final services = [
      {'id': 'hardware_repair', 'label': 'Hardware Repair', 'extra': '+150 ETB', 'icon': Icons.memory_outlined},
      {'id': 'software_os', 'label': 'OS & Software', 'extra': '+50 ETB', 'icon': Icons.code_rounded},
      {'id': 'network_setup', 'label': 'Network Setup', 'extra': '+100 ETB', 'icon': Icons.router_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Device & System'),
        _buildGridSelector(devices, _selectedTechDevice, const Color(0xFF2563EB), const Color(0xFFEFF6FF), (id) {
          setState(() {
            _selectedTechDevice = id;
            _syncBudgetWithCalculation('tech');
          });
        }),
        const SizedBox(height: 14),

        _buildSectionHeader('Service Scope & Technical Hardness'),
        _buildRowSelector(services, _selectedTechService, const Color(0xFF2563EB), const Color(0xFFEFF6FF), (id) {
          setState(() {
            _selectedTechService = id;
            _syncBudgetWithCalculation('tech');
          });
        }),
        const SizedBox(height: 12),

        _buildCheckboxRow('Urgent / Immediate IT fix needed (+150 ETB)', _isUrgentTech, const Color(0xFF2563EB), (v) {
          setState(() {
            _isUrgentTech = v;
            _syncBudgetWithCalculation('tech');
          });
        }),
      ],
    );
  }

  // 7. Plumbing Section
  Widget _buildPlumbingSpecializedSection() {
    final issues = [
      {'id': 'leak', 'label': 'Pipe Leak / Drip', 'sub': 'Sink & bathroom', 'price': 400, 'icon': Icons.water_drop_outlined},
      {'id': 'clogged_drain', 'label': 'Clogged Drain', 'sub': 'Toilet & sewer', 'price': 500, 'icon': Icons.plumbing_outlined},
      {'id': 'fixture_install', 'label': 'Faucet & Shower', 'sub': 'Install/replace', 'price': 600, 'icon': Icons.shower_outlined},
      {'id': 'tank_heater', 'label': 'Water Tank / Heater', 'sub': 'Boiler & pump', 'price': 1000, 'icon': Icons.propane_tank_outlined},
    ];

    final urgencyLevels = [
      {'id': 'urgent', 'label': 'Urgent / Active Leak', 'extra': '+150 ETB', 'icon': Icons.flash_on_rounded},
      {'id': 'standard', 'label': 'Standard Schedule', 'extra': '+0 ETB', 'icon': Icons.calendar_today_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Plumbing Problem'),
        _buildGridSelector(issues, _selectedPlumbingIssue, const Color(0xFF0D9488), const Color(0xFFF0FDFA), (id) {
          setState(() {
            _selectedPlumbingIssue = id;
            _syncBudgetWithCalculation('plumbing');
          });
        }),
        const SizedBox(height: 14),

        _buildSectionHeader('Urgency Level'),
        _buildRowSelector(urgencyLevels, _selectedPlumbingUrgency, const Color(0xFF0D9488), const Color(0xFFF0FDFA), (id) {
          setState(() {
            _selectedPlumbingUrgency = id;
            _syncBudgetWithCalculation('plumbing');
          });
        }),
        const SizedBox(height: 14),

        _buildCheckboxRow('Replacement parts already on site (Save +100 ETB)', _partsProvided, const Color(0xFF0D9488), (v) {
          setState(() {
            _partsProvided = v;
            _syncBudgetWithCalculation('plumbing');
          });
        }),
      ],
    );
  }

  // 8. Electrical Section
  Widget _buildElectricalSpecializedSection() {
    final jobs = [
      {'id': 'short_circuit', 'label': 'Short Circuit', 'sub': 'Tripped breaker', 'price': 450, 'icon': Icons.bolt_rounded},
      {'id': 'lighting', 'label': 'Lighting & Lamps', 'sub': 'Chandelier & LED', 'price': 350, 'icon': Icons.lightbulb_outline_rounded},
      {'id': 'sockets', 'label': 'Sockets & Switches', 'sub': 'Wall plugs', 'price': 300, 'icon': Icons.power_outlined},
      {'id': 'generator', 'label': 'Generator / Inverter', 'sub': 'Backup power', 'price': 800, 'icon': Icons.electric_meter_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Electrical Job'),
        _buildGridSelector(jobs, _selectedElectricalJob, const Color(0xFFB45309), const Color(0xFFFFFBEB), (id) {
          setState(() {
            _selectedElectricalJob = id;
            _syncBudgetWithCalculation('electrical');
          });
        }),
        const SizedBox(height: 14),

        _buildCheckboxRow('Main electrical panel / breaker is accessible (Save +100 ETB)', _breakerAccessible, const Color(0xFFB45309), (v) {
          setState(() {
            _breakerAccessible = v;
            _syncBudgetWithCalculation('electrical');
          });
        }),
        _buildCheckboxRow('Tasker needs to bring tall ladder (+100 ETB)', _needLadder, const Color(0xFFB45309), (v) {
          setState(() {
            _needLadder = v;
            _syncBudgetWithCalculation('electrical');
          });
        }),
      ],
    );
  }

  // 9. Handyman Section
  Widget _buildHandymanSpecializedSection() {
    final handymanJobs = [
      {'id': 'tv_mount', 'label': 'TV Wall Mount', 'sub': 'Bracket & anchors', 'price': 350, 'icon': Icons.tv_rounded},
      {'id': 'curtains_art', 'label': 'Curtains & Mirrors', 'sub': 'Hanging & drilling', 'price': 300, 'icon': Icons.crop_portrait_outlined},
      {'id': 'doors_locks', 'label': 'Doors & Locks', 'sub': 'Hinges & handles', 'price': 400, 'icon': Icons.lock_outline_rounded},
      {'id': 'wall_repairs', 'label': 'Wall Patch & Paint', 'sub': 'Holes & drywall', 'price': 500, 'icon': Icons.format_paint_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Handyman Task Type'),
        _buildGridSelector(handymanJobs, _selectedHandymanType, const Color(0xFF475569), const Color(0xFFF8FAFC), (id) {
          setState(() {
            _selectedHandymanType = id;
            _syncBudgetWithCalculation('handyman');
          });
        }),
        const SizedBox(height: 14),

        _buildCheckboxRow('Mounting screws & hardware available (Save +100 ETB)', _hasBracketsAndScrews, const Color(0xFF475569), (v) {
          setState(() {
            _hasBracketsAndScrews = v;
            _syncBudgetWithCalculation('handyman');
          });
        }),
        _buildCheckboxRow('Tasker brings heavy drill & tall ladder (+100 ETB)', _ladderRequired, const Color(0xFF475569), (v) {
          setState(() {
            _ladderRequired = v;
            _syncBudgetWithCalculation('handyman');
          });
        }),
      ],
    );
  }

  // 10. Other Category
  Widget _buildOtherSpecializedSection() {
    final customTags = [
      'Refrigerator & appliance repair',
      'AC & cooling maintenance',
      'Pet care & dog walking',
      'Event helper & setup',
      'Gardening & yard work',
      'Document typing & printing',
      'Photography & video',
      'Fitness trainer / coach',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Popular Custom Services'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final tag in customTags)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _titleController.text = tag;
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _titleController.text == tag ? const Color(0xFFEEF2FF) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _titleController.text == tag ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                          width: _titleController.text == tag ? 1.4 : 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _titleController.text == tag ? const Color(0xFF6366F1) : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildSectionHeader('Custom Scope & Equipment'),
        _buildCheckboxRow('Tasker brings own equipment / materials (+100 ETB)', _taskerBringsTools, const Color(0xFF6366F1), (v) {
          setState(() {
            _taskerBringsTools = v;
            _syncBudgetWithCalculation('other');
          });
        }),
      ],
    );
  }

  // Safe UI Helper Builders (Zero layout overflow)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildGridSelector(List<Map<String, dynamic>> items, String selectedId, Color primaryColor, Color bgColor, Function(String) onSelect) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedId == item['id'];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(item['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? bgColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
                width: isSelected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withOpacity(0.15) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item['icon'] as IconData, size: 18, color: isSelected ? primaryColor : AppColors.textDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: isSelected ? primaryColor : AppColors.textDark,
                        ),
                      ),
                      if (item['price'] != null)
                        Text(
                          '${item['price']} ETB',
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? primaryColor : const Color(0xFF087F5B),
                          ),
                        )
                      else if (item['sub'] != null)
                        Text(
                          item['sub'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMedium.copyWith(fontSize: 9.5, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRowSelector(List<Map<String, dynamic>> items, String selectedId, Color primaryColor, Color bgColor, Function(String) onSelect) {
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelect(item['id'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: selectedId == item['id'] ? bgColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedId == item['id'] ? primaryColor : const Color(0xFFE5E7EB),
                      width: selectedId == item['id'] ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(item['icon'] as IconData, size: 18, color: selectedId == item['id'] ? primaryColor : AppColors.textMuted),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selectedId == item['id'] ? primaryColor : AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (item['extra'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item['extra'] as String,
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: selectedId == item['id'] ? primaryColor : AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckboxRow(String label, bool value, Color activeColor, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              activeColor: activeColor,
              onChanged: (v) => onChanged(v ?? false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Location & Route with Real-Time Distance & Fare Calculation (Zero Yellow Overflows)
  Widget _buildStep3Location(TaskProvider taskProvider) {
    final cat = taskProvider.wizardCategory.toLowerCase();
    final isRouteBased = cat == 'delivery' || cat == 'moving' || cat == 'shopping';

    final addisNeighborhoods = [
      'Bole Medhanialem',
      'Kazanchis',
      'Sarbet',
      'Piassa',
      'CMC / Ayat',
      'Meskel Square',
      'Megenagna',
      'Old Airport',
      'Gotera / Kera',
      'Gerji',
      '4 Kilo',
      'Mexico',
      'Tor Hailoch',
      '22 Mazoria',
      'Summit',
      'Lebu / Jomo',
    ];

    final pricing = _calculateDetailedPricing(cat);
    final total = pricing['total'] as int;
    final extraDistanceKm = math.max(0.0, _routeDistanceKm - 3.0);
    final distanceRatePerKm = cat == 'moving' ? 60 : (cat == 'shopping' ? 15 : 20);
    final distanceExtraFee = (extraDistanceKm * distanceRatePerKm).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRouteBased ? 'Location & Distance Fare' : 'Service Location',
          style: AppTypography.displayLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isRouteBased
              ? 'Select pickup and drop-off places to calculate distance and price.'
              : 'Enter the exact location where work will be performed.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 14),

        // Remote Switcher Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isRemoteTask ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isRemoteTask ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
              width: _isRemoteTask ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isRemoteTask ? Icons.laptop_mac_rounded : Icons.location_on_outlined,
                size: 20,
                color: _isRemoteTask ? const Color(0xFF6366F1) : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Online / Remote task (No physical address needed)',
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 11.5,
                    fontWeight: _isRemoteTask ? FontWeight.w700 : FontWeight.w500,
                    color: _isRemoteTask ? const Color(0xFF4338CA) : AppColors.textDark,
                  ),
                ),
              ),
              Switch(
                value: _isRemoteTask,
                activeColor: const Color(0xFF6366F1),
                onChanged: (val) {
                  setState(() {
                    _isRemoteTask = val;
                    _syncBudgetWithCalculation(cat);
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_isRemoteTask) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_done_outlined, size: 40, color: Color(0xFF6366F1)),
                const SizedBox(height: 10),
                Text(
                  'Remote Service Mode Active',
                  style: AppTypography.titleSmall.copyWith(
                    color: const Color(0xFF3730A3),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Taskers from across Addis Ababa can collaborate and complete this request digitally.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: const Color(0xFF4F46E5),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Interactive Map Header with Full Screen Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.map_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Real-Time Live Map',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _pickLocationOnMap(isDropoff: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fullscreen_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Open Full Screen Map 📍',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Real-Time Map Preview with Live Distance Pill
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  child: SimulatedMapWidget(
                    onFullScreenTap: () => _pickLocationOnMap(isDropoff: false),
                    pins: [
                      MapTaskPin(
                        id: 'loc_pickup',
                        title: isRouteBased ? 'Pickup' : 'Service',
                        price: 'Origin',
                        relativePosition: const Offset(0.35, 0.45),
                        location: _pickupController.text.isNotEmpty ? _pickupController.text : 'Bole',
                      ),
                      if (isRouteBased)
                        MapTaskPin(
                          id: 'loc_dropoff',
                          title: 'Drop-off',
                          price: 'Dest',
                          relativePosition: const Offset(0.68, 0.55),
                          location: _dropoffController.text.isNotEmpty ? _dropoffController.text : 'Sarbet',
                        ),
                    ],
                  ),
                ),
                if (isRouteBased)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.route_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${_routeDistanceKm.toStringAsFixed(1)} km · ~${(_routeDistanceKm * 3.5).round()} mins',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic Route Distance & Surcharge Price Card (Zero Overflow)
          if (isRouteBased) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.timeline_rounded, size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'DISTANCE & FARE CALCULATION',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                  color: const Color(0xFF15803D),
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+$distanceRatePerKm ETB / extra km',
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Route: ${_routeDistanceKm.toStringAsFixed(1)} km',
                              style: AppTypography.titleSmall.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF14532D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              extraDistanceKm > 0
                                  ? '3.0 km included · +${extraDistanceKm.toStringAsFixed(1)} km (+$distanceExtraFee ETB)'
                                  : 'Within base 3.0 km radius (0 extra)',
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 11.5,
                                color: const Color(0xFF166534),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$total ETB',
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF15803D)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'System Road Route: ${_routeDistanceKm.toStringAsFixed(1)} km (Auto-calculated)',
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF14532D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_routeDistanceKm.toStringAsFixed(1)} km',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 1. Quick Pickup Places Picker
          Row(
            children: [
              const Icon(Icons.trip_origin_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '1-Tap Pickup Places (Origin)',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final hood in addisNeighborhoods)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _pickupController.text = '$hood, Addis Ababa';
                          _routeDistanceKm = _estimateDistanceBetween(_pickupController.text, _dropoffController.text);
                          _syncBudgetWithCalculation(cat);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _pickupController.text.contains(hood) ? AppColors.primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _pickupController.text.contains(hood) ? AppColors.primary : const Color(0xFFE5E7EB),
                            width: _pickupController.text.contains(hood) ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          hood,
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _pickupController.text.contains(hood) ? AppColors.primaryDark : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Quick Drop-off Places Picker (For route tasks)
          if (isRouteBased) ...[
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Text(
                  '1-Tap Drop-off Places (Destination)',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final hood in addisNeighborhoods)
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            _dropoffController.text = '$hood, Addis Ababa';
                            _routeDistanceKm = _estimateDistanceBetween(_pickupController.text, _dropoffController.text);
                            _syncBudgetWithCalculation(cat);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _dropoffController.text.contains(hood) ? const Color(0xFFFEE2E2) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _dropoffController.text.contains(hood) ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                              width: _dropoffController.text.contains(hood) ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            hood,
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _dropoffController.text.contains(hood) ? const Color(0xFFB91C1C) : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Pickup Location Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.trip_origin_rounded, size: 14, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRouteBased ? 'Pickup Location / Origin' : 'Service Location',
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 10.5,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextField(
                            controller: _pickupController,
                            style: AppTypography.titleSmall.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                            onChanged: (val) {
                              setState(() {
                                _routeDistanceKm = _estimateDistanceBetween(val, _dropoffController.text);
                                _syncBudgetWithCalculation(cat);
                              });
                            },
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.only(top: 2),
                              border: InputBorder.none,
                              hintText: 'Enter street, building, or area name',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pick on Map Button
                        InkWell(
                          onTap: () => _pickLocationOnMap(isDropoff: false),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.map_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Pick on Map',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primaryDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Current Location Icon Button
                        IconButton(
                          tooltip: 'Use My Real Location',
                          icon: const Icon(Icons.my_location_rounded, size: 18, color: AppColors.primary),
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Detecting real device GPS location...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            final realPos = await LocationService().getCurrentDeviceLocation();
                            if (realPos != null) {
                              final realAddr = await LocationService().reverseGeocode(realPos);
                              setState(() {
                                _pickupController.text = realAddr;
                                _routeDistanceKm = _estimateDistanceBetween(_pickupController.text, _dropoffController.text);
                                _syncBudgetWithCalculation(cat);
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Detected: $realAddr')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 14, color: Color(0xFFF3F4F6)),
                TextField(
                  controller: _pickupUnitController,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Apartment, house number or landmark notes (optional)',
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),

          if (isRouteBased) ...[
            const SizedBox(height: 10),
            // Drop-off Location Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Drop-off / Destination Address',
                              style: AppTypography.labelMedium.copyWith(
                                fontSize: 10.5,
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextField(
                              controller: _dropoffController,
                              style: AppTypography.titleSmall.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
                              onChanged: (val) {
                                setState(() {
                                  _routeDistanceKm = _estimateDistanceBetween(_pickupController.text, val);
                                  _syncBudgetWithCalculation(cat);
                                });
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.only(top: 2),
                                border: InputBorder.none,
                                hintText: 'Enter drop-off destination address',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Drop-off Pick on Map Button
                      InkWell(
                        onTap: () => _pickLocationOnMap(isDropoff: true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map_rounded, size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                              Text(
                                'Pick on Map',
                                style: AppTypography.labelMedium.copyWith(
                                  color: const Color(0xFFB91C1C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14, color: Color(0xFFF3F4F6)),
                  TextField(
                    controller: _dropoffUnitController,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Drop-off floor, gate code, or reception desk note (optional)',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  // STEP 4: Schedule with Dynamic Urgency Pricing & Rich Time Windows
  Widget _buildStep4Schedule(TaskProvider taskProvider) {
    final cat = taskProvider.wizardCategory.toLowerCase();
    final pricing = _calculateDetailedPricing(cat);
    final total = pricing['total'] as int;

    final scheduleOptions = [
      {
        'id': 'asap',
        'title': 'ASAP · Express Urgent Dispatch',
        'sub': 'Tasker dispatched immediately · Arrival < 60 mins',
        'extra': '+150 ETB Urgency',
        'priceNote': '+150 ETB',
        'isExpress': true,
        'badgeColor': const Color(0xFFF59E0B),
        'icon': Icons.bolt_rounded,
      },
      {
        'id': 'today',
        'title': 'Today · Afternoon / Evening',
        'sub': 'Today · Flexible daytime arrival (2:00 PM - 7:00 PM)',
        'extra': '+50 ETB Same-Day',
        'priceNote': '+50 ETB',
        'isExpress': false,
        'badgeColor': const Color(0xFF0284C7),
        'icon': Icons.today_rounded,
      },
      {
        'id': 'tomorrow',
        'title': 'Tomorrow · Morning Window',
        'sub': 'Tomorrow · Reserved morning slot (9:00 AM - 1:00 PM)',
        'extra': 'Standard (0 Extra)',
        'priceNote': '0 ETB',
        'isExpress': false,
        'badgeColor': const Color(0xFF16A34A),
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'id': 'scheduled',
        'title': 'Custom Date & Specific Time Window',
        'sub': 'Select custom calendar day and preferred arrival hour',
        'extra': 'Custom (0 Extra)',
        'priceNote': '0 ETB',
        'isExpress': false,
        'badgeColor': const Color(0xFF6366F1),
        'icon': Icons.calendar_month_outlined,
      },
    ];

    final timeSlots = [
      {'id': 'morning', 'label': 'Morning', 'time': '8:00 AM - 12:00 PM', 'extra': '0 ETB', 'icon': Icons.wb_twilight_rounded},
      {'id': 'afternoon', 'label': 'Afternoon', 'time': '12:00 PM - 5:00 PM', 'extra': '0 ETB', 'icon': Icons.wb_sunny_rounded},
      {'id': 'evening', 'label': 'Evening', 'time': '5:00 PM - 9:00 PM', 'extra': '0 ETB', 'icon': Icons.nightlight_round},
      {'id': 'night', 'label': 'Night Shift', 'time': '9:00 PM+ (Emergency)', 'extra': '+100 ETB', 'icon': Icons.bedtime_outlined},
    ];

    final dayPresets = [
      {'id': 'today', 'label': 'Today'},
      {'id': 'tomorrow', 'label': 'Tomorrow'},
      {'id': 'in_2_days', 'label': 'In 2 Days'},
      {'id': 'weekend', 'label': 'This Weekend'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule & Urgency',
          style: AppTypography.displayLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Choose your preferred arrival window. Express dispatch is prioritized.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 14),

        // Live Urgency & Fare Breakdown Banner (Zero Overflow)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F44), Color(0xFF087F5B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF087F5B).withOpacity(0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_outlined, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED TASK FARE',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      taskProvider.wizardScheduleType == 'asap'
                          ? 'ASAP Express Priority Dispatch (+150 ETB)'
                          : (taskProvider.wizardScheduleType == 'today'
                              ? 'Same-Day Afternoon Window (+50 ETB)'
                              : (_selectedTimeOfDay == 'night' ? 'Night Shift (+100 ETB)' : 'Standard Booking (0 Extra)')),
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$total ETB',
                  style: AppTypography.titleSmall.copyWith(
                    color: const Color(0xFF087F5B),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Rich Schedule Option Cards
        for (final opt in scheduleOptions) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  taskProvider.wizardScheduleType = opt['id'] as String;
                  taskProvider.wizardScheduleText = opt['sub'] as String;
                  _syncBudgetWithCalculation(cat);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: taskProvider.wizardScheduleType == opt['id'] ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: taskProvider.wizardScheduleType == opt['id']
                        ? AppColors.primary
                        : const Color(0xFFE5E7EB),
                    width: taskProvider.wizardScheduleType == opt['id'] ? 2 : 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: taskProvider.wizardScheduleType == opt['id']
                          ? AppColors.primary.withOpacity(0.08)
                          : Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: taskProvider.wizardScheduleType == opt['id']
                            ? AppColors.primary.withOpacity(0.15)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        opt['icon'] as IconData,
                        size: 22,
                        color: taskProvider.wizardScheduleType == opt['id']
                            ? AppColors.primary
                            : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  opt['title'] as String,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: taskProvider.wizardScheduleType == opt['id']
                                        ? AppColors.primaryDark
                                        : AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (opt['badgeColor'] as Color).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: (opt['badgeColor'] as Color).withOpacity(0.3)),
                                ),
                                child: Text(
                                  opt['extra'] as String,
                                  style: AppTypography.labelMedium.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: opt['badgeColor'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt['sub'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Radio<String>(
                      value: opt['id'] as String,
                      groupValue: taskProvider.wizardScheduleType,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          taskProvider.wizardScheduleType = val!;
                          taskProvider.wizardScheduleText = opt['sub'] as String;
                          _syncBudgetWithCalculation(cat);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Day Presets & Time Slot Windows for Custom or Today schedule
        if (taskProvider.wizardScheduleType == 'scheduled' || taskProvider.wizardScheduleType == 'today') ...[
          const SizedBox(height: 8),
          Text(
            'Select Target Day',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final day in dayPresets)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedScheduleDatePreset = day['id'] as String;
                          taskProvider.wizardScheduleText = '${day['label']} · $_selectedTimeOfDay';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: _selectedScheduleDatePreset == day['id'] ? const Color(0xFF087F5B) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedScheduleDatePreset == day['id'] ? const Color(0xFF087F5B) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          day['label'] as String,
                          style: AppTypography.labelMedium.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedScheduleDatePreset == day['id'] ? Colors.white : AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            'Select Preferred Time Window',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final slot in timeSlots)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedTimeOfDay = slot['id'] as String;
                          _syncBudgetWithCalculation(cat);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: _selectedTimeOfDay == slot['id'] ? const Color(0xFFF0FDF4) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedTimeOfDay == slot['id'] ? AppColors.primary : const Color(0xFFE5E7EB),
                            width: _selectedTimeOfDay == slot['id'] ? 1.8 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              slot['icon'] as IconData,
                              size: 16,
                              color: _selectedTimeOfDay == slot['id'] ? AppColors.primary : AppColors.textMuted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slot['label'] as String,
                              style: AppTypography.labelMedium.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _selectedTimeOfDay == slot['id'] ? AppColors.primaryDark : AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              slot['extra'] as String,
                              style: AppTypography.labelMedium.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: _selectedTimeOfDay == slot['id'] ? AppColors.primary : AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Trust & Punctuality Guarantee Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF16A34A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '100% Punctuality Guarantee · Tasker ETA tracked live in chat',
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 11.5,
                    color: const Color(0xFF15803D),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 5: Set Your Budget with Live Breakdown & Escrow Agreement
  Widget _buildStep5Budget(TaskProvider taskProvider) {
    final cat = taskProvider.wizardCategory.toLowerCase();
    final pricing = _calculateDetailedPricing(cat);
    final calculatedBase = pricing['basePrice'] as int;
    final calculatedTotal = pricing['total'] as int;
    final modifiers = pricing['modifiers'] as List<Map<String, dynamic>>;

    final currentBudget = int.tryParse(_budgetController.text) ?? calculatedTotal;

    final smartPresets = [
      {
        'label': 'Budget',
        'sub': '-15%',
        'amount': (calculatedTotal * 0.85).round(),
        'badge': 'Saver',
        'badgeColor': const Color(0xFF64748B),
      },
      {
        'label': 'Recommended',
        'sub': 'Market',
        'amount': calculatedTotal,
        'badge': 'Optimal',
        'badgeColor': const Color(0xFF16A34A),
      },
      {
        'label': 'Fast Match',
        'sub': '+15%',
        'amount': (calculatedTotal * 1.15).round(),
        'badge': 'Popular',
        'badgeColor': const Color(0xFF0284C7),
      },
      {
        'label': 'Priority',
        'sub': '+30%',
        'amount': (calculatedTotal * 1.30).round(),
        'badge': 'Express',
        'badgeColor': const Color(0xFFF59E0B),
      },
    ];

    final pricingModels = [
      {
        'id': 'fixed',
        'title': 'Fixed Price',
        'sub': 'Set guaranteed total price',
        'badge': 'Recommended',
        'icon': Icons.lock_outline_rounded,
      },
      {
        'id': 'negotiable',
        'title': 'Open to Offers',
        'sub': 'Taskers submit custom bids',
        'badge': 'Flexible',
        'icon': Icons.gavel_outlined,
      },
      {
        'id': 'hourly',
        'title': 'Hourly Rate',
        'sub': 'Pay by tracked session time',
        'badge': 'Time-Based',
        'icon': Icons.access_time_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Your Budget',
          style: AppTypography.displayLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Fair pricing attracts top-rated taskers and guarantees faster acceptance.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 14),

        // Hero Fare & Dynamic Breakdown Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F44), Color(0xFF087F5B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF087F5B).withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'RECOMMENDED MARKET RATE',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cat.toUpperCase(),
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$currentBudget',
                          style: AppTypography.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ETB',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Includes base scope rate, distance route surcharge & selected urgency tier',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Breakdown Toggle Header
              InkWell(
                onTap: () => setState(() => _showFareBreakdown = !_showFareBreakdown),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _showFareBreakdown ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showFareBreakdown ? 'Hide Itemized Fare Breakdown' : 'View Itemized Fare Breakdown (${modifiers.length + 1} items)',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _showFareBreakdown ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable Itemized Price Breakdown Table
              if (_showFareBreakdown)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                  ),
                  child: Column(
                    children: [
                      // Base Rate
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pricing['baseLabel'] as String,
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$calculatedBase ETB',
                            style: AppTypography.labelMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Modifiers
                      for (final m in modifiers) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                m['label'] as String,
                                style: AppTypography.bodyMedium.copyWith(fontSize: 11.5, color: const Color(0xFF047857)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${m['amount']} ETB',
                              style: AppTypography.labelMedium.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Platform fee
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Finish Protection & Escrow Coverage',
                              style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '0 ETB (Included)',
                            style: AppTypography.labelMedium.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: Color(0xFFE5E7EB)),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Calculated Fair Total',
                            style: AppTypography.titleSmall.copyWith(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                          Text(
                            '$calculatedTotal ETB',
                            style: AppTypography.titleSmall.copyWith(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF087F5B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Smart Tier Presets
        Text(
          'Quick Pricing Presets',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final p in smartPresets)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _budgetController.text = p['amount'].toString();
                        taskProvider.wizardBudget = p['amount'] as int;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: _budgetController.text == p['amount'].toString()
                            ? const Color(0xFFF0FDF4)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _budgetController.text == p['amount'].toString()
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                          width: _budgetController.text == p['amount'].toString() ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: (p['badgeColor'] as Color).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p['badge'] as String,
                              style: AppTypography.labelMedium.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: p['badgeColor'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p['amount']} ETB',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: _budgetController.text == p['amount'].toString()
                                  ? AppColors.primary
                                  : AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            p['sub'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 9.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Custom Budget Input Field with Quick Increments
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Target Budget (ETB)',
                style: AppTypography.labelMedium.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ETB',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Enter custom budget',
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) {
                          taskProvider.wizardBudget = parsed;
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      final val = (int.tryParse(_budgetController.text) ?? calculatedTotal);
                      if (val > 50) {
                        final updated = val - 50;
                        setState(() {
                          _budgetController.text = updated.toString();
                          taskProvider.wizardBudget = updated;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-50',
                        style: AppTypography.labelMedium.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      final val = (int.tryParse(_budgetController.text) ?? calculatedTotal);
                      final updated = val + 50;
                      setState(() {
                        _budgetController.text = updated.toString();
                        taskProvider.wizardBudget = updated;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+50',
                        style: AppTypography.labelMedium.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3 Rich Pricing Models (Fixed, Offers, Hourly)
        Text(
          'Payment Agreement Term',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        for (final m in pricingModels) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => taskProvider.wizardPricingType = m['id'] as String),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: taskProvider.wizardPricingType == m['id'] ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: taskProvider.wizardPricingType == m['id'] ? AppColors.primary : const Color(0xFFE5E7EB),
                    width: taskProvider.wizardPricingType == m['id'] ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: taskProvider.wizardPricingType == m['id'] ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        m['icon'] as IconData,
                        size: 18,
                        color: taskProvider.wizardPricingType == m['id'] ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                m['title'] as String,
                                style: AppTypography.titleSmall.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: taskProvider.wizardPricingType == m['id'] ? AppColors.primaryDark : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: taskProvider.wizardPricingType == m['id'] ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m['badge'] as String,
                                  style: AppTypography.labelMedium.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: taskProvider.wizardPricingType == m['id'] ? const Color(0xFF15803D) : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            m['sub'] as String,
                            style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: m['id'] as String,
                      groupValue: taskProvider.wizardPricingType,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => taskProvider.wizardPricingType = v!),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),

        // Finish Escrow & Customer Protection Trust Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF16A34A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Finish Escrow Protected · Payment only released after your approval',
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 11,
                    color: const Color(0xFF15803D),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 6: Review & Final Confirmation
  Widget _buildStep6Review(TaskProvider taskProvider) {
    final cat = taskProvider.wizardCategory.toLowerCase();
    final isRouteBased = cat == 'delivery' || cat == 'moving' || cat == 'shopping';
    final pricing = _calculateDetailedPricing(cat);
    final calculatedTotal = pricing['total'] as int;
    final currentBudget = int.tryParse(_budgetController.text) ?? calculatedTotal;

    // Collect category specific review points
    final specItems = <Map<String, String>>[];
    if (cat == 'delivery') {
      specItems.add({'label': 'Package Type', 'value': _selectedPackageType.toUpperCase()});
      specItems.add({'label': 'Vehicle', 'value': _selectedVehicleType.toUpperCase()});
      if (_isFragile) specItems.add({'label': 'Handling', 'value': 'Fragile & Sensitive'});
      if (_recipientNameController.text.isNotEmpty) {
        specItems.add({'label': 'Recipient', 'value': '${_recipientNameController.text} (${_recipientPhoneController.text})'});
      }
      specItems.add({'label': 'Handover Proof', 'value': _requirePhotoProof ? 'Photo Required' : 'Standard'});
    } else if (cat == 'cleaning') {
      specItems.add({'label': 'Property Size', 'value': _selectedCleaningSpace.replaceAll('_', ' ').toUpperCase()});
      specItems.add({'label': 'Clean Depth', 'value': _selectedCleaningType.toUpperCase()});
      if (_selectedCleaningAddons.contains('sofa')) {
        specItems.add({'label': 'Sofa Wash', 'value': _selectedSofaType.replaceAll('_', ' ').toUpperCase()});
      }
      if (_selectedCleaningAddons.contains('carpet')) {
        specItems.add({'label': 'Carpet Wash', 'value': _selectedCarpetType.replaceAll('_', ' ').toUpperCase()});
      }
      if (_includeMattressWash) specItems.add({'label': 'Mattress Steam', 'value': 'Included'});
      if (_includeCurtainSteam) specItems.add({'label': 'Curtains Steam', 'value': 'Included'});
      if (_includeWindowsGlass) specItems.add({'label': 'Glass Polish', 'value': 'Included'});
      specItems.add({'label': 'Supplies', 'value': _selectedSupplyOption == 'tasker_supplies' ? 'Tasker Brings' : 'Customer Has'});
    } else if (cat == 'shopping') {
      specItems.add({'label': 'Shopping Scope', 'value': _selectedShoppingType.toUpperCase()});
      specItems.add({'label': 'Target Store', 'value': _selectedStorePreference.replaceAll('_', ' ').toUpperCase()});
      specItems.add({'label': 'Items to Buy', 'value': '${_shoppingItems.length} items (${_shoppingItems.map((e) => e['name']).take(3).join(', ')})'});
      if (_estimatedGoodsCostController.text.isNotEmpty) {
        specItems.add({'label': 'Goods Budget', 'value': '${_estimatedGoodsCostController.text} ETB'});
      }
      specItems.add({'label': 'Receipt', 'value': _requireItemizedReceipt ? 'Receipt Required' : 'Optional'});
    } else if (cat == 'moving') {
      specItems.add({'label': 'Move Size', 'value': _selectedMoveSize.replaceAll('_', ' ').toUpperCase()});
      specItems.add({'label': 'Floor & Access', 'value': 'Floor $_selectedFloorLevel · ${_hasElevator ? "Elevator" : "Stairs"}'});
      specItems.add({'label': 'Helpers', 'value': _needHelpers ? 'Helper Requested' : 'Driver Only'});
      specItems.add({'label': 'Packing Kit', 'value': _needPackingMaterials ? 'Materials Needed' : 'Pre-Packed'});
    } else if (cat == 'assembly') {
      specItems.add({'label': 'Item to Assemble', 'value': _selectedAssemblyType.replaceAll('_', ' ').toUpperCase()});
      specItems.add({'label': 'Manual', 'value': _hasAssemblyManual ? 'Manual Available' : 'No Manual'});
      specItems.add({'label': 'Tools', 'value': _taskerBringsTools ? 'Tasker Brings Tools' : 'Customer Has Tools'});
    } else if (cat == 'tech') {
      specItems.add({'label': 'Device', 'value': _selectedTechDevice.toUpperCase()});
      specItems.add({'label': 'Service Need', 'value': _selectedTechService.replaceAll('_', ' ').toUpperCase()});
      if (_isUrgentTech) specItems.add({'label': 'Urgency', 'value': 'Urgent IT Fix'});
    } else if (cat == 'plumbing') {
      specItems.add({'label': 'Plumbing Issue', 'value': _selectedPlumbingIssue.replaceAll('_', ' ').toUpperCase()});
      specItems.add({'label': 'Urgency Level', 'value': _selectedPlumbingUrgency.toUpperCase()});
      specItems.add({'label': 'Parts', 'value': _partsProvided ? 'Parts on Site' : 'Tasker Sources Parts'});
    } else if (cat == 'electrical') {
      specItems.add({'label': 'Electrical Job', 'value': _selectedElectricalJob.replaceAll('_', ' ').toUpperCase()});
      specItems.add({'label': 'Panel Access', 'value': _breakerAccessible ? 'Panel Accessible' : 'Diagnostics Needed'});
      if (_needLadder) specItems.add({'label': 'Equipment', 'value': 'Tall Ladder Needed'});
    } else if (cat == 'handyman') {
      specItems.add({'label': 'Handyman Task', 'value': _selectedHandymanType.replaceAll('_', ' ').toUpperCase()});
      specItems.add({'label': 'Hardware', 'value': _hasBracketsAndScrews ? 'Hardware Available' : 'Tasker Brings Hardware'});
      if (_ladderRequired) specItems.add({'label': 'Equipment', 'value': 'Tall Ladder Needed'});
    } else {
      specItems.add({'label': 'Scope', 'value': 'Custom Specified Service'});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Confirm',
          style: AppTypography.displayLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Verify all details before publishing to verified taskers.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 14),

        // Hero Overview Card with Live Budget Pill
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F44), Color(0xFF087F5B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF087F5B).withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          cat.toUpperCase(),
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$currentBudget ETB',
                      style: AppTypography.titleSmall.copyWith(
                        color: const Color(0xFF087F5B),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _titleController.text.isNotEmpty ? _titleController.text : 'Custom Task Request',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.route_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _isRemoteTask
                          ? 'Remote / Digital Task'
                          : '${_pickupController.text.split(',').first} → ${_dropoffController.text.split(',').first} (${_routeDistanceKm.toStringAsFixed(1)} km)',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section 1: Task Specifications & Add-ons
        _buildReviewSectionCard(
          title: 'Task Details & Hardness Scope',
          icon: Icons.assignment_outlined,
          onEdit: () => setState(() => _currentStep = 2),
          children: [
            for (final spec in specItems)
              _buildReviewRowItem(spec['label']!, spec['value']!),
            if (_instructionsController.text.isNotEmpty)
              _buildReviewRowItem('Special Note', _instructionsController.text),
          ],
        ),
        const SizedBox(height: 12),

        // Section 2: Location & Route Information
        _buildReviewSectionCard(
          title: 'Location & Route',
          icon: Icons.location_on_outlined,
          onEdit: () => setState(() => _currentStep = 3),
          children: [
            if (_isRemoteTask) ...[
              _buildReviewRowItem('Service Mode', 'Remote / Online Service'),
            ] else ...[
              _buildReviewRowItem(
                isRouteBased ? 'Origin / Pickup' : 'Service Address',
                _pickupController.text,
              ),
              if (_pickupUnitController.text.isNotEmpty)
                _buildReviewRowItem('Pickup Note', _pickupUnitController.text),
              if (isRouteBased) ...[
                _buildReviewRowItem('Destination', _dropoffController.text),
                if (_dropoffUnitController.text.isNotEmpty)
                  _buildReviewRowItem('Drop-off Note', _dropoffUnitController.text),
                _buildReviewRowItem('Road Distance', '${_routeDistanceKm.toStringAsFixed(1)} km (Auto-calculated GPS route)'),
              ],
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Section 3: Schedule & Urgency
        _buildReviewSectionCard(
          title: 'Schedule & Timing',
          icon: Icons.calendar_month_outlined,
          onEdit: () => setState(() => _currentStep = 4),
          children: [
            _buildReviewRowItem(
              'Urgency Tier',
              taskProvider.wizardScheduleType == 'asap'
                  ? '⚡ ASAP Express (< 60 mins dispatch)'
                  : (taskProvider.wizardScheduleType == 'today'
                      ? 'Today Afternoon Window'
                      : (taskProvider.wizardScheduleType == 'tomorrow' ? 'Tomorrow Morning' : 'Custom Scheduled Date')),
            ),
            _buildReviewRowItem('Time Window', taskProvider.wizardScheduleText),
          ],
        ),
        const SizedBox(height: 12),

        // Section 4: Budget & Payment Terms
        _buildReviewSectionCard(
          title: 'Budget & Payment Agreement',
          icon: Icons.payments_outlined,
          onEdit: () => setState(() => _currentStep = 5),
          children: [
            _buildReviewRowItem('Agreed Budget', '$currentBudget ETB'),
            _buildReviewRowItem(
              'Pricing Model',
              taskProvider.wizardPricingType == 'fixed'
                  ? 'Fixed Price (Guaranteed & Escrow-Protected)'
                  : (taskProvider.wizardPricingType == 'negotiable' ? 'Open to Tasker Offers' : 'Hourly Rate Tracked'),
            ),
            _buildReviewRowItem('Platform Fee', '0 ETB (100% Free for Customers)'),
          ],
        ),
        const SizedBox(height: 14),

        // Finish Escrow & Trust Protection Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, size: 18, color: Color(0xFF15803D)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Finish 100% Escrow & Satisfaction Guarantee',
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14532D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '• Your funds are held securely in escrow and only released after you inspect and approve the completed job.\n• Free cancellation before the tasker starts.\n• Live in-app chat & real-time GPS arrival tracking.',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 11.5,
                  color: const Color(0xFF166534),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSectionCard({
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined, size: 12, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        'Edit',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 14, color: Color(0xFFF3F4F6)),
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewRowItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const AnimatedCheckmark(size: 88),
              const SizedBox(height: 24),
              Text(
                'Task Posted!',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nearby verified taskers are being notified in real time.\nYou will receive offers and updates shortly.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, height: 1.4),
              ),
              const Spacer(),
              FinishButton(
                text: 'View My Tasks',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
