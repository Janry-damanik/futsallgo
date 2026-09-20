class BookingSummary {
  const BookingSummary({
    required this.fieldName,
    required this.fieldLocation,
    required this.date,
    required this.time,
    required this.price,
    required this.total,
    required this.status,
  });

  final String fieldName;
  final String fieldLocation;
  final String date;
  final String time;
  final String price;
  final String total;
  final String status;

  Map<String, dynamic> toJson() => {
        'fieldName': fieldName,
        'fieldLocation': fieldLocation,
        'date': date,
        'time': time,
        'price': price,
        'total': total,
        'status': status,
      };

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      fieldName: json['fieldName']?.toString() ?? 'Lapangan',
      fieldLocation: json['fieldLocation']?.toString() ?? '-',
      date: json['date']?.toString() ?? '-',
      time: json['time']?.toString() ?? '-',
      price: json['price']?.toString() ?? 'Rp 0',
      total: json['total']?.toString() ?? 'Rp 0',
      status: json['status']?.toString() ?? 'Dipesan',
    );
  }
}
