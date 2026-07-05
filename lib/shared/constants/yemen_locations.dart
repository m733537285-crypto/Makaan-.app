class YemenLocations {
  const YemenLocations._();

  static const Map<String, List<String>> governorates = <String, List<String>>{
    'أمانة العاصمة': <String>['التحرير', 'الوحدة', 'السبعين', 'معين', 'بني الحارث'],
    'عدن': <String>['صيرة', 'خور مكسر', 'المنصورة', 'الشيخ عثمان', 'دار سعد'],
    'صنعاء': <String>['سنحان وبني بهلول', 'بني مطر', 'الحصن', 'همدان', 'بلاد الروس'],
    'تعز': <String>['المظفر', 'القاهرة', 'صالة', 'التعزية', 'المعافر'],
    'إب': <String>['الظهار', 'المشنة', 'بعدان', 'العدين', 'ذي السفال'],
    'الحديدة': <String>['الحديدة', 'الحوك', 'باجل', 'زبيد', 'بيت الفقيه'],
    'حضرموت': <String>['المكلا', 'الشحر', 'سيئون', 'تريم', 'القطن'],
    'مأرب': <String>['مدينة مأرب', 'الوادي', 'الجوبة', 'مدغل', 'صرواح'],
    'لحج': <String>['الحوطة', 'تبن', 'ردفان', 'طور الباحة', 'يافع'],
    'ذمار': <String>['مدينة ذمار', 'عنس', 'جبل الشرق', 'ضوران', 'وصاب العالي'],
  };

  static List<String> get governorateNames => governorates.keys.toList(growable: false);

  static List<String> districtsFor(String governorate) {
    return governorates[governorate] ?? const <String>[];
  }
}
