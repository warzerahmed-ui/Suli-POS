/// ڕێکخستنەکانی فرۆشگا کە لە هەموو سیستەمەکەدا بەکاردێن.
/// English: store profile + money/locale preferences, persisted locally.
class StoreSettings {
  const StoreSettings({
    this.storeName = 'مارکێتی نموونە',
    this.phone = '',
    this.address = '',
    this.currencySymbol = 'د.ع',
    this.currencyDecimals = 0,
    this.taxPercent = 0,
    this.receiptFooter = 'سوپاس بۆ کڕینەکەت',
    this.isDarkMode = false,
    this.pointsEnabled = true,
    this.pointsPerAmount = 1000,
    this.amountPerPoint = 10,
  });

  final String storeName;
  final String phone;
  final String address;
  final String currencySymbol;

  /// ژمارەی دەهییەکان کە لە نرخ پیشان دەدرێن (0 بۆ دینار).
  final int currencyDecimals;
  final double taxPercent;
  final String receiptFooter;
  final bool isDarkMode;

  /// سیستەمی پۆینتی کڕیاران
  final bool pointsEnabled;

  /// بۆ هەر چەند دینار کڕین ١ پۆینت هەژمار بکرێت (default: 1000 د.ع)
  final double pointsPerAmount;

  /// بەهای هەر ١ پۆینت لە کاتی بەکارهێنان بۆ کڕین (default: 10 د.ع)
  final double amountPerPoint;

  StoreSettings copyWith({
    String? storeName,
    String? phone,
    String? address,
    String? currencySymbol,
    int? currencyDecimals,
    double? taxPercent,
    String? receiptFooter,
    bool? isDarkMode,
    bool? pointsEnabled,
    double? pointsPerAmount,
    double? amountPerPoint,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyDecimals: currencyDecimals ?? this.currencyDecimals,
      taxPercent: taxPercent ?? this.taxPercent,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pointsEnabled: pointsEnabled ?? this.pointsEnabled,
      pointsPerAmount: pointsPerAmount ?? this.pointsPerAmount,
      amountPerPoint: amountPerPoint ?? this.amountPerPoint,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'storeName': storeName,
        'phone': phone,
        'address': address,
        'currencySymbol': currencySymbol,
        'currencyDecimals': currencyDecimals,
        'taxPercent': taxPercent,
        'receiptFooter': receiptFooter,
        'isDarkMode': isDarkMode,
        'pointsEnabled': pointsEnabled,
        'pointsPerAmount': pointsPerAmount,
        'amountPerPoint': amountPerPoint,
      };

  factory StoreSettings.fromJson(Map<String, dynamic> json) => StoreSettings(
        storeName: json['storeName'] as String? ?? 'مارکێتی نموونە',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        currencySymbol: json['currencySymbol'] as String? ?? 'د.ع',
        currencyDecimals: (json['currencyDecimals'] as num?)?.toInt() ?? 0,
        taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
        receiptFooter: json['receiptFooter'] as String? ?? '',
        isDarkMode: json['isDarkMode'] as bool? ?? false,
        pointsEnabled: json['pointsEnabled'] as bool? ?? true,
        pointsPerAmount: (json['pointsPerAmount'] as num?)?.toDouble() ?? 1000,
        amountPerPoint: (json['amountPerPoint'] as num?)?.toDouble() ?? 10,
      );
}

