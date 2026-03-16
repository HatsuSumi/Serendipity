/**
 * 地址工具类
 * 
 * 提供地址相关的解析功能：
 * - 从地址字符串中提取省市区信息
 * 
 * 设计原则：
 * - 与前端 AddressHelper 逻辑一致
 * - 无状态：所有方法都是静态的
 * - Fail Fast：参数非法返回 null，不抛异常
 */
export class AddressHelper {
  /**
   * 从地址字符串中提取省市区信息
   * 
   * 支持的格式：
   * - "北京市朝阳区..." -> { province: null, city: "北京市", area: "朝阳区" }
   * - "上海市浦东新区..." -> { province: null, city: "上海市", area: "浦东新区" }
   * - "广东省深圳市南山区..." -> { province: "广东省", city: "深圳市", area: "南山区" }
   * - "江苏省南京市玄武区..." -> { province: "江苏省", city: "南京市", area: "玄武区" }
   * 
   * @param address - 地址字符串
   * @returns 包含 province、city、area 的对象，无法提取则返回空对象
   */
  static extractRegion(address: string | null | undefined): {
    province?: string;
    city?: string;
    area?: string;
  } {
    // Fail Fast：地址为空，返回空对象
    if (!address || address.trim() === '') {
      return {};
    }

    let province: string | undefined;
    let city: string | undefined;
    let area: string | undefined;

    // 1. 提取省份（如果有）
    const provinceMatch = address.match(/^(.+?省)/);
    if (provinceMatch) {
      province = provinceMatch[1];
    }

    // 2. 提取城市
    // 如果有省份，从省份后面开始查找市
    const cityStartIndex = province ? province.length : 0;
    const cityMatch = address.substring(cityStartIndex).match(/(.+?市)/);
    if (cityMatch) {
      city = cityMatch[1];
    }

    // 3. 提取区县
    // 如果有城市，从城市后面开始查找区/县
    if (city) {
      const areaStartIndex = cityStartIndex + city.length;
      if (areaStartIndex < address.length) {
        // 匹配区、县、市（县级市）
        const areaMatch = address.substring(areaStartIndex).match(/(.+?[区县市])/);
        if (areaMatch) {
          area = areaMatch[1];
        }
      }
    }

    return {
      ...(province && { province }),
      ...(city && { city }),
      ...(area && { area }),
    };
  }

  /**
   * 从地址字符串中提取城市名称
   * 
   * @param address - 地址字符串
   * @returns 城市名称，如果无法提取则返回 null
   */
  static extractCity(address: string | null | undefined): string | null {
    const region = this.extractRegion(address);
    return region.city || null;
  }
}

