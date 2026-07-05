import 'package:flutter/material.dart';

import '../../core/localization/localized_text.dart';
import '../../core/router/app_routes.dart';
import 'placeholder_models.dart';

class FeatureCatalog {
  const FeatureCatalog._();

  static const FeatureSpec home = FeatureSpec(
    title: LocalizedText('الرئيسية', 'Home'),
    subtitle: LocalizedText(
      'بحث، بنرات، تصنيفات، خدمات مميزة، عروض، وتوصيات.',
      'Search, banners, categories, featured services, offers, and recommendations.',
    ),
    screenKey: 'home',
    icon: Icons.home_rounded,
    navIndex: 0,
    showSearch: true,
    highlights: <LocalizedText>[
      LocalizedText('بحث مباشر', 'Instant search'),
      LocalizedText('عروض مميزة', 'Featured offers'),
      LocalizedText('خدمات مقترحة', 'Recommended services'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('ابحث الآن', 'Search now'),
        icon: Icons.search_rounded,
        routeName: AppRoutes.search,
      ),
      PlaceholderAction(
        label: LocalizedText('استعرض التصنيفات', 'Browse categories'),
        icon: Icons.grid_view_rounded,
        routeName: AppRoutes.categories,
      ),
      PlaceholderAction(
        label: LocalizedText('أنشئ طلب', 'Create request'),
        icon: Icons.add_task_rounded,
        routeName: AppRoutes.createRequest,
      ),
      PlaceholderAction(
        label: LocalizedText('أضف إعلان', 'Add ad'),
        icon: Icons.campaign_outlined,
        routeName: AppRoutes.addAd,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('وحدات المحتوى', 'Content modules'),
        items: <LocalizedText>[
          LocalizedText(
            'هيدر ترحيبي مع CTA رئيسي',
            'Primary welcome header with CTA',
          ),
          LocalizedText(
            'بنرات وعروض قابلة للتمرير',
            'Scrollable banners and offers',
          ),
          LocalizedText(
            'شبكة تصنيفات وخدمات سريعة',
            'Category grid and quick services',
          ),
        ],
      ),
      PlaceholderSection(
        title: LocalizedText('توصيات مخصصة', 'Personalized recommendations'),
        style: PlaceholderSectionStyle.chips,
        items: <LocalizedText>[
          LocalizedText('خدمات منزلية', 'Home services'),
          LocalizedText('نقل وشحن', 'Moving and logistics'),
          LocalizedText('صيانة عاجلة', 'Urgent maintenance'),
          LocalizedText('إعلانات مميزة', 'Premium ads'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(
        label: LocalizedText('تصنيفات', 'Categories'),
        value: '22',
      ),
      PlaceholderStat(
        label: LocalizedText('خدمات مقترحة', 'Suggestions'),
        value: '12+',
      ),
      PlaceholderStat(
        label: LocalizedText('مسارات سريعة', 'Quick actions'),
        value: '4',
      ),
    ],
  );

  static const FeatureSpec categories = FeatureSpec(
    title: LocalizedText('التصنيفات', 'Categories'),
    subtitle: LocalizedText(
      'عرض هرمي للتصنيفات والخدمات الفرعية والفلترة.',
      'Hierarchical categories, sub-services, and filtering.',
    ),
    screenKey: 'categories',
    icon: Icons.grid_view_rounded,
    navIndex: 1,
    highlights: <LocalizedText>[
      LocalizedText('فلترة', 'Filtering'),
      LocalizedText('عرض هرمي', 'Hierarchical view'),
      LocalizedText('خدمات فرعية', 'Sub-services'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('عرض الخدمات', 'View services'),
        icon: Icons.apps_rounded,
        routeName: AppRoutes.search,
      ),
      PlaceholderAction(
        label: LocalizedText('تطبيق الفلاتر', 'Apply filters'),
        icon: Icons.tune_rounded,
        demoKind: PlaceholderDemoKind.sheet,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('مستويات العرض', 'Display levels'),
        items: <LocalizedText>[
          LocalizedText(
            'تصنيفات رئيسية وبطاقات فرعية',
            'Main categories and nested cards',
          ),
          LocalizedText(
            'شيبس للفرز والمناطق',
            'Chips for sort and area filters',
          ),
          LocalizedText(
            'انتقال سريع إلى نتائج البحث',
            'Quick jump to search results',
          ),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('مستويات', 'Levels'), value: '3'),
      PlaceholderStat(label: LocalizedText('فلاتر', 'Filters'), value: '6'),
    ],
  );

  static const FeatureSpec search = FeatureSpec(
    title: LocalizedText('البحث', 'Search'),
    subtitle: LocalizedText(
      'بحث مباشر مع اقتراحات ونتائج وفرز وفلاتر.',
      'Instant search with suggestions, results, sorting, and filters.',
    ),
    screenKey: 'search',
    icon: Icons.search_rounded,
    showSearch: true,
    highlights: <LocalizedText>[
      LocalizedText('نتائج فورية', 'Instant results'),
      LocalizedText('فرز', 'Sorting'),
      LocalizedText('اقتراحات', 'Suggestions'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('فتح مقدم خدمة', 'Open provider'),
        icon: Icons.storefront_outlined,
        routeName: AppRoutes.providerProfile,
      ),
      PlaceholderAction(
        label: LocalizedText('خيارات الفرز', 'Sort options'),
        icon: Icons.swap_vert_rounded,
        demoKind: PlaceholderDemoKind.sheet,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('العناصر المطلوبة', 'Required elements'),
        items: <LocalizedText>[
          LocalizedText(
            'شريط بحث رئيسي مع فلاتر',
            'Primary search bar with filters',
          ),
          LocalizedText(
            'نتائج على هيئة بطاقات أو قائمة',
            'Cards or list-based results',
          ),
          LocalizedText(
            'اقتراحات قبل وبعد البحث',
            'Suggestions before and after searching',
          ),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(
        label: LocalizedText('أنماط النتائج', 'Result layouts'),
        value: '2',
      ),
      PlaceholderStat(
        label: LocalizedText('حالات البحث', 'Search states'),
        value: '4',
      ),
    ],
  );

  static const FeatureSpec providerProfile = FeatureSpec(
    title: LocalizedText('صفحة مقدم الخدمة', 'Provider profile'),
    subtitle: LocalizedText(
      'نبذة، خدمات، تقييمات، منطقة، وأزرار طلب وتواصل.',
      'Bio, services, reviews, area, and clear request/contact actions.',
    ),
    screenKey: 'provider_profile',
    icon: Icons.storefront_outlined,
    highlights: <LocalizedText>[
      LocalizedText('نبذة تعريفية', 'Profile summary'),
      LocalizedText('تقييمات', 'Reviews'),
      LocalizedText('منطقة الخدمة', 'Service area'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('إنشاء طلب', 'Create request'),
        icon: Icons.add_task_rounded,
        routeName: AppRoutes.createRequest,
      ),
      PlaceholderAction(
        label: LocalizedText('التقييمات', 'Reviews'),
        icon: Icons.reviews_outlined,
        routeName: AppRoutes.reviews,
        isPrimary: false,
      ),
      PlaceholderAction(
        label: LocalizedText('إبلاغ', 'Report'),
        icon: Icons.flag_outlined,
        routeName: AppRoutes.reports,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('محتوى الملف', 'Profile modules'),
        items: <LocalizedText>[
          LocalizedText(
            'ملخص موثوقية ووقت استجابة',
            'Trust badges and response time',
          ),
          LocalizedText('قائمة خدمات قابلة للحجز', 'Bookable service list'),
          LocalizedText('موقع ومنطقة تغطية', 'Location and coverage area'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('خدمات', 'Services'), value: '8+'),
      PlaceholderStat(label: LocalizedText('تقييم', 'Rating'), value: '4.8'),
    ],
  );

  static const FeatureSpec createRequest = FeatureSpec(
    title: LocalizedText('إنشاء طلب', 'Create request'),
    subtitle: LocalizedText(
      'تفاصيل الخدمة، الموقع، الموعد، الصور، الملاحظات، والميزانية.',
      'Service details, location, date, photos, notes, and budget.',
    ),
    screenKey: 'create_request',
    icon: Icons.add_task_rounded,
    highlights: <LocalizedText>[
      LocalizedText('Stepper', 'Stepper'),
      LocalizedText('مرفقات', 'Attachments'),
      LocalizedText('ميزانية', 'Budget'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('إرسال الطلب', 'Submit request'),
        icon: Icons.send_rounded,
        demoKind: PlaceholderDemoKind.success,
      ),
      PlaceholderAction(
        label: LocalizedText('اختيار الموقع', 'Pick location'),
        icon: Icons.location_on_outlined,
        routeName: AppRoutes.locationPicker,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('خطوات النموذج', 'Form steps'),
        items: <LocalizedText>[
          LocalizedText('الخدمة والموعد', 'Service and appointment'),
          LocalizedText('الموقع والصور', 'Location and photos'),
          LocalizedText('الملاحظات والميزانية', 'Notes and budget'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('الخطوات', 'Steps'), value: '3'),
      PlaceholderStat(
        label: LocalizedText('حقول حرجة', 'Critical fields'),
        value: '6',
      ),
    ],
  );

  static const FeatureSpec orders = FeatureSpec(
    title: LocalizedText('الطلبات', 'Orders'),
    subtitle: LocalizedText(
      'قائمة الطلبات مع التبويبات والحالات والزمن والإجراءات.',
      'Order list with tabs, statuses, time indicators, and actions.',
    ),
    screenKey: 'orders',
    icon: Icons.receipt_long_rounded,
    navIndex: 2,
    highlights: <LocalizedText>[
      LocalizedText('تبويبات', 'Tabs'),
      LocalizedText('حالات الطلب', 'Status tracking'),
      LocalizedText('إجراءات سريعة', 'Quick actions'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('عرض التفاصيل', 'View details'),
        icon: Icons.visibility_outlined,
        routeName: AppRoutes.createRequest,
      ),
      PlaceholderAction(
        label: LocalizedText('إلغاء الطلب', 'Cancel order'),
        icon: Icons.cancel_outlined,
        demoKind: PlaceholderDemoKind.dialog,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('أنواع البطاقات', 'Card types'),
        items: <LocalizedText>[
          LocalizedText(
            'جديد · قيد التنفيذ · مكتمل',
            'New · In progress · Completed',
          ),
          LocalizedText('مؤقتات وشرائط حالة', 'Timers and status banners'),
          LocalizedText('CTA للتقييم وإعادة الطلب', 'Review and reorder CTAs'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('تبويبات', 'Tabs'), value: '4'),
      PlaceholderStat(label: LocalizedText('إجراءات', 'Actions'), value: '3'),
    ],
  );

  static const FeatureSpec notifications = FeatureSpec(
    title: LocalizedText('الإشعارات', 'Notifications'),
    subtitle: LocalizedText(
      'إشعارات مجمعة حسب النوع مع حالات القراءة والإجراء.',
      'Grouped notifications with read state and contextual actions.',
    ),
    screenKey: 'notifications',
    icon: Icons.notifications_none_rounded,
    highlights: <LocalizedText>[
      LocalizedText('مجمعة', 'Grouped'),
      LocalizedText('مقروء/غير مقروء', 'Read state'),
      LocalizedText('إجراءات', 'Actions'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('فتح الطلب', 'Open order'),
        icon: Icons.open_in_new_rounded,
        routeName: AppRoutes.orders,
      ),
      PlaceholderAction(
        label: LocalizedText('تعليم كمقروء', 'Mark as read'),
        icon: Icons.done_all_rounded,
        demoKind: PlaceholderDemoKind.success,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('أنواع الإشعارات', 'Notification types'),
        style: PlaceholderSectionStyle.chips,
        items: <LocalizedText>[
          LocalizedText('طلبات', 'Orders'),
          LocalizedText('عروض', 'Offers'),
          LocalizedText('اشتراك', 'Subscription'),
          LocalizedText('دعم', 'Support'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('مجموعات', 'Groups'), value: '4'),
      PlaceholderStat(label: LocalizedText('إجراءات', 'Actions'), value: '3'),
    ],
  );

  static const FeatureSpec ads = FeatureSpec(
    title: LocalizedText('الإعلانات', 'Ads'),
    subtitle: LocalizedText(
      'سوق إعلانات مع فلاتر وبطاقات وCTA واضح.',
      'Marketplace-style ads with filters, cards, and a clear CTA.',
    ),
    screenKey: 'ads',
    icon: Icons.campaign_outlined,
    navIndex: 3,
    showSearch: true,
    showFab: true,
    fabRoute: AppRoutes.addAd,
    fabLabel: LocalizedText('إضافة إعلان', 'Add ad'),
    highlights: <LocalizedText>[
      LocalizedText('بطاقات إعلانية', 'Ad cards'),
      LocalizedText('فلاتر', 'Filters'),
      LocalizedText('حفظ ومشاركة', 'Save and share'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('عرض الإعلان', 'View ad'),
        icon: Icons.visibility_outlined,
        routeName: AppRoutes.adDetails,
      ),
      PlaceholderAction(
        label: LocalizedText('إجراءات الإعلان', 'Ad actions'),
        icon: Icons.more_horiz_rounded,
        demoKind: PlaceholderDemoKind.sheet,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('بنية السوق', 'Marketplace structure'),
        items: <LocalizedText>[
          LocalizedText(
            'معرض صور وسعر وموقع',
            'Image gallery, price, and location',
          ),
          LocalizedText('شارات للإعلانات المميزة', 'Badges for promoted ads'),
          LocalizedText(
            'حفظ، مشاركة، وتواصل',
            'Save, share, and contact actions',
          ),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(
        label: LocalizedText('أنماط البطاقة', 'Card variants'),
        value: '3',
      ),
      PlaceholderStat(label: LocalizedText('فلاتر', 'Filters'), value: '5'),
    ],
  );

  static const FeatureSpec addAd = FeatureSpec(
    title: LocalizedText('إضافة إعلان', 'Add ad'),
    subtitle: LocalizedText(
      'نموذج متعدد الخطوات مع صور وسعر وموقع وتفاصيل.',
      'Multi-step ad form with images, price, location, and details.',
    ),
    screenKey: 'add_ad',
    icon: Icons.add_box_outlined,
    highlights: <LocalizedText>[
      LocalizedText('متعدد الخطوات', 'Multi-step'),
      LocalizedText('صور', 'Photos'),
      LocalizedText('سعر وموقع', 'Price and location'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('نشر الإعلان', 'Publish ad'),
        icon: Icons.publish_rounded,
        demoKind: PlaceholderDemoKind.success,
      ),
      PlaceholderAction(
        label: LocalizedText('معرض الصور', 'Image gallery'),
        icon: Icons.photo_library_outlined,
        routeName: AppRoutes.gallery,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('أقسام النموذج', 'Form sections'),
        items: <LocalizedText>[
          LocalizedText('بيانات أساسية وصور', 'Basic information and media'),
          LocalizedText('سعر وموقع وتفاصيل', 'Price, location, and details'),
          LocalizedText('معاينة قبل النشر', 'Preview before publishing'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('الخطوات', 'Steps'), value: '3'),
      PlaceholderStat(
        label: LocalizedText('حقول الوسائط', 'Media fields'),
        value: '2',
      ),
    ],
  );

  static const FeatureSpec adDetails = FeatureSpec(
    title: LocalizedText('تفاصيل الإعلان', 'Ad details'),
    subtitle: LocalizedText(
      'معرض صور، وصف، المالك، الموقع، بلاغ، ومشاركة.',
      'Image gallery, description, owner info, location, reporting, and sharing.',
    ),
    screenKey: 'ad_details',
    icon: Icons.apartment_outlined,
    highlights: <LocalizedText>[
      LocalizedText('معرض صور', 'Gallery'),
      LocalizedText('وصف تفصيلي', 'Detailed description'),
      LocalizedText('مشاركة', 'Share'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('تواصل', 'Contact'),
        icon: Icons.call_outlined,
        demoKind: PlaceholderDemoKind.success,
      ),
      PlaceholderAction(
        label: LocalizedText('إبلاغ', 'Report'),
        icon: Icons.flag_outlined,
        routeName: AppRoutes.reports,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('الوحدات المطلوبة', 'Required modules'),
        items: <LocalizedText>[
          LocalizedText('صور وبادجات حالة', 'Photos and status badges'),
          LocalizedText('بيانات المالك والموقع', 'Owner details and location'),
          LocalizedText('إجراءات الحفظ والمشاركة', 'Save and share actions'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('وسائط', 'Media'), value: '10+'),
      PlaceholderStat(label: LocalizedText('إجراءات', 'Actions'), value: '4'),
    ],
  );

  static const FeatureSpec profile = FeatureSpec(
    title: LocalizedText('الملف الشخصي', 'Profile'),
    subtitle: LocalizedText(
      'بيانات المستخدم، مؤشرات الحساب، المفضلة، وإعدادات سريعة.',
      'User details, account KPIs, favorites, and quick settings.',
    ),
    screenKey: 'profile',
    icon: Icons.person_outline_rounded,
    navIndex: 4,
    highlights: <LocalizedText>[
      LocalizedText('مؤشرات الحساب', 'Account KPIs'),
      LocalizedText('إجراءات سريعة', 'Quick actions'),
      LocalizedText('مفضلة', 'Favorites'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('إدارة الطلبات', 'Manage orders'),
        icon: Icons.receipt_long_rounded,
        routeName: AppRoutes.orders,
      ),
      PlaceholderAction(
        label: LocalizedText('الاشتراك', 'Subscription'),
        icon: Icons.workspace_premium_outlined,
        routeName: AppRoutes.subscription,
        isPrimary: false,
      ),
      PlaceholderAction(
        label: LocalizedText('الإعدادات', 'Settings'),
        icon: Icons.settings_outlined,
        routeName: AppRoutes.settings,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('وحدات الحساب', 'Account modules'),
        items: <LocalizedText>[
          LocalizedText('بطاقة هوية المستخدم', 'User identity header'),
          LocalizedText(
            'روابط للإعلانات والطلبات',
            'Shortcuts to ads and orders',
          ),
          LocalizedText('مفضلة وإعدادات سريعة', 'Favorites and quick settings'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(
        label: LocalizedText('روابط سريعة', 'Quick links'),
        value: '5',
      ),
      PlaceholderStat(label: LocalizedText('مؤشرات', 'KPIs'), value: '3'),
    ],
  );

  static const FeatureSpec subscription = FeatureSpec(
    title: LocalizedText('الاشتراك', 'Subscription'),
    subtitle: LocalizedText(
      'الخطط والمزايا والفواتير وسجل التجديد.',
      'Plans, benefits, invoices, and renewal history.',
    ),
    screenKey: 'subscription',
    icon: Icons.workspace_premium_outlined,
    highlights: <LocalizedText>[
      LocalizedText('خطط', 'Plans'),
      LocalizedText('مقارنة', 'Comparison'),
      LocalizedText('تجديد', 'Renewal'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('اختيار الخطة', 'Choose plan'),
        icon: Icons.check_circle_outline_rounded,
        demoKind: PlaceholderDemoKind.success,
      ),
      PlaceholderAction(
        label: LocalizedText('مقارنة', 'Compare'),
        icon: Icons.compare_arrows_rounded,
        demoKind: PlaceholderDemoKind.sheet,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('محتوى الاشتراك', 'Subscription content'),
        items: <LocalizedText>[
          LocalizedText('بطاقات خطط ومزايا', 'Plan cards and benefits'),
          LocalizedText('سجل فواتير وتجديد', 'Invoices and renewal history'),
          LocalizedText('CTA للترقية أو التجديد', 'Upgrade and renew CTAs'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('خطط', 'Plans'), value: '3'),
      PlaceholderStat(
        label: LocalizedText('مستوى المقارنة', 'Compare depth'),
        value: '1',
      ),
    ],
  );

  static const FeatureSpec support = FeatureSpec(
    title: LocalizedText('الدعم', 'Support'),
    subtitle: LocalizedText(
      'فتح تذكرة، قنوات تواصل، وحالة الطلبات السابقة.',
      'Create tickets, access channels, and review previous cases.',
    ),
    screenKey: 'support',
    icon: Icons.headset_mic_outlined,
    highlights: <LocalizedText>[
      LocalizedText('تذكرة', 'Ticket'),
      LocalizedText('قنوات تواصل', 'Channels'),
      LocalizedText('حالة سابقة', 'Past tickets'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('إنشاء تذكرة', 'Create ticket'),
        icon: Icons.add_comment_outlined,
        demoKind: PlaceholderDemoKind.success,
      ),
      PlaceholderAction(
        label: LocalizedText('المساعدة', 'Help center'),
        icon: Icons.help_outline_rounded,
        routeName: AppRoutes.help,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('قوالب الدعم', 'Support templates'),
        items: <LocalizedText>[
          LocalizedText('نموذج تذكرة مختصر', 'Compact ticket form'),
          LocalizedText('قنوات التواصل السريعة', 'Quick contact channels'),
          LocalizedText('قائمة الحالات السابقة', 'Past support cases'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('قنوات', 'Channels'), value: '3'),
      PlaceholderStat(
        label: LocalizedText('أنواع تذاكر', 'Ticket types'),
        value: '4',
      ),
    ],
  );

  static const FeatureSpec help = FeatureSpec(
    title: LocalizedText('المساعدة', 'Help'),
    subtitle: LocalizedText(
      'FAQ، أدلة الاستخدام، الشروط، والسياسات.',
      'FAQ, usage guides, terms, and policies.',
    ),
    screenKey: 'help',
    icon: Icons.help_outline_rounded,
    highlights: <LocalizedText>[
      LocalizedText('FAQ', 'FAQ'),
      LocalizedText('أدلة', 'Guides'),
      LocalizedText('سياسات', 'Policies'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('تواصل معنا', 'Contact us'),
        icon: Icons.support_agent_rounded,
        routeName: AppRoutes.support,
      ),
      PlaceholderAction(
        label: LocalizedText('تصفح المقالات', 'Browse articles'),
        icon: Icons.article_outlined,
        demoKind: PlaceholderDemoKind.sheet,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('المحتوى المعرفي', 'Knowledge content'),
        items: <LocalizedText>[
          LocalizedText('مقالات مرتبة حسب المجال', 'Topic-based articles'),
          LocalizedText(
            'أسئلة شائعة قابلة للطي',
            'Expandable frequently asked questions',
          ),
          LocalizedText('روابط للشروط والسياسات', 'Terms and policy links'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('أقسام', 'Sections'), value: '4'),
      PlaceholderStat(
        label: LocalizedText('أنواع المحتوى', 'Content types'),
        value: '3',
      ),
    ],
  );

  static const FeatureSpec reports = FeatureSpec(
    title: LocalizedText('البلاغات', 'Reports'),
    subtitle: LocalizedText(
      'إرسال بلاغ ومتابعته مع تصنيف السبب والأدلة.',
      'Submit and track reports with reason classification and evidence.',
    ),
    screenKey: 'reports',
    icon: Icons.flag_outlined,
    highlights: <LocalizedText>[
      LocalizedText('تصنيف السبب', 'Reason category'),
      LocalizedText('أدلة', 'Evidence'),
      LocalizedText('تتبع الحالة', 'Status tracking'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('إرسال البلاغ', 'Submit report'),
        icon: Icons.send_rounded,
        demoKind: PlaceholderDemoKind.success,
      ),
      PlaceholderAction(
        label: LocalizedText('إضافة مرفق', 'Add attachment'),
        icon: Icons.attach_file_rounded,
        routeName: AppRoutes.gallery,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('تفاصيل البلاغ', 'Report details'),
        items: <LocalizedText>[
          LocalizedText('اختيار سبب البلاغ', 'Choose reason'),
          LocalizedText('وصف مختصر ومرفقات', 'Description and attachments'),
          LocalizedText(
            'حالة المراجعة والمتابعة',
            'Review status and follow-up',
          ),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('أسباب', 'Reasons'), value: '5'),
      PlaceholderStat(
        label: LocalizedText('أنواع أدلة', 'Evidence types'),
        value: '3',
      ),
    ],
  );

  static const FeatureSpec reviews = FeatureSpec(
    title: LocalizedText('التقييمات', 'Reviews'),
    subtitle: LocalizedText(
      'ملخص النجوم، التعليقات، الفرز، وكتابة تقييم.',
      'Star summary, comments, sorting, and write-review CTA.',
    ),
    screenKey: 'reviews',
    icon: Icons.reviews_outlined,
    highlights: <LocalizedText>[
      LocalizedText('نجوم', 'Stars'),
      LocalizedText('تعليقات', 'Comments'),
      LocalizedText('فرز', 'Sorting'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('كتابة تقييم', 'Write review'),
        icon: Icons.edit_note_rounded,
        demoKind: PlaceholderDemoKind.success,
      ),
      PlaceholderAction(
        label: LocalizedText('خيارات الفرز', 'Sort options'),
        icon: Icons.filter_list_rounded,
        demoKind: PlaceholderDemoKind.sheet,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('مكوّنات التقييم', 'Review modules'),
        items: <LocalizedText>[
          LocalizedText('ملخص النجوم والإحصاءات', 'Star summary and metrics'),
          LocalizedText('تعليقات قابلة للتصفية', 'Filterable comments'),
          LocalizedText('CTA لإضافة تقييم جديد', 'Add-review call to action'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(
        label: LocalizedText('فئات النجوم', 'Star buckets'),
        value: '5',
      ),
      PlaceholderStat(
        label: LocalizedText('أنماط الفرز', 'Sort modes'),
        value: '3',
      ),
    ],
  );

  static const FeatureSpec dashboard = FeatureSpec(
    title: LocalizedText('لوحة التحكم', 'Dashboard'),
    subtitle: LocalizedText(
      'مؤشرات، إدارة محتوى، مستخدمين، طلبات، وإعلانات.',
      'Operational dashboard with KPIs, content, users, orders, and ad management.',
    ),
    screenKey: 'dashboard',
    icon: Icons.space_dashboard_outlined,
    highlights: <LocalizedText>[
      LocalizedText('KPI', 'KPIs'),
      LocalizedText('إدارة محتوى', 'Content management'),
      LocalizedText('نشاطات', 'Activity feed'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('مراجعة البلاغات', 'Review reports'),
        icon: Icons.fact_check_outlined,
        routeName: AppRoutes.reports,
      ),
      PlaceholderAction(
        label: LocalizedText('إدارة الإعلانات', 'Manage ads'),
        icon: Icons.campaign_outlined,
        routeName: AppRoutes.ads,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('وحدات الإدارة', 'Admin modules'),
        items: <LocalizedText>[
          LocalizedText('KPI summary', 'KPI summary'),
          LocalizedText(
            'أحدث الطلبات والبلاغات',
            'Latest orders and pending reports',
          ),
          LocalizedText(
            'إدارة البنرات والعروض والنشاطات',
            'Banners, offers, and activity feed',
          ),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('وحدات', 'Modules'), value: '6'),
      PlaceholderStat(label: LocalizedText('إجراءات', 'Actions'), value: '5'),
    ],
  );

  static const FeatureSpec locationPicker = FeatureSpec(
    title: LocalizedText('اختيار الموقع', 'Location picker'),
    subtitle: LocalizedText(
      'اختيار المحافظة والمديرية أو تعذر الوصول للموقع.',
      'Choose region and district or handle location access errors.',
    ),
    screenKey: 'location_picker',
    icon: Icons.location_on_outlined,
    highlights: <LocalizedText>[
      LocalizedText('محافظة', 'Region'),
      LocalizedText('مديرية', 'District'),
      LocalizedText('خطأ الموقع', 'Location failure'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('فتح القائمة السفلية', 'Open bottom sheet'),
        icon: Icons.expand_less_rounded,
        demoKind: PlaceholderDemoKind.sheet,
      ),
      PlaceholderAction(
        label: LocalizedText('تأكيد', 'Confirm'),
        icon: Icons.check_rounded,
        demoKind: PlaceholderDemoKind.success,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('السيناريوهات', 'Scenarios'),
        items: <LocalizedText>[
          LocalizedText('محافظة ثم مديرية', 'Region then district'),
          LocalizedText(
            'تحديد يدوي عند فشل الوصول',
            'Manual override on access failure',
          ),
          LocalizedText(
            'رسائل خطأ ونجاح واضحة',
            'Clear success and error messages',
          ),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(label: LocalizedText('مستويات', 'Levels'), value: '2'),
    ],
  );

  static const FeatureSpec gallery = FeatureSpec(
    title: LocalizedText('معرض الصور', 'Image gallery'),
    subtitle: LocalizedText(
      'معاينة صور الإعلان أو الطلب أو المرفقات.',
      'Preview ad, request, or attachment images.',
    ),
    screenKey: 'gallery',
    icon: Icons.photo_library_outlined,
    highlights: <LocalizedText>[
      LocalizedText('تكبير', 'Zoom'),
      LocalizedText('تنقل', 'Navigation'),
      LocalizedText('مؤشرات', 'Indicators'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('مشاركة', 'Share'),
        icon: Icons.share_outlined,
        demoKind: PlaceholderDemoKind.success,
      ),
      PlaceholderAction(
        label: LocalizedText('إغلاق', 'Close'),
        icon: Icons.close_rounded,
        isPrimary: false,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('خصائص المعرض', 'Gallery capabilities'),
        items: <LocalizedText>[
          LocalizedText('معاينة كاملة للشاشة', 'Full-screen preview'),
          LocalizedText('مؤشر لعدد الصور', 'Image count indicator'),
          LocalizedText('أزرار مشاركة وإبلاغ', 'Share and report actions'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(
        label: LocalizedText('تنقل', 'Navigation'),
        value: 'Swipe',
      ),
    ],
  );

  static const FeatureSpec notFound = FeatureSpec(
    title: LocalizedText('404 داخلية', 'Internal 404'),
    subtitle: LocalizedText(
      'عند فقدان الصفحة أو البيانات داخل التطبيق.',
      'Used when a page or data is missing inside the app.',
    ),
    screenKey: 'not_found',
    icon: Icons.error_outline_rounded,
    highlights: <LocalizedText>[
      LocalizedText('إعادة توجيه', 'Redirect'),
      LocalizedText('معلومات مساعدة', 'Helpful message'),
      LocalizedText('عودة آمنة', 'Safe return'),
    ],
    actions: <PlaceholderAction>[
      PlaceholderAction(
        label: LocalizedText('العودة للرئيسية', 'Back home'),
        icon: Icons.home_rounded,
        routeName: AppRoutes.home,
      ),
    ],
    sections: <PlaceholderSection>[
      PlaceholderSection(
        title: LocalizedText('رسائل الإرشاد', 'Guidance'),
        items: <LocalizedText>[
          LocalizedText('شرح مختصر للمشكلة', 'Short explanation'),
          LocalizedText('زر رجوع واضح', 'Clear back CTA'),
          LocalizedText('دعم للوضع الفارغ', 'Support empty-state recovery'),
        ],
      ),
    ],
    stats: <PlaceholderStat>[
      PlaceholderStat(
        label: LocalizedText('نوع الحالة', 'State type'),
        value: '404',
      ),
    ],
  );
}
