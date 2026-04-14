import { IMembershipRepository } from '../repositories/membershipRepository';

/**
 * 同步访问策略服务接口
 * 负责判定当前用户是否允许下载核心内容主资产。
 */
export interface ISyncAccessPolicyService {
  canDownloadCoreContent(userId: string): Promise<boolean>;
  buildCoreContentScope(userId: string, deviceId: string): Promise<{ userId: string; sourceDeviceId?: string }>;
}

/**
 * 默认同步访问策略实现
 *
 * 当前产品规则：
 * - 免费版：只上传，不自动下载其他设备产生的核心内容主资产
 * - 会员版：允许下载全部核心内容主资产
 */
export class SyncAccessPolicyService implements ISyncAccessPolicyService {
  constructor(private membershipRepository: IMembershipRepository) {}

  async canDownloadCoreContent(userId: string): Promise<boolean> {
    return this.membershipRepository.isUserPremium(userId);
  }

  async buildCoreContentScope(
    userId: string,
    deviceId: string
  ): Promise<{ userId: string; sourceDeviceId?: string }> {
    const isPremium = await this.membershipRepository.isUserPremium(userId);

    if (isPremium) {
      return { userId };
    }

    return {
      userId,
      sourceDeviceId: deviceId,
    };
  }
}

