import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import bcrypt from 'bcrypt';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function seed() {
  try {
    console.log('Starting database seeding...');

    // 创建测试用户
    const passwordHash = await bcrypt.hash('password123', 10);
    
    const user = await prisma.user.create({
      data: {
        email: 'test@example.com',
        passwordHash,
        displayName: '测试用户',
      },
    });

    console.log(`Created test user: ${user.email}`);

    // 创建用户设置
    await prisma.userSettings.create({
      data: {
        userId: user.id,
      },
    });

    console.log('Created user settings');

    // 创建会员记录
    await prisma.membership.create({
      data: {
        userId: user.id,
        tier: 'free',
        status: 'active',
      },
    });

    console.log('Created membership');

    // 创建测试记录
    const record = await prisma.record.create({
      data: {
        id: '550e8400-e29b-41d4-a716-446655440000',
        userId: user.id,
        timestamp: new Date('2026-02-25T10:00:00Z'),
        location: {
          latitude: 39.9087,
          longitude: 116.3975,
          address: '北京市朝阳区建国门外大街1号',
          placeName: '常去的咖啡馆',
          placeType: 'coffee_shop',
        },
        description: '她在读《百年孤独》...',
        tags: [
          {
            tag: '长发',
            note: '光线不好，可能是深棕色',
          },
        ],
        emotion: 'thought_all_night',
        status: 'missed',
        weather: ['sunny', 'breeze'],
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    });

    console.log(`Created test record: ${record.id}`);

    // 创建故事线
    const storyLine = await prisma.storyLine.create({
      data: {
        id: '660e8400-e29b-41d4-a716-446655440000',
        userId: user.id,
        name: '地铁上的她',
        recordIds: [record.id],
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    });

    console.log(`Created test story line: ${storyLine.name}`);

    console.log('Database seeding completed successfully!');
  } catch (error) {
    console.error('Error seeding database:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

seed();

