/// دەقەکانی ڕووکاری سیستەمەکە (کوردی - سۆرانی).
///
/// English: Single place for every user facing string. The app is Kurdish
/// (Sorani / `ckb`) first, but keeping all labels here makes it possible to add
/// more languages later without touching the UI code.
class AppStrings {
  const AppStrings._();

  // ── گشتی (common) ────────────────────────────────────────────────────────
  static const String appTitle = 'RAND SUITE POS';
  static const String appSubtitle = 'سیستەمی پێشکەوتووی بەڕێوەبردنی خاڵی فرۆشتن';
  static const String brandName = 'RAND SUITE';
  static const String poweredBy = 'Powered by RAND SUITE';
  static const String developedBy = 'گەشەپێدراوە لەلایەن RAND SUITE';
  static const String brandTagline = 'سیستەمی مۆدێرن و خێرای مارکێت و خاڵی فرۆشتن';
  static const String loading = 'چاوەڕوان بە...';
  static const String noData = 'هیچ داتایەک نییە';
  static const String search = 'گەڕان';
  static const String add = 'زیادکردن';
  static const String edit = 'دەستکاری';
  static const String delete = 'سڕینەوە';
  static const String save = 'پاشەکەوتکردن';
  static const String cancel = 'پاشگەزبوونەوە';
  static const String close = 'داخستن';
  static const String confirm = 'دڵنیاکردنەوە';
  static const String apply = 'جێبەجێکردن';
  static const String all = 'هەموو';
  static const String yes = 'بەڵێ';
  static const String no = 'نەخێر';
  static const String copy = 'کۆپیکردن';
  static const String copied = 'کۆپی کرا';
  static const String saved = 'بە سەرکەوتوویی پاشەکەوت کرا';
  static const String deleted = 'سڕایەوە';
  static const String optional = 'ئارەزوومەندانە';
  static const String amount = 'بڕ';
  static const String quantity = 'بڕی کاڵا';
  static const String price = 'نرخ';
  static const String date = 'بەروار';
  static const String status = 'دۆخ';
  static const String actions = 'کردارەکان';
  static const String details = 'وردەکاری';
  static const String totalLabelOnly = 'کۆ';
  static const String required = 'پێویستە';
  static const String exactAmount = 'بڕی تەواو';
  static const String invalidNumberGeneric = 'تکایە ژمارەیەکی دروست بنووسە';

  // ── چوونەژوورەوە (authentication) ────────────────────────────────────────
  static const String login = 'چوونەژوورەوە';
  static const String signIn = 'چوونەژوورەوە بۆ سیستەم';
  static const String logout = 'دەرچوون';
  static const String username = 'ناوی بەکارهێنەر';
  static const String password = 'وشەی نهێنی';
  static const String fullName = 'ناوی تەواو';
  static const String role = 'ڕۆڵ';
  static const String roleAdmin = 'بەڕێوەبەر';
  static const String roleCashier = 'کاشێر';
  static const String roleAdminDesc = 'دەستڕاگەیشتنی تەواو بە هەموو بەشەکان';
  static const String roleCashierDesc = 'تەنها فرۆشتن و پسووڵەکان';
  static const String wrongCredentials = 'ناوی بەکارهێنەر یان وشەی نهێنی بە هەڵەیە';
  static const String inactiveUser = 'ئەم بەکارهێنەرە ناچالاک کراوە';
  static const String demoCredentials = 'بەکارهێنەری سەرەتا: admin / admin123';
  static const String welcomeBack = 'بەخێربێیتەوە';
  static const String confirmLogout = 'دەتەوێت بچیتە دەرەوە؟';
  static const String usernameTaken = 'ئەم ناوی بەکارهێنەرە پێشتر بەکارهاتووە';
  static const String userSaved = 'بەکارهێنەر پاشەکەوت کرا';
  static const String addUser = 'زیادکردنی بەکارهێنەر';
  static const String editUser = 'دەستکاریکردنی بەکارهێنەر';
  static const String deleteUserConfirm = 'ئەم بەکارهێنەرە بسڕدرێتەوە؟';
  static const String changePassword = 'گۆڕینی وشەی نهێنی';
  static const String newPassword = 'وشەی نهێنی نوێ';
  static const String passwordHint = 'لانیکەم ٤ پیت';
  static const String cantDeleteSelf = 'ناتوانیت خۆت بسڕیتەوە';
  static const String activeAccount = 'چالاک';

  // ── بەشەکان (navigation) ────────────────────────────────────────────────
  static const String dashboard = 'داشبۆرد';
  static const String pos = 'فرۆشتن (POS)';
  static const String posShort = 'فرۆشتن';
  static const String sales = 'پسووڵەکان';
  static const String products = 'کاڵاکان';
  static const String categories = 'پۆلەکان';
  static const String reports = 'ڕاپۆرتەکان';
  static const String settings = 'ڕێکخستنەکان';
  static const String users = 'بەکارهێنەران';
  static const String noPermission = 'دەستڕاگەیشتنت نییە بۆ ئەم بەشە';

  // ── داشبۆرد (dashboard) ─────────────────────────────────────────────────
  static const String todaySales = 'فرۆشتنی ئەمڕۆ';
  static const String todayInvoices = 'پسووڵەی ئەمڕۆ';
  static const String itemsSold = 'کاڵای فرۆشراو';
  static const String todayProfit = 'قازانجی ئەمڕۆ';
  static const String inventoryValue = 'بەهای کۆگا';
  static const String lowStockItems = 'کاڵای کەم';
  static const String quickActions = 'کردارە خێراکان';
  static const String recentSales = 'دوایین فرۆشتنەکان';
  static const String weeklySales = 'فرۆشتنی ٧ ڕۆژی ڕابردوو';
  static const String stockAlerts = 'ئاگادارییەکانی کۆگا';
  static const String allStockOk = 'دۆخی کۆگا باشە';

  // ── فرۆشتن (POS) ────────────────────────────────────────────────────────
  static const String searchProductOrBarcode = 'گەڕان بە ناو یان بارکۆد...';
  static const String barcode = 'بارکۆد';
  static const String scanBarcode = 'بارکۆد بخوێنەوە و Enter دابگرە';
  static const String cart = 'سەبەتە';
  static const String emptyCart = 'سەبەتە بەتاڵە';
  static const String emptyCartHint = 'کاڵایەک هەڵبژێرە بۆ دەستپێکردنی فرۆشتن';
  static const String subtotal = 'کۆی کاڵاکان';
  static const String discount = 'داشکاندن';
  static const String tax = 'باج';
  static const String total = 'کۆی گشتی';
  static const String checkout = 'پارەدان و تەواوکردن';
  static const String paymentMethod = 'شێوازی پارەدان';
  static const String cash = 'نەقد';
  static const String card = 'کارت';
  static const String credit = 'قەرز';
  static const String paidAmount = 'بڕی پارەی دراو';
  static const String change = 'گەڕانەوە';
  static const String paidLessThanTotal = 'بڕی پارەی دراو لە کۆی گشتی کەمترە';
  static const String customerName = 'ناوی کڕیار / قەرزدار';
  static const String customerPhone = 'مۆبایلی کڕیار';
  static const String debt = 'قەرز';
  static const String totalDebt = 'کۆی قەرز';
  static const String todayDebt = 'قەرزی ئەمڕۆ';
  static const String remainingDebt = 'قەرزی ماوە';
  static const String creditSales = 'فرۆشتنی قەرز';
  static const String cashSales = 'فرۆشتنی نەقد';
  static const String cardSales = 'فرۆشتنی کارت';
  static const String initialPayment = 'پێشەکی / دراو';
  static const String payDebt = 'دانەوەی قەرز';
  static const String debtSettled = 'قەرز بە سەرکەوتوویی درایەوە';
  static const String settleDebtTitle = 'دانەوەی قەرزی پسووڵە';
  static const String enterAmountToPay = 'بڕی پارەی دانراو بنووسە';
  static const String payFullDebt = 'دانەوەی هەمووی';
  static const String paymentBreakdown = 'شێوازی پارەدانەکان';
  static const String noDebt = 'قەرزی لەسەر نییە';
  static const String checkoutTitle = 'تەواوکردنی فرۆشتن';
  static const String saleCompleted = 'فرۆشتن تەواو بوو';
  static const String insufficientStock = 'کۆگا بەس نییە';
  static const String outOfStock = 'لە کۆگا نەماوە';
  static const String productNotFound = 'کاڵا نەدۆزرایەوە';
  static const String clearCart = 'سەبەتە بەتاڵ بکە';
  static const String clearCartConfirm = 'هەموو کاڵاکانی سەبەتە بسڕدرێنەوە؟';
  static const String remainingStock = 'ماوە لە کۆگا';
  static const String note = 'تێبینی';
  static const String holdCart = 'هەڵواسینی سەبەتە';
  static const String heldCarts = 'سەبەتە هەڵواسراوەکان';
  static const String cartHeld = 'سەبەتە هەڵواسرا';
  static const String resumeCart = 'گەڕاندنەوە بۆ سەبەتە';
  static const String allCategories = 'هەموو پۆلەکان';

  // ── کاڵا و پۆل (catalog) ────────────────────────────────────────────────
  static const String productName = 'ناوی کاڵا';
  static const String addProduct = 'زیادکردنی کاڵا';
  static const String editProduct = 'دەستکاریکردنی کاڵا';
  static const String productSaved = 'کاڵا پاشەکەوت کرا';
  static const String deleteProductConfirm = 'ئەم کاڵایە بسڕدرێتەوە؟';
  static const String category = 'پۆل';
  static const String withoutCategory = 'بێ پۆل';
  static const String unit = 'یەکە';
  static const String costPrice = 'نرخی کڕین';
  static const String salePrice = 'نرخی فرۆشتن';
  static const String stock = 'کۆگا';
  static const String initialStock = 'بڕی سەرەتایی';
  static const String lowStockThreshold = 'سنووری ئاگاداری';
  static const String profitMargin = 'ڕێژەی قازانج';
  static const String active = 'چالاک';
  static const String inactive = 'ناچالاک';
  static const String showInactive = 'پیشاندانی ناچالاک';
  static const String addCategory = 'زیادکردنی پۆل';
  static const String editCategory = 'دەستکاریکردنی پۆل';
  static const String categoryName = 'ناوی پۆل';
  static const String icon = 'نیشانە';
  static const String color = 'ڕەنگ';
  static const String deleteCategoryConfirm =
      'ئەم پۆلە بسڕدرێتەوە؟ کاڵاکانی دەچنە پۆلی «بێ پۆل»';
  static const String categoryUsedByProducts = 'کاڵا لەم پۆلەدا هەیە';
  static const String invalidPrice = 'نرخی فرۆشتن نابێت لە نرخی کڕین کەمتر بێت';
  static const String invalidNumber = 'تکایە ژمارەیەکی دروست بنووسە';
  static const String productCount = 'ژمارەی کاڵا';

  // ── پسووڵە (receipts / invoices) ────────────────────────────────────────
  static const String invoiceNumber = 'ژمارەی پسووڵە';
  static const String invoice = 'پسووڵە';
  static const String noReceipts = 'هیچ پسووڵەیەک نییە';
  static const String cashier = 'کاشێر';
  static const String lineItems = 'کاڵاکان';
  static const String thanksMessage = 'سوپاس بۆ کڕینەکەت — بەخێر بێیتەوە';
  static const String receipt = 'وەسڵ';
  static const String printReceipt = 'چاپکردنی وەسڵ';
  static const String copyReceipt = 'کۆپیکردنی وەسڵ وەک دەق';
  static const String receiptCopied = 'وەسڵ کۆپی کرا بۆ کلیپبۆرد';
  static const String printHint =
      'بۆ چاپکردن: وەسڵ کۆپی بکە یان لە ڕووکارەکەدا Ctrl+P بەکاربهێنە';
  static const String voidSale = 'هەڵوەشاندنەوە';
  static const String voidSaleConfirm =
      'ئەم پسووڵەیە هەڵبوەشێنرێتەوە و کاڵاکان بگەڕێنەوە کۆگا؟';
  static const String saleVoided = 'پسووڵە هەڵوەشێنرایەوە';
  static const String voided = 'هەڵوەشێنراوە';
  static const String completed = 'تەواوکراو';
  static const String searchInvoice = 'گەڕان بە ژمارەی پسووڵە...';
  static const String from = 'لە';
  static const String to = 'بۆ';
  static const String today = 'ئەمڕۆ';
  static const String yesterday = 'دوێنێ';
  static const String thisWeek = 'ئەم حەفتەیە';
  static const String thisMonth = 'ئەم مانگە';
  static const String allTime = 'هەموو کات';
  static const String customRange = 'ماوەی دیاریکراو';
  static const String selectRange = 'ماوە هەڵبژێرە';
  static const String soldBy = 'فرۆشراوە لەلایەن';
  static const String voidedBy = 'هەڵوەشێنرایەوە لەلایەن';

  // ── ڕاپۆرت (reports) ───────────────────────────────────────────────────
  static const String revenue = 'داهات';
  static const String totalCost = 'کۆی تێچوو';
  static const String profit = 'قازانج';
  static const String averageInvoice = 'ناوەندی پسووڵە';
  static const String topProducts = 'زۆرترین فرۆشراو';
  static const String salesByDay = 'فرۆشتن بەپێی ڕۆژ';
  static const String salesByCategory = 'فرۆشتن بەپێی پۆل';
  static const String byCashier = 'فرۆشتن بەپێی کاشێر';
  static const String exportCsv = 'هەناردەکردنی CSV';
  static const String csvCopied = 'CSV کۆپی کرا بۆ کلیپبۆرد';
  static const String dateRange = 'ماوەی بەروار';
  static const String quantitySold = 'بڕی فرۆشراو';
  static const String noSalesInRange = 'لەم ماوەیەدا فرۆشتن نییە';

  // ── ڕێکخستن (settings) ─────────────────────────────────────────────────
  static const String storeInfo = 'زانیاری فرۆشگا';
  static const String storeName = 'ناوی فرۆشگا';
  static const String phone = 'ژمارەی مۆبایل';
  static const String address = 'ناونیشان';
  static const String currencySymbol = 'دراوی بازنە';
  static const String currencyDecimals = 'ژمارەی دەیی لە نرخ';
  static const String taxPercent = 'ڕێژەی باج (%)';
  static const String receiptFooter = 'دەقی خوارەوەی وەسڵ';
  static const String appearance = 'شێوە و ڕەنگ';
  static const String darkMode = 'دۆخی تاریک';
  static const String language = 'زمان';
  static const String kurdish = 'کوردی (سۆرانی)';
  static const String dataManagement = 'بەڕێوەبردنی داتا';
  static const String seedDemoData = 'بارکردنی داتای نموونە';
  static const String seedConfirm =
      'داتای نموونە زیاد بکرێت؟ کاڵا و پسووڵەکانی ئێستا نامێنن';
  static const String seedDone = 'داتای نموونە بارکرا';
  static const String resetData = 'سڕینەوەی هەموو داتا';
  static const String resetConfirm =
      'هەموو کاڵا، پۆل، پسووڵە و ڕێکخستنەکان بسڕدرێنەوە؟ ئەم کردارە ناگەڕێتەوە';
  static const String resetDone = 'هەموو داتا سڕایەوە';
  static const String about = 'دەربارە';
  static const String version = 'وەشان';
  static const String storageNote =
      'داتاکان بە شێوەی ناوخۆیی (SharedPreferences) لەم ئامێرەدا پاشەکەوت دەکرێن';
  static const String settingsSaved = 'ڕێکخستنەکان پاشەکەوت کران';

  // ── بەرنامەی مۆبایل (PWA Install) ───────────────────────────────────────
  static const String installApp = 'دابەزاندنی ئەپ بۆ مۆبایل';
  static const String installAppDesc = 'بەکارهێنانی سیستەم وەک ئەپێکی سەربەخۆی مۆبایل';
  static const String pwaInstallTitle = 'دامەزراندنی Suli POS لەسەر مۆبایل';
  static const String pwaInstallIosGuide =
      'بۆ ئەوەی سیستەمەکە وەک ئەپێکی ڕەسمی لەسەر ئایفۆن دابەزێت:\n'
      '١. لە وێبگەڕی Safari دەست بنێ بە دوگمەی هاوبەشکردن (Share ⎋).\n'
      '٢. لە لیستەکەدا کلیک بکە لەسەر "Add to Home Screen" (زیادکردن بۆ پەڕەی سەرەکی).\n'
      '٣. دەست بنێ بە Add. ئێستا ئایکۆنی ڕەسمی Suli POS دەکەوێتە سەر شاشەی مۆبایلەکەت!';
  static const String pwaInstallAndroidGuide =
      'بۆ ئەوەی سیستەمەکە وەک ئەپێکی سەربەخۆ لەسەر ئەندرۆید دابەزێت:\n'
      '١. لە وێبگەڕی Chrome دەست بنێ بە سێ خاڵەکەی سەرەوە (⋮).\n'
      '٢. کلیک بکە لەسەر "Install app" یان "Add to Home screen".\n'
      '٣. پشتڕاستی بکەرەوە تا وەک ئەپی فەرمی و بەبێ شریتی وێب کاربکات!';
}
