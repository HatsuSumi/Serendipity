import { IMembershipRepository } from '../repositories/membershipRepository';

/**
 * 同步访问策略服务接口
 * 负责判定当前用户是否允许下载业务主数据。
 */
export interface ISyncAccessPolicyService {
  canDownloadBusinessData(userId: string): Promise<boolean>;
}

/**
 * 默认同步访问策略实现
 *
 * 当前产品规则：
 * - 免费版：只上传，不自动下载业务主数据
 * - 会员版：允许下载业务主数据
 */
export class SyncAccessPolicyService implements ISyncAccessPolicyService {
  constructor(private membershipRepository: IMembershipRepository) {}

  async canDownloadBusinessData(userId: string): Promise<boolean> {
    return this.membershipRepository.isUserPremium(userId);
  }
}

