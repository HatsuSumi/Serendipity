/**
 * 手动测试脚本 - 成就解锁同步 API
 * 运行方式: node scripts/test-achievement-unlock-manual.js
 */

const BASE_URL = 'http://localhost:3000/api';

// 测试数据存储
const testData = {
  email: `test${Date.now()}@example.com`,
  password: 'password123',
  accessToken: '',
  userId: '',
  achievements: [
    { id: 'first_met', unlockedAt: new Date('2024-01-01T10:00:00Z').toISOString() },
    { id: 'social_butterfly', unlockedAt: new Date('2024-01-02T15:30:00Z').toISOString() },
    { id: 'check_in_7_days', unlockedAt: new Date('2024-01-03T20:00:00Z').toISOString() }
  ]
};

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSuccess(message) {
  log(`✅ ${message}`, 'green');
}

function logError(message) {
  log(`❌ ${message}`, 'red');
}

function logInfo(message) {
  log(`ℹ️  ${message}`, 'cyan');
}

function logWarning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

function logSection(message) {
  log(`\n${'='.repeat(60)}`, 'blue');
  log(`  ${message}`, 'blue');
  log(`${'='.repeat(60)}`, 'blue');
}

// HTTP 请求封装
async function request(method, path, body = null, headers = {}) {
  const url = `${BASE_URL}${path}`;
  
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...headers
    }
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  logInfo(`${method} ${path}`);
  
  try {
    const response = await fetch(url, options);
    const data = await response.json();
    
    if (response.ok) {
      logSuccess(`状态码: ${response.status}`);
      return { success: true, data, status: response.status };
    } else {
      logWarning(`状态码: ${response.status}`);
      return { success: false, data, status: response.status };
    }
  } catch (error) {
    logError(`请求失败: ${error.message}`);
    return { success: false, error: error.message };
  }
}

// 准备工作：注册并登录
async function setupUser() {
  logSection('准备工作: 注册并登录测试用户');
  
  // 注册
  logInfo('步骤 1: 注册用户');
  const registerResult = await request('POST', '/auth/register/email', {
    email: testData.email,
    password: testData.password
  });

  if (!registerResult.success) {
    logError('注册失败');
    console.log(JSON.stringify(registerResult.data, null, 2));
    return false;
  }

  const { user, tokens } = registerResult.data.data;
  testData.userId = user.id;
  testData.accessToken = tokens.accessToken;

  logSuccess(`✓ 用户注册成功`);
  log(`📧 邮箱: ${testData.email}`, 'cyan');
  log(`👤 用户 ID: ${testData.userId}`, 'cyan');

  return true;
}

// 测试场景 1: 上传单个成就解锁记录
async function testUploadSingleAchievement() {
  logSection('测试场景 1: 上传单个成就解锁记录');
  
  const achievement = testData.achievements[0];
  
  const result = await request('POST', '/achievement-unlocks', {
    userId: testData.userId,
    achievementId: achievement.id,
    unlockedAt: achievement.unlockedAt
  }, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result.success) {
    logError('上传失败');
    console.log(JSON.stringify(result.data, null, 2));
    return false;
  }

  logSuccess('✓ 成就解锁记录上传成功');
  log(`   成就 ID: ${achievement.id}`, 'cyan');
  log(`   解锁时间: ${achievement.unlockedAt}`, 'cyan');

  return true;
}

// 测试场景 2: 下载成就解锁记录
async function testDownloadAchievements() {
  logSection('测试场景 2: 下载成就解锁记录');
  
  const result = await request('GET', `/achievement-unlocks?userId=${testData.userId}`, null, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result.success) {
    logError('下载失败');
    console.log(JSON.stringify(result.data, null, 2));
    return false;
  }

  const { unlocks } = result.data.data;

  logSuccess(`✓ 下载成功，共 ${unlocks.length} 条记录`);

  if (unlocks.length !== 1) {
    logError(`✗ 预期 1 条记录，实际 ${unlocks.length} 条`);
    return false;
  }

  const unlock = unlocks[0];
  const expected = testData.achievements[0];

  if (unlock.achievementId === expected.id && unlock.unlockedAt === expected.unlockedAt) {
    logSuccess('✓ 数据一致性验证通过');
    log(`   成就 ID: ${unlock.achievementId}`, 'cyan');
    log(`   解锁时间: ${unlock.unlockedAt}`, 'cyan');
  } else {
    logError('✗ 数据不一致');
    console.log('预期:', expected);
    console.log('实际:', unlock);
    return false;
  }

  return true;
}

// 测试场景 3: 批量上传成就解锁记录
async function testBatchUploadAchievements() {
  logSection('测试场景 3: 批量上传成就解锁记录');
  
  // 上传剩余的两个成就
  for (let i = 1; i < testData.achievements.length; i++) {
    const achievement = testData.achievements[i];
    
    logInfo(`上传成就 ${i + 1}/${testData.achievements.length}: ${achievement.id}`);
    
    const result = await request('POST', '/achievement-unlocks', {
      userId: testData.userId,
      achievementId: achievement.id,
      unlockedAt: achievement.unlockedAt
    }, {
      'Authorization': `Bearer ${testData.accessToken}`
    });

    if (!result.success) {
      logError(`上传失败: ${achievement.id}`);
      return false;
    }

    logSuccess(`✓ ${achievement.id} 上传成功`);
    
    // 避免请求太快
    await new Promise(resolve => setTimeout(resolve, 200));
  }

  logSuccess(`✓ 批量上传完成，共 ${testData.achievements.length - 1} 条新记录`);

  return true;
}

// 测试场景 4: 验证批量上传结果
async function testVerifyBatchUpload() {
  logSection('测试场景 4: 验证批量上传结果');
  
  const result = await request('GET', `/achievement-unlocks?userId=${testData.userId}`, null, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result.success) {
    logError('下载失败');
    return false;
  }

  const { unlocks } = result.data.data;

  logSuccess(`✓ 下载成功，共 ${unlocks.length} 条记录`);

  if (unlocks.length !== testData.achievements.length) {
    logError(`✗ 预期 ${testData.achievements.length} 条记录，实际 ${unlocks.length} 条`);
    return false;
  }

  // 验证每条记录
  logInfo('验证数据完整性:');
  for (const expected of testData.achievements) {
    const found = unlocks.find(u => u.achievementId === expected.id);
    if (found && found.unlockedAt === expected.unlockedAt) {
      logSuccess(`✓ ${expected.id} - 数据一致`);
    } else {
      logError(`✗ ${expected.id} - 数据不一致或缺失`);
      return false;
    }
  }

  return true;
}

// 测试场景 5: 幂等性测试（重复上传）
async function testIdempotency() {
  logSection('测试场景 5: 幂等性测试（重复上传同一成就）');
  
  const achievement = testData.achievements[0];
  const newUnlockedAt = new Date('2024-12-31T23:59:59Z').toISOString();
  
  logInfo('步骤 1: 记录原始解锁时间');
  log(`   原始时间: ${achievement.unlockedAt}`, 'cyan');
  
  logInfo('\n步骤 2: 用不同的解锁时间重复上传');
  log(`   新时间: ${newUnlockedAt}`, 'cyan');
  
  const result = await request('POST', '/achievement-unlocks', {
    userId: testData.userId,
    achievementId: achievement.id,
    unlockedAt: newUnlockedAt
  }, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result.success) {
    logError('重复上传失败');
    return false;
  }

  logSuccess('✓ 重复上传成功（服务器接受请求）');

  logInfo('\n步骤 3: 验证解锁时间是否保持不变');
  
  const downloadResult = await request('GET', `/achievement-unlocks?userId=${testData.userId}`, null, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!downloadResult.success) {
    logError('下载失败');
    return false;
  }

  const unlock = downloadResult.data.data.unlocks.find(u => u.achievementId === achievement.id);
  
  if (!unlock) {
    logError('✗ 找不到成就记录');
    return false;
  }

  log(`   当前时间: ${unlock.unlockedAt}`, 'cyan');

  if (unlock.unlockedAt === achievement.unlockedAt) {
    logSuccess('✓ 幂等性验证通过：解锁时间保持不变');
    logSuccess('✓ 重复上传不会覆盖原有数据');
  } else {
    logError('✗ 幂等性验证失败：解锁时间被修改');
    log(`   预期: ${achievement.unlockedAt}`, 'red');
    log(`   实际: ${unlock.unlockedAt}`, 'red');
    return false;
  }

  return true;
}

// 测试场景 6: 参数验证（Fail Fast）
async function testFailFast() {
  logSection('测试场景 6: 参数验证（Fail Fast）');
  
  // 测试 6.1: 缺少 userId
  logInfo('测试 6.1: 缺少 userId');
  const result1 = await request('POST', '/achievement-unlocks', {
    achievementId: 'test_achievement',
    unlockedAt: new Date().toISOString()
  }, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result1.success && result1.status === 400) {
    logSuccess('✓ 缺少 userId 时返回 400');
  } else {
    logError('✗ 应该返回 400 错误');
    return false;
  }

  // 测试 6.2: 缺少 achievementId
  logInfo('\n测试 6.2: 缺少 achievementId');
  const result2 = await request('POST', '/achievement-unlocks', {
    userId: testData.userId,
    unlockedAt: new Date().toISOString()
  }, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result2.success && result2.status === 400) {
    logSuccess('✓ 缺少 achievementId 时返回 400');
  } else {
    logError('✗ 应该返回 400 错误');
    return false;
  }

  // 测试 6.3: 缺少 unlockedAt
  logInfo('\n测试 6.3: 缺少 unlockedAt');
  const result3 = await request('POST', '/achievement-unlocks', {
    userId: testData.userId,
    achievementId: 'test_achievement'
  }, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result3.success && result3.status === 400) {
    logSuccess('✓ 缺少 unlockedAt 时返回 400');
  } else {
    logError('✗ 应该返回 400 错误');
    return false;
  }

  // 测试 6.4: 下载时缺少 userId
  logInfo('\n测试 6.4: 下载时缺少 userId');
  const result4 = await request('GET', '/achievement-unlocks', null, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result4.success && result4.status === 400) {
    logSuccess('✓ 下载时缺少 userId 返回 400');
  } else {
    logError('✗ 应该返回 400 错误');
    return false;
  }

  logSuccess('\n✓ Fail Fast 原则验证通过');

  return true;
}

// 测试场景 7: 模拟设备同步场景
async function testDeviceSyncScenario() {
  logSection('测试场景 7: 模拟设备同步场景');
  
  logInfo('场景说明:');
  log('  设备 A: 已上传 3 个成就', 'cyan');
  log('  设备 B: 新登录，下载成就列表', 'cyan');
  log('  预期: 设备 B 能获取到所有 3 个成就', 'cyan');
  
  logInfo('\n模拟设备 B 登录并下载成就:');
  
  const result = await request('GET', `/achievement-unlocks?userId=${testData.userId}`, null, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result.success) {
    logError('设备 B 下载失败');
    return false;
  }

  const { unlocks } = result.data.data;

  logSuccess(`✓ 设备 B 成功下载 ${unlocks.length} 个成就`);

  if (unlocks.length === testData.achievements.length) {
    logSuccess('✓ 设备同步场景验证通过');
    logInfo('设备 B 可以静默解锁这些成就（不弹通知）');
  } else {
    logError(`✗ 预期 ${testData.achievements.length} 个成就，实际 ${unlocks.length} 个`);
    return false;
  }

  return true;
}

// 主测试流程
async function runAllTests() {
  log('\n🚀 开始测试成就解锁同步 API', 'blue');
  log(`📍 服务器地址: ${BASE_URL}\n`, 'cyan');

  const tests = [
    { name: '准备工作: 注册并登录', fn: setupUser },
    { name: '场景 1: 上传单个成就', fn: testUploadSingleAchievement },
    { name: '场景 2: 下载成就记录', fn: testDownloadAchievements },
    { name: '场景 3: 批量上传成就', fn: testBatchUploadAchievements },
    { name: '场景 4: 验证批量上传', fn: testVerifyBatchUpload },
    { name: '场景 5: 幂等性测试', fn: testIdempotency },
    { name: '场景 6: 参数验证', fn: testFailFast },
    { name: '场景 7: 设备同步场景', fn: testDeviceSyncScenario }
  ];

  const results = [];

  for (const test of tests) {
    try {
      const passed = await test.fn();
      results.push({ name: test.name, passed });
      
      if (!passed) {
        logError(`\n❌ ${test.name} 失败，停止后续测试\n`);
        break;
      }
      
      // 等待一下，避免请求太快
      await new Promise(resolve => setTimeout(resolve, 500));
    } catch (error) {
      logError(`\n❌ ${test.name} 抛出异常: ${error.message}\n`);
      console.error(error);
      results.push({ name: test.name, passed: false, error: error.message });
      break;
    }
  }

  // 测试总结
  logSection('测试总结');
  
  const passed = results.filter(r => r.passed).length;
  const total = results.length;
  
  results.forEach(result => {
    if (result.passed) {
      logSuccess(`✓ ${result.name}`);
    } else {
      logError(`✗ ${result.name}`);
      if (result.error) {
        log(`  错误: ${result.error}`, 'red');
      }
    }
  });

  log(`\n📊 测试结果: ${passed}/${total} 通过`, passed === total ? 'green' : 'red');

  if (passed === total) {
    log('\n🎉 所有测试通过！成就解锁同步功能正常！\n', 'green');
    log('✅ 验证通过的功能:', 'green');
    log('  - 上传成就解锁记录', 'cyan');
    log('  - 下载成就解锁记录', 'cyan');
    log('  - 批量上传', 'cyan');
    log('  - 数据一致性', 'cyan');
    log('  - 幂等性（重复上传不覆盖）', 'cyan');
    log('  - Fail Fast 参数验证', 'cyan');
    log('  - 设备同步场景', 'cyan');
  } else {
    log('\n⚠️  部分测试失败，请检查服务器日志\n', 'yellow');
  }
}

// 检查服务器是否运行
async function checkServer() {
  logInfo('检查服务器是否运行...');
  
  try {
    const response = await fetch(`${BASE_URL}/health`);
    if (response.ok) {
      logSuccess('服务器正在运行');
      return true;
    }
  } catch (error) {
    logError('无法连接到服务器');
    logInfo('请确保服务器正在运行: npm run dev');
    return false;
  }
}

// 启动测试
(async () => {
  const serverRunning = await checkServer();
  
  if (!serverRunning) {
    log('\n❌ 测试终止：服务器未运行\n', 'red');
    process.exit(1);
  }

  await runAllTests();
})();

