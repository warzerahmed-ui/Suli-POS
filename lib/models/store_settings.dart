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

  StoreSettings copyWith({
    String? storeName,
    String? phone,
    String? address,
    String? currencySymbol,
    int? currencyDecimals,
    double? taxPercent,
    String? receiptFooter,
    bool? isDarkMode,
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
      );
}
