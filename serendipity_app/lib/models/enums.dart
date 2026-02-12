/// 记录状态
enum EncounterStatus {
  missed(1, '错过', '🌫️'),
  reencounter(2, '再遇', '🌟'),
  met(3, '邂逅', '💫'),
  reunion(4, '重逢', '💝'),
  farewell(5, '别离', '🥀'),
  lost(6, '失联', '🍂');

  final int value;
  final String label;
  final String icon;
  
  const EncounterStatus(this.value, this.label, this.icon);
}

/// 情绪强度
enum EmotionIntensity {
  barelyFelt(1, '几乎没感觉'),
  slightlyCared(2, '有点在意'),
  thoughtOnWayHome(3, '回家后还在想'),
  allNight(4, '想了一整晚'),
  untilNow(5, '至今难忘');

  final int value;
  final String label;
  
  const EmotionIntensity(this.value, this.label);
}

/// 场所类型
enum PlaceType {
  // 交通
  subway('subway', '地铁', '🚇'),
  bus('bus', '公交', '🚌'),
  train('train', '火车站', '🚄'),
  airport('airport', '机场', '✈️'),
  
  // 餐饮
  coffeeShop('coffee_shop', '咖啡馆', '☕'),
  restaurant('restaurant', '餐厅', '🍽️'),
  bar('bar', '酒吧', '🍺'),
  teaHouse('tea_house', '茶馆', '🍵'),
  dessertShop('dessert_shop', '甜品店', '🍰'),
  
  // 购物
  mall('mall', '商场', '🛍️'),
  supermarket('supermarket', '超市', '🛒'),
  bookstore('bookstore', '书店', '📚'),
  
  // 休闲娱乐
  park('park', '公园', '🌳'),
  cinema('cinema', '电影院', '🎬'),
  museum('museum', '博物馆', '🏛️'),
  artGallery('art_gallery', '美术馆', '🎨'),
  aquarium('aquarium', '水族馆', '🐠'),
  zoo('zoo', '动物园', '🦁'),
  amusementPark('amusement_park', '游乐园', '🎡'),
  
  // 运动健身
  gym('gym', '健身房', '💪'),
  swimmingPool('swimming_pool', '游泳馆', '🏊'),
  stadium('stadium', '体育馆', '🏟️'),
  
  // 学习工作
  library('library', '图书馆', '📖'),
  school('school', '学校', '🎓'),
  office('office', '办公楼', '🏢'),
  
  // 医疗健康
  hospital('hospital', '医院', '🏥'),
  clinic('clinic', '诊所', '⚕️'),
  
  // 其他
  hotel('hotel', '酒店', '🏨'),
  beach('beach', '海滩', '🏖️'),
  mountain('mountain', '山/景区', '⛰️'),
  street('street', '街道', '🛣️'),
  other('other', '其他', '📍');

  final String value;
  final String label;
  final String icon;
  
  const PlaceType(this.value, this.label, this.icon);
}

/// 天气类型
enum Weather {
  // 天空状况
  sunny(1, '晴天', '☀️'),
  cloudy(2, '多云', '⛅'),
  overcast(3, '阴天', '☁️'),
  
  // 降水类 - 雨
  drizzle(4, '毛毛雨', '🌦️'),
  lightRain(5, '小雨', '🌦️'),
  moderateRain(6, '中雨', '🌧️'),
  heavyRain(7, '大雨', '🌧️'),
  rainstorm(8, '暴雨', '⛈️'),
  freezingRain(9, '冻雨', '🧊'),
  
  // 降水类 - 雪
  lightSnow(10, '小雪', '🌨️'),
  moderateSnow(11, '中雪', '❄️'),
  heavySnow(12, '大雪', '❄️'),
  snowstorm(13, '暴雪', '❄️'),
  
  // 降水类 - 其他
  sleet(14, '雨夹雪', '🌨️'),
  hail(15, '冰雹', '🧊'),
  
  // 能见度
  mist(16, '轻雾', '🌫️'),
  fog(17, '雾', '🌫️'),
  haze(18, '霾', '😷'),
  dust(19, '沙尘', '💨'),
  sandstorm(20, '沙尘暴', '💨'),
  
  // 风力
  breeze(21, '微风', '🍃'),
  windy(22, '大风', '💨'),
  
  // 极端天气
  typhoon(23, '台风', '🌀'),
  hurricane(24, '飓风', '🌀'),
  tornado(25, '龙卷风', '🌪️');

  final int value;
  final String label;
  final String icon;
  
  const Weather(this.value, this.label, this.icon);
}

/// 匹配状态
enum MatchStatus {
  pending(1, '等待冷静期'),
  notified(2, '已通知'),
  verifying(3, '验证中'),
  verified(4, '验证成功'),
  rejected(5, '验证失败'),
  expired(6, '已过期');

  final int value;
  final String label;
  
  const MatchStatus(this.value, this.label);
}

/// 匹配置信度
enum MatchConfidence {
  high(1, '高置信度'),
  medium(2, '中置信度'),
  low(3, '低置信度');

  final int value;
  final String label;
  
  const MatchConfidence(this.value, this.label);
}

/// 验证选择
enum VerificationChoice {
  wantContact(1, '想要联系'),
  keepInMemory(2, '留在记忆里'),
  notMe(3, '不是我，认错人了');

  final int value;
  final String label;
  
  const VerificationChoice(this.value, this.label);
}

/// 登录方式
enum AuthProvider {
  email('email', '邮箱'),
  phone('phone', '手机号'),
  apple('apple', 'Apple ID'),
  google('google', 'Google'),
  wechat('wechat', '微信');

  final String value;
  final String label;
  
  const AuthProvider(this.value, this.label);
}

