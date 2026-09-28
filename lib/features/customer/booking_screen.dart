import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/outlined_button.dart';
import '../../providers/data_providers.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/models.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String id;
  const BookingScreen({super.key, required this.id});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0;

  // Form State
  String? _selectedPackageId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedTimeSlot;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController(text: 'Hà Nội');
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  final List<String> _timeSlots = ['08:00', '09:00', '10:00', '14:00', '15:00', '16:00'];

  String _formatPrice(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  void _next() {
    if (_step == 0) {
      if (_selectedPackageId == null || _selectedTimeSlot == null) {
        if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn gói chụp và khung giờ')));
        return;
      }
    }
    if (_step == 1) {
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
        if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên và số điện thoại')));
        return;
      }
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      if (context.mounted) context.pop();
    }
  }

  Future<void> _submit(Photographer p, User user) async { try {
    final pkg = p.packages.firstWhere((pkg) => pkg.id == _selectedPackageId, orElse: () => p.packages.first);
    
    final newBooking = Booking(
      id: 'b${Random().nextInt(10000)}',
      clientId: user.id,
      clientName: _nameController.text,
      photographerId: p.id,
      photographerName: p.name,
      style: p.styles.isNotEmpty ? p.styles.first : 'Khác',
      date: '${DateFormat('yyyy-MM-dd').format(_selectedDate)} $_selectedTimeSlot',
      location: '${_addressController.text}, ${_cityController.text}',
      price: pkg.price,
    );
    
    
    await ref.read(asyncBookingsProvider.notifier).createBooking(newBooking);
    
    if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gửi yêu cầu đặt lịch thành công!')),
    );
    
    context.go('/customer_home/bookings'); } catch (e, stack) { if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)); print("SUBMIT ERROR: $e"); print(stack); }
  }

  @override
  Widget build(BuildContext context) {
    final photographers = ref.watch(photographersProvider);
    final p = photographers.firstWhere((p) => p.id == widget.id, orElse: () => photographers.first);
    final user = ref.watch(authUserProvider);
    
    // Auto-select first package if none
    if (_selectedPackageId == null && p.packages.isNotEmpty) {
      _selectedPackageId = p.packages.first.id;
    }
    // Auto-fill user info if empty
    if (_nameController.text.isEmpty && user != null) {
      _nameController.text = user.name;
    }

    final selectedPackage = p.packages.firstWhere((pkg) => pkg.id == _selectedPackageId, orElse: () => p.packages.first);
    final totalPrice = selectedPackage.price;

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.snow,
        elevation: 0,
        title: Text(_step == 0 ? 'Gói chụp & Thời gian' : _step == 1 ? 'Thông tin liên hệ' : 'Xác nhận thông tin', style: const TextStyle(color: AppColors.obsidian, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
          onPressed: _back,
        ),
      ),
      body: Column(
        children: [
          // Stepper indicator
          Container(
            color: AppColors.snow,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Thời gian'),
                _buildStepLine(0),
                _buildStepIndicator(1, 'Thông tin'),
                _buildStepLine(1),
                _buildStepIndicator(2, 'Xác nhận'),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _step == 0 
                  ? _buildStep0(p) 
                  : _step == 1 
                      ? _buildStep1() 
                      : _buildStep2(p, selectedPackage),
            ),
          ),
          
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.snow,
              border: Border(top: BorderSide(color: AppColors.pebble)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Tổng tạm tính', style: TextStyle(color: AppColors.steel, fontSize: 12)),
                      Text(_formatPrice(totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.obsidian)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _step < 2
                        ? PrimaryButton(text: 'Tiếp tục', onPressed: _next)
                        : PrimaryButton(text: 'Xác nhận đặt lịch', onPressed: () { if (user == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Chưa đăng nhập"))); return; } _submit(p, user); }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label) {
    final isActive = _step >= stepIndex;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.obsidian : AppColors.snow,
            border: Border.all(color: isActive ? AppColors.obsidian : AppColors.pebble),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${stepIndex + 1}',
            style: TextStyle(color: isActive ? Colors.white : AppColors.steel, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isActive ? AppColors.obsidian : AppColors.steel, fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStepLine(int stepIndex) {
    final isActive = _step > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 14),
        color: isActive ? AppColors.obsidian : AppColors.pebble,
      ),
    );
  }

  Widget _buildStep0(Photographer p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. Chọn gói chụp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.obsidian)),
        const SizedBox(height: 12),
        ...p.packages.map((pkg) {
          final isSelected = _selectedPackageId == pkg.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedPackageId = pkg.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.snow : AppColors.mist,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.obsidian : AppColors.pebble, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(pkg.duration, style: const TextStyle(color: AppColors.steel, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(_formatPrice(pkg.price), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian)),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 32),
        const Text('2. Chọn ngày & khung giờ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.obsidian)),
        const SizedBox(height: 12),
        
        // Calendar Date Picker
        Container(
          decoration: BoxDecoration(
            color: AppColors.snow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.pebble),
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _selectedDate,
            currentDay: DateTime.now(),
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.obsidian,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.pebble,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: AppColors.obsidian),
            ),
            availableGestures: AvailableGestures.horizontalSwipe,
          ),
        ),
        
        const SizedBox(height: 16),
        const Text('Khung giờ trống', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.steel)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _timeSlots.map((time) {
            final isSelected = _selectedTimeSlot == time;
            return GestureDetector(
              onTap: () => setState(() => _selectedTimeSlot = time),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.obsidian : AppColors.snow,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: isSelected ? AppColors.obsidian : AppColors.pebble),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.obsidian,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thông tin người đặt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.obsidian)),
        const SizedBox(height: 24),
        const Text('Họ và tên', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian)),
        const SizedBox(height: 8),
        _buildTextField(_nameController, 'Người liên hệ'),
        const SizedBox(height: 16),
        const Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian)),
        const SizedBox(height: 8),
        _buildTextField(_phoneController, 'VD: 0901234567', isPhone: true),
        const SizedBox(height: 32),
        
        const Text('Địa điểm chụp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.obsidian)),
        const SizedBox(height: 24),
        const Text('Tỉnh / Thành phố', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian)),
        const SizedBox(height: 8),
        _buildTextField(_cityController, 'VD: Hà Nội'),
        const SizedBox(height: 16),
        const Text('Địa chỉ cụ thể (Không bắt buộc)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian)),
        const SizedBox(height: 8),
        _buildTextField(_addressController, 'VD: Studio ABC, Hồ Tây...'),
        const SizedBox(height: 32),
        
        const Text('Ghi chú (Không bắt buộc)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian)),
        const SizedBox(height: 8),
        _buildTextField(_noteController, 'Mô tả ý tưởng, concept...', maxLines: 4),
      ],
    );
  }

  Widget _buildStep2(Photographer p, PhotographerPackage pkg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.snow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.pebble),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundImage: NetworkImage(p.avatar), onBackgroundImageError: (_, __) => {}),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(p.city, style: const TextStyle(color: AppColors.steel, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.pebble),
              ),
              _buildSummaryRow('Gói chụp', pkg.name),
              _buildSummaryRow('Ngày & giờ', '${DateFormat('dd/MM/yyyy').format(_selectedDate)} · $_selectedTimeSlot'),
              _buildSummaryRow('Địa điểm', '${_addressController.text.isNotEmpty ? '${_addressController.text}, ' : ''}${_cityController.text}'),
              _buildSummaryRow('Liên hệ', '${_nameController.text} · ${_phoneController.text}'),
              if (_noteController.text.isNotEmpty) _buildSummaryRow('Ghi chú', _noteController.text),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Lưu ý: Đây là chi phí tạm tính. Nhiếp ảnh gia sẽ liên hệ xác nhận lại các yêu cầu chi tiết của bạn trước khi chốt lịch.',
          style: TextStyle(color: AppColors.steel, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.steel))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.obsidian), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPhone = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.snow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.pebble)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.pebble)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.obsidian)),
      ),
    );
  }
}
