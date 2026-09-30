/// یەکەکانی پێوانەی کاڵا.
/// English: units a product can be sold in. `label` is used in forms,
/// `shortLabel` is shown in the cart/receipt to save space.
enum ProductUnit {
  piece('دانە', 'دانە'),
  pack('پاکەت', 'پاکەت'),
  box('کارتۆن', 'کارتۆن'),
  dozen('دەستە', 'دەستە'),
  kilogram('کیلۆگرام', 'کگ'),
  gram('گرام', 'گر'),
  liter('لیتر', 'لیتر'),
  milliliter('ملیلتر', 'مل'),
  meter('مەتر', 'مەتر');

  const ProductUnit(this.label, this.shortLabel);

  final String label;
  final String shortLabel;

  /// ئایا ئەم یەکەیە بە کێش یان قەبارە هەژمار دەکرێت (بۆ شێوەکردنی بڕ).
  bool get isMeasured =>
      this == ProductUnit.kilogram ||
      this == ProductUnit.gram ||
      this == ProductUnit.liter ||
      this == ProductUnit.milliliter;

  /// ئایا بڕ دەتوانێت دەیی بێت (بۆ نموونە ١.٥ کگ).
  bool get allowsFractions => isMeasured;

  static ProductUnit fromName(String? name) => ProductUnit.values.firstWhere(
    (ProductUnit unit) => unit.name == name,
    orElse: () => ProductUnit.piece,
  );
}
