import prisma from '../src/utils/prisma';
import * as fs from 'fs';
import * as path from 'path';

interface TestPost {
  id: string;
  recordId: string;
  timestamp: string;
  address?: string;
  placeName: string | null;
  placeType: string;
  province?: string;
  city?: string;
  area?: string;
  status: string;
  description: string | null;
  tags: Array<{ tag: string; note?: string }>;
  publishedAt: string;
  createdAt: string;
  updatedAt: string;
}

async function importTestPosts() {
  try {
    console.log('开始导入测试数据...');

    // 1. 清空旧的测试数据
    console.log('清空旧的测试数据...');
    const deleteResult = await prisma.communityPost.deleteMany({});
    console.log(`✅ 已删除 ${deleteResult.count} 条旧数据`);

    // 2. 创建或获取测试用户
    const testUserId = 'test_user_community';
    let testUser = await prisma.user.findUnique({
      where: { id: testUserId },
    });

    if (!testUser) {
      console.log('创建测试用户...');
      testUser = await prisma.user.create({
        data: {
          id: testUserId,
          email: 'test_community@example.com',
          displayName: '测试用户',
          passwordHash: 'dummy_hash', // 假密码，不会用于登录
        },
      });
      console.log('✅ 测试用户已创建');
    } else {
      console.log('✅ 测试用户已存在');
    }

    // 读取测试数据文件
    const testDataPath = path.join(
      __dirname,
      '../../serendipity_app/test/test_posts.json'
    );
    const testData = JSON.parse(
      fs.readFileSync(testDataPath, 'utf-8')
    ) as TestPost[];

    console.log(`读取到 ${testData.length} 条测试数据`);

    // 批量插入
    let successCount = 0;
    let errorCount = 0;

    for (const post of testData) {
      try {
        await prisma.communityPost.create({
          data: {
            id: post.id,
            userId: testUserId, // 使用统一的测试用户ID
            recordId: post.recordId,
            timestamp: new Date(post.timestamp),
            address: post.address || null,
            placeName: post.placeName,
            placeType: post.placeType,
            province: post.province || null,
            city: post.city || null,
            area: post.area || null,
            description: post.description,
            tags: post.tags,
            status: post.status,
            publishedAt: new Date(post.publishedAt),
            createdAt: new Date(post.createdAt),
            updatedAt: new Date(post.updatedAt),
          },
        });
        successCount++;

        if (successCount % 50 === 0) {
          console.log(`已导入 ${successCount} 条...`);
        }
      } catch (error) {
        errorCount++;
        console.error(`导入失败 (${post.id}):`, error);
      }
    }

    console.log('\n✅ 导入完成！');
    console.log(`成功: ${successCount} 条`);
    console.log(`失败: ${errorCount} 条`);
  } catch (error) {
    console.error('❌ 导入失败:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// 运行导入
importTestPosts();

