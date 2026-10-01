class BookingSummary {
  const BookingSummary({
    required this.fieldName,
    required this.fieldLocation,
    required this.date,
    required this.time,
    required this.price,
    required this.total,
    required this.status,
    this.id,
    this.code,
    this.courtName,
    this.customerName,
    this.durationHours = 1,
  });

  final int? id;
  final String? code;
  final String fieldName;
  final String fieldLocation;
  final String date;
  final String time;
  final String price;
  final String total;
  final String status;
  final String? courtName;
  final String? customerName;
  final int durationHours;

  bool get isPaymentPending => status == 'Menunggu pembayaran';

  bool get isPaid =>
      status == 'Lunas via Midtrans' ||
      status == 'Dikonfirmasi' ||
      status == 'Selesai';

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'fieldName': fieldName,
    'fieldLocation': fieldLocation,
    'date': date,
    'time': time,
    'price': price,
    'total': total,
    'status': status,
    'courtName': courtName,
    'customerName': customerName,
    'durationHours': durationHours,
  };

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      id: int.tryParse(json['id']?.toString() ?? ''),
      code: json['code']?.toString(),
      fieldName: json['fieldName']?.toString() ?? 'Lapangan',
      fieldLocation: json['fieldLocation']?.toString() ?? '-',
      date: json['date']?.toString() ?? '-',
      time: json['time']?.toString() ?? '-',
      price: _formatAmount(json['price'] ?? json['amount']),
      total: _formatAmount(json['total'] ?? json['amount']),
      status: json['status']?.toString() ?? 'Dipesan',
      courtName: json['courtName']?.toString(),
      customerName: json['customerName']?.toString(),
      durationHours: int.tryParse(json['durationHours']?.toString() ?? '') ?? 1,
    );
  }

  static String _formatAmount(dynamic value) {
    if (value == null) return 'Rp 0';
    final amount = int.tryParse(value.toString());
    if (amount == null) return value.toString();
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $formatted';
  }
}
