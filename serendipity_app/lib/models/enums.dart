import 'package:hive/hive.dart';

part 'enums.g.dart';

/// 记录状态
@HiveType(typeId: 10)
enum EncounterStatus {
  @HiveField(0)
  missed(1, '错过', '🌫️'),
  @HiveField(1)
  reencounter(2, '再遇', '🌟'),
  @HiveField(2)
  met(3, '邂逅', '💫'),
  @HiveField(3)
  reunion(4, '重逢', '💝'),
  @HiveField(4)
  farewell(5, '别离', '🥀'),
  @HiveField(5)
  lost(6, '失联', '🍂');

  final int value;
  final String label;
  final String icon;
  
  const EncounterStatus(this.value, this.label, this.icon);
}

/// 情绪强度
@HiveType(typeId: 11)
enum EmotionIntensity {
  @HiveField(0)
  barelyFelt(1, '几乎没感觉'),
  @HiveField(1)
  slightlyCared(2, '有点在意'),
  @HiveField(2)
  thoughtOnWayHome(3, '回家后还在想'),
  @HiveField(3)
  allNight(4, '想了一整晚'),
  @HiveField(4)
  untilNow(5, '至今难忘');

  final int value;
  final String label;
  
  const EmotionIntensity(this.value, this.label);
}

/// 场所类型
@HiveType(typeId: 12)
enum PlaceType {
  // 交通
  @HiveField(0)
  subway('subway', '地铁', '🚇'),
  @HiveField(1)
  bus('bus', '公交', '🚌'),
  @HiveField(2)
  train('train', '火车站', '🚄'),
  @HiveField(3)
  airport('airport', '机场', '✈️'),
  
  // 餐饮
  @HiveField(4)
  coffeeShop('coffee_shop', '咖啡馆', '☕'),
  @HiveField(5)
  restaurant('restaurant', '餐厅', '🍽️'),
  @HiveField(6)
  bar('bar', '酒吧', '🍺'),
  @HiveField(7)
  teaHouse('tea_house', '茶馆', '🍵'),
  @HiveField(8)
  dessertShop('dessert_shop', '甜品店', '🍰'),
  
  // 购物
  @HiveField(9)
  mall('mall', '商场', '🛍️'),
  @HiveField(10)
  supermarket('supermarket', '超市', '🛒'),
  @HiveField(11)
  bookstore('bookstore', '书店', '📚'),
  
  // 休闲娱乐
  @HiveField(12)
  park('park', '公园', '🌳'),
  @HiveField(13)
  cinema('cinema', '电影院', '🎬'),
  @HiveField(14)
  museum('museum', '博物馆', '🏛️'),
  @HiveField(15)
  artGallery('art_gallery', '美术馆', '🎨'),
  @HiveField(16)
  aquarium('aquarium', '水族馆', '🐠'),
  @HiveField(17)
  zoo('zoo', '动物园', '🦁'),
  @HiveField(18)
  amusementPark('amusement_park', '游乐园', '🎡'),
  
  // 运动健身
  @HiveField(19)
  gym('gym', '健身房', '💪'),
  @HiveField(20)
  swimmingPool('swimming_pool', '游泳馆', '🏊'),
  @HiveField(21)
  stadium('stadium', '体育馆', '🏟️'),
  
  // 学习工作
  @HiveField(22)
  library('library', '图书馆', '📖'),
  @HiveField(23)
  school('school', '学校', '🎓'),
  @HiveField(24)
  office('office', '办公楼', '🏢'),
  
  // 医疗健康
  @HiveField(25)
  hospital('hospital', '医院', '🏥'),
  @HiveField(26)
  clinic('clinic', '诊所', '⚕️'),
  
  // 其他
  @HiveField(27)
  hotel('hotel', '酒店', '🏨'),
  @HiveField(28)
  beach('beach', '海滩', '🏖️'),
  @HiveField(29)
  mountain('mountain', '山/景区', '⛰️'),
  @HiveField(30)
  street('street', '街道', '🛣️'),
  @HiveField(31)
  other('other', '其他', '📍');

  final String value;
  final String label;
  final String icon;
  
  const PlaceType(this.value, this.label, this.icon);
}

/// 天气类型
@HiveType(typeId: 13)
enum Weather {
  // 天空状况
  @HiveField(0)
  sunny(1, '晴天', '☀️', WeatherCategory.sky),
  @HiveField(1)
  cloudy(2, '多云', '⛅', WeatherCategory.sky),
  @HiveField(2)
  overcast(3, '阴天', '☁️', WeatherCategory.sky),
  
  // 降水类 - 雨
  @HiveField(3)
  drizzle(4, '毛毛雨', '🌦️', WeatherCategory.precipitation),
  @HiveField(4)
  lightRain(5, '小雨', '🌦️', WeatherCategory.precipitation),
  @HiveField(5)
  moderateRain(6, '中雨', '🌧️', WeatherCategory.precipitation),
  @HiveField(6)
  heavyRain(7, '大雨', '🌧️', WeatherCategory.precipitation),
  @HiveField(7)
  rainstorm(8, '暴雨', '⛈️', WeatherCategory.precipitation),
  @HiveField(8)
  freezingRain(9, '冻雨', '🧊', WeatherCategory.precipitation),
  
  // 降水类 - 雪
  @HiveField(9)
  lightSnow(10, '小雪', '🌨️', WeatherCategory.precipitation),
  @HiveField(10)
  moderateSnow(11, '中雪', '❄️', WeatherCategory.precipitation),
  @HiveField(11)
  heavySnow(12, '大雪', '❄️', WeatherCategory.precipitation),
  @HiveField(12)
  snowstorm(13, '暴雪', '❄️', WeatherCategory.precipitation),
  
  // 降水类 - 其他
  @HiveField(13)
  sleet(14, '雨夹雪', '🌨️', WeatherCategory.precipitation),
  @HiveField(14)
  hail(15, '冰雹', '🧊', WeatherCategory.precipitation),
  
  // 能见度
  @HiveField(15)
  mist(16, '轻雾', '🌫️', WeatherCategory.visibility),
  @HiveField(16)
  fog(17, '雾', '🌫️', WeatherCategory.visibility),
  @HiveField(17)
  haze(18, '霾', '😷', WeatherCategory.visibility),
  @HiveField(18)
  dust(19, '沙尘', '💨', WeatherCategory.visibility),
  @HiveField(19)
  sandstorm(20, '沙尘暴', '💨', WeatherCategory.visibility),
  
  // 风力
  @HiveField(20)
  breeze(21, '微风', '🍃', WeatherCategory.wind),
  @HiveField(21)
  windy(22, '大风', '💨', WeatherCategory.wind),
  
  // 极端天气
  @HiveField(22)
  typhoon(23, '台风', '🌀', WeatherCategory.extreme),
  @HiveField(23)
  hurricane(24, '飓风', '🌀', WeatherCategory.extreme),
  @HiveField(24)
  tornado(25, '龙卷风', '🌪️', WeatherCategory.extreme);

  final int value;
  final String label;
  final String icon;
  final WeatherCategory category;
  
  const Weather(this.value, this.label, this.icon, this.category);
}

/// 天气分类
enum WeatherCategory {
  sky('天空状况', '☁️'),
  precipitation('降水', '🌧️'),
  visibility('能见度', '🌫️'),
  wind('风力', '💨'),
  extreme('极端天气', '⚠️');

  final String label;
  final String icon;
  
  const WeatherCategory(this.label, this.icon);
}

/// 登录方式
@HiveType(typeId: 17)
enum AuthProvider {
  @HiveField(0)
  email('email', '邮箱'),
  @HiveField(1)
  phone('phone', '手机号'),
  @HiveField(2)
  apple('apple', 'Apple ID'),
  @HiveField(3)
  google('google', 'Google'),
  @HiveField(4)
  wechat('wechat', '微信');

  final String value;
  final String label;
  
  const AuthProvider(this.value, this.label);
}

/// 会员等级
@HiveType(typeId: 18)
enum MembershipTier {
  @HiveField(0)
  free(1, '免费版'),
  @HiveField(1)
  premium(2, '会员版');

  final int value;
  final String label;
  
  const MembershipTier(this.value, this.label);
}

/// 会员状态
@HiveType(typeId: 19)
enum MembershipStatus {
  @HiveField(0)
  inactive(1, '未激活'),
  @HiveField(1)
  active(2, '活跃'),
  @HiveField(2)
  expired(3, '已过期'),
  @HiveField(3)
  cancelled(4, '已取消');

  final int value;
  final String label;
  
  const MembershipStatus(this.value, this.label);
}

/// 支付方式
@HiveType(typeId: 20)
enum PaymentMethod {
  @HiveField(0)
  free('free', '免费解锁'),
  @HiveField(1)
  applePay('apple_pay', 'Apple Pay'),
  @HiveField(2)
  googlePay('google_pay', 'Google Pay'),
  @HiveField(3)
  alipay('alipay', '支付宝'),
  @HiveField(4)
  wechatPay('wechat_pay', '微信支付');

  final String value;
  final String label;
  
  const PaymentMethod(this.value, this.label);
}

/// 支付状态
@HiveType(typeId: 21)
enum PaymentStatus {
  @HiveField(0)
  pending(1, '待支付'),
  @HiveField(1)
  processing(2, '处理中'),
  @HiveField(2)
  success(3, '支付成功'),
  @HiveField(3)
  failed(4, '支付失败'),
  @HiveField(4)
  refunded(5, '已退款');

  final int value;
  final String label;
  
  const PaymentStatus(this.value, this.label);
}

/// 应用主题选项（用户偏好设置）
@HiveType(typeId: 22)
enum ThemeOption {
  @HiveField(0)
  light('light', '浅色', false),
  @HiveField(1)
  dark('dark', '深色', false),
  @HiveField(2)
  system('system', '跟随系统', false),
  @HiveField(3)
  misty('misty', '朦胧', true),
  @HiveField(4)
  midnight('midnight', '深夜', true),
  @HiveField(5)
  warm('warm', '温暖', true),
  @HiveField(6)
  autumn('autumn', '秋日', true);

  final String value;
  final String label;
  final bool isPremium;
  
  const ThemeOption(this.value, this.label, this.isPremium);
}

/// 页面切换动画类型
@HiveType(typeId: 24)
enum PageTransitionType {
  @HiveField(0)
  none('none', '无动画', '🚫'),
  @HiveField(1)
  random('random', '随机动画', '🎲'),
  @HiveField(2)
  slideFromRight('slide_from_right', '从右滑入', '⬅️'),
  @HiveField(3)
  slideFromBottom('slide_from_bottom', '从底部滑入', '⬆️'),
  @HiveField(4)
  slideFromLeft('slide_from_left', '从左滑入', '➡️'),
  @HiveField(5)
  slideFromTop('slide_from_top', '从顶部滑入', '⬇️'),
  @HiveField(6)
  fade('fade', '淡入淡出', '✨'),
  @HiveField(7)
  scale('scale', '缩放', '🔍'),
  @HiveField(8)
  rotation('rotation', '旋转', '🔄');

  final String value;
  final String label;
  final String icon;
  
  const PageTransitionType(this.value, this.label, this.icon);
}

/// 对话框动画类型
@HiveType(typeId: 25)
enum DialogAnimationType {
  @HiveField(0)
  none('none', '无动画', '🚫'),
  @HiveField(1)
  random('random', '随机动画', '🎲'),
  @HiveField(2)
  fade('fade', '淡入', '✨'),
  @HiveField(3)
  scale('scale', '缩放', '🔍'),
  @HiveField(4)
  slideUp('slide_up', '从下滑入', '⬆️'),
  @HiveField(5)
  slideDown('slide_down', '从上滑入', '⬇️'),
  @HiveField(6)
  slideLeft('slide_left', '从右滑入', '⬅️'),
  @HiveField(7)
  slideRight('slide_right', '从左滑入', '➡️'),
  @HiveField(8)
  fadeScale('fade_scale', '淡入+缩放', '💫'),
  @HiveField(9)
  fadeSlide('fade_slide', '淡入+滑动', '🌟');

  final String value;
  final String label;
  final String icon;
  
  const DialogAnimationType(this.value, this.label, this.icon);
}

