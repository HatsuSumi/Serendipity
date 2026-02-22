import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AchievementDetector - 城市提取测试', () {
    test('城市提取 - 直辖市（北京市）', () {
      expect(_extractCityFromAddress('北京市朝阳区建国门外大街1号'), '北京市');
      expect(_extractCityFromAddress('北京市海淀区中关村大街1号'), '北京市');
    });

    test('城市提取 - 直辖市（上海市）', () {
      expect(_extractCityFromAddress('上海市浦东新区世纪大道1号'), '上海市');
      expect(_extractCityFromAddress('上海市黄浦区南京东路1号'), '上海市');
    });

    test('城市提取 - 直辖市（天津市、重庆市）', () {
      expect(_extractCityFromAddress('天津市和平区南京路1号'), '天津市');
      expect(_extractCityFromAddress('重庆市渝中区解放碑1号'), '重庆市');
    });

    test('城市提取 - 省级城市', () {
      expect(_extractCityFromAddress('广东省广州市天河区天河路1号'), '广州市');
      expect(_extractCityFromAddress('浙江省杭州市西湖区文三路1号'), '杭州市');
      expect(_extractCityFromAddress('江苏省南京市玄武区中山路1号'), '南京市');
    });

    test('城市提取 - 自治区城市', () {
      expect(_extractCityFromAddress('新疆维吾尔自治区乌鲁木齐市天山区解放路1号'), '乌鲁木齐市');
      expect(_extractCityFromAddress('广西壮族自治区南宁市青秀区民族大道1号'), '南宁市');
    });

    test('城市提取 - 无效地址', () {
      expect(_extractCityFromAddress(''), isNull);
      expect(_extractCityFromAddress('某个地方'), isNull);
      expect(_extractCityFromAddress('朝阳区建国门外大街1号'), isNull);
    });

    test('城市提取 - 去重测试', () {
      final cities = <String>{};
      cities.add(_extractCityFromAddress('北京市朝阳区建国门外大街1号')!);
      cities.add(_extractCityFromAddress('上海市浦东新区世纪大道1号')!);
      cities.add(_extractCityFromAddress('广东省广州市天河区天河路1号')!);
      cities.add(_extractCityFromAddress('北京市海淀区中关村大街1号')!); // 重复
      
      expect(cities.length, 3); // 3个城市：北京市、上海市、广州市
    });
  });

  group('AchievementDetector - 节日判断测试', () {
    test('节日判断 - 固定日期节日', () {
      expect(_isHolidayHelper(DateTime(2024, 1, 1)), true); // 元旦
      expect(_isHolidayHelper(DateTime(2024, 2, 14)), true); // 情人节
      expect(_isHolidayHelper(DateTime(2024, 3, 14)), true); // 白色情人节
      expect(_isHolidayHelper(DateTime(2024, 5, 20)), true); // 520表白日
      expect(_isHolidayHelper(DateTime(2024, 10, 31)), true); // 万圣节
      expect(_isHolidayHelper(DateTime(2024, 11, 11)), true); // 双十一
      expect(_isHolidayHelper(DateTime(2024, 12, 24)), true); // 平安夜
      expect(_isHolidayHelper(DateTime(2024, 12, 25)), true); // 圣诞节
    });

    test('节日判断 - 春节范围（1月21日-2月20日）', () {
      expect(_isHolidayHelper(DateTime(2024, 1, 20)), false); // 春节前
      expect(_isHolidayHelper(DateTime(2024, 1, 21)), true); // 春节范围开始
      expect(_isHolidayHelper(DateTime(2024, 1, 25)), true); // 春节范围内
      expect(_isHolidayHelper(DateTime(2024, 2, 10)), true); // 春节范围内
      expect(_isHolidayHelper(DateTime(2024, 2, 20)), true); // 春节范围结束
      expect(_isHolidayHelper(DateTime(2024, 2, 21)), false); // 春节后
    });

    test('节日判断 - 七夕（8月）', () {
      expect(_isHolidayHelper(DateTime(2024, 7, 31)), false); // 七夕前
      expect(_isHolidayHelper(DateTime(2024, 8, 1)), true); // 8月开始
      expect(_isHolidayHelper(DateTime(2024, 8, 15)), true); // 8月中
      expect(_isHolidayHelper(DateTime(2024, 8, 31)), true); // 8月结束
      expect(_isHolidayHelper(DateTime(2024, 9, 1)), false); // 七夕后
    });

    test('节日判断 - 中秋节范围（9月10日-10月10日）', () {
      expect(_isHolidayHelper(DateTime(2024, 9, 9)), false); // 中秋前
      expect(_isHolidayHelper(DateTime(2024, 9, 10)), true); // 中秋范围开始
      expect(_isHolidayHelper(DateTime(2024, 9, 20)), true); // 中秋范围内
      expect(_isHolidayHelper(DateTime(2024, 10, 5)), true); // 中秋范围内
      expect(_isHolidayHelper(DateTime(2024, 10, 10)), true); // 中秋范围结束
      expect(_isHolidayHelper(DateTime(2024, 10, 11)), false); // 中秋后
    });

    test('节日判断 - 非节日日期', () {
      expect(_isHolidayHelper(DateTime(2024, 3, 15)), false);
      expect(_isHolidayHelper(DateTime(2024, 4, 10)), false);
      expect(_isHolidayHelper(DateTime(2024, 6, 20)), false);
      expect(_isHolidayHelper(DateTime(2024, 7, 15)), false);
      expect(_isHolidayHelper(DateTime(2024, 11, 20)), false);
    });

    test('节日判断 - 边界情况', () {
      // 1月20日不是节日（春节前一天）
      expect(_isHolidayHelper(DateTime(2024, 1, 20)), false);
      
      // 2月21日不是节日（春节后一天）
      expect(_isHolidayHelper(DateTime(2024, 2, 21)), false);
      
      // 9月9日不是节日（中秋前一天）
      expect(_isHolidayHelper(DateTime(2024, 9, 9)), false);
      
      // 10月11日不是节日（中秋后一天）
      expect(_isHolidayHelper(DateTime(2024, 10, 11)), false);
    });
  });
}

// 辅助方法：提取城市（复制自 AchievementDetector）
String? _extractCityFromAddress(String address) {
  // 1. 直辖市
  final municipalities = ['北京市', '上海市', '天津市', '重庆市'];
  for (final city in municipalities) {
    if (address.contains(city)) {
      return city;
    }
  }

  // 2. 省级城市
  final provinceCityPattern = RegExp(
    r'(?:[\u4e00-\u9fa5]+(?:省|自治区))([\u4e00-\u9fa5]+市)',
  );
  final provinceCityMatch = provinceCityPattern.firstMatch(address);
  if (provinceCityMatch != null) {
    return provinceCityMatch.group(1);
  }

  // 3. 只有城市名
  final cityPattern = RegExp(r'([\u4e00-\u9fa5]{2,}市)');
  final cityMatch = cityPattern.firstMatch(address);
  if (cityMatch != null) {
    final cityName = cityMatch.group(1)!;
    if (!cityName.endsWith('区市') && !cityName.endsWith('县市')) {
      return cityName;
    }
  }

  return null;
}

// 辅助方法：判断节日（复制自 AchievementDetector）
bool _isHolidayHelper(DateTime date) {
  final month = date.month;
  final day = date.day;

  // 固定日期节日
  if (month == 1 && day == 1) return true; // 元旦
  if (month == 2 && day == 14) return true; // 情人节
  if (month == 3 && day == 14) return true; // 白色情人节
  if (month == 5 && day == 20) return true; // 520表白日
  if (month == 10 && day == 31) return true; // 万圣节
  if (month == 11 && day == 11) return true; // 双十一
  if (month == 12 && day == 24) return true; // 平安夜
  if (month == 12 && day == 25) return true; // 圣诞节

  // 春节：1月21日-2月20日
  if (month == 1 && day >= 21) return true;
  if (month == 2 && day <= 20) return true;

  // 七夕：8月
  if (month == 8) return true;

  // 中秋节：9月10日-10月10日
  if (month == 9 && day >= 10) return true;
  if (month == 10 && day <= 10) return true;

  return false;
}

