/**
 * 手动测试脚本 - Phase 1.4 认证 API
 * 运行方式: node scripts/test-auth-manual.js
 */

const BASE_URL = 'http://localhost:3000/api/v1';

// 测试数据存储
const testData = {
  email: `test${Date.now()}@example.com`,
  password: 'password123',
  newPassword: 'newpassword456',
  resetPassword: 'resetpassword789',
  accessToken: '',
  refreshToken: '',
  recoveryKey: '',
  userId: ''
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

// 测试场景 1: 用户注册
async function testRegister() {
  logSection('测试场景 1: 用户注册 (验证 P0-3 恢复密钥生成)');
  
  const result = await request('POST', '/auth/register/email', {
    email: testData.email,
    password: testData.password
  });

  if (!result.success) {
    logError('注册失败');
    console.log(JSON.stringify(result.data, null, 2));
    return false;
  }

  const { user, tokens, recoveryKey } = result.data.data;
  
  // 保存数据
  testData.userId = user.id;
  testData.accessToken = tokens.accessToken;
  testData.refreshToken = tokens.refreshToken;
  testData.recoveryKey = recoveryKey;

  // 验证点
  logInfo('验证点检查:');
  
  if (recoveryKey && /^[a-z0-9]{4}(-[a-z0-9]{4}){7}$/.test(recoveryKey)) {
    logSuccess('✓ 恢复密钥格式正确 (8组4位，用 - 分隔)');
  } else {
    logError('✗ 恢复密钥格式错误');
    return false;
  }

  if (tokens.accessToken && tokens.refreshToken) {
    logSuccess('✓ 返回了 accessToken 和 refreshToken');
  } else {
    logError('✗ Token 缺失');
    return false;
  }

  log(`\n📧 测试邮箱: ${testData.email}`, 'cyan');
  log(`🔑 恢复密钥: ${testData.recoveryKey}`, 'cyan');
  log(`👤 用户 ID: ${testData.userId}`, 'cyan');

  return true;
}

// 测试场景 2.1: 正确登录
async function testLoginSuccess() {
  logSection('测试场景 2.1: 正确的邮箱和密码登录');
  
  const result = await request('POST', '/auth/login/email', {
    email: testData.email,
    password: testData.password
  });

  if (!result.success) {
    logError('登录失败');
    console.log(JSON.stringify(result.data, null, 2));
    return false;
  }

  const { tokens } = result.data.data;
  
  // 更新 Token
  testData.accessToken = tokens.accessToken;
  testData.refreshToken = tokens.refreshToken;

  logSuccess('✓ 登录成功');
  logSuccess('✓ 返回了新的 Token');

  return true;
}

// 测试场景 2.2: 错误密码
async function testLoginWrongPassword() {
  logSection('测试场景 2.2: 错误的密码 (验证 P0-2 登录验证)');
  
  const result = await request('POST', '/auth/login/email', {
    email: testData.email,
    password: 'wrongpassword'
  });

  if (result.success) {
    logError('应该登录失败，但成功了');
    return false;
  }

  if (result.status === 400 || result.status === 401) {
    logSuccess('✓ 返回了正确的错误状态码');
  } else {
    logError(`✗ 错误状态码不正确: ${result.status}`);
    return false;
  }

  if (result.data.error) {
    logSuccess(`✓ 错误信息: ${result.data.error.message || result.data.error}`);
  }

  return true;
}

// 测试场景 2.3: 空密码
async function testLoginEmptyPassword() {
  logSection('测试场景 2.3: 空密码 (验证 P1-2 Fail Fast)');
  
  const result = await request('POST', '/auth/login/email', {
    email: testData.email,
    password: ''
  });

  if (result.success) {
    logError('应该登录失败，但成功了');
    return false;
  }

  if (result.status === 400) {
    logSuccess('✓ Fail Fast 生效，立即返回错误');
  } else {
    logError(`✗ 状态码不正确: ${result.status}`);
    return false;
  }

  if (result.data.error) {
    logSuccess(`✓ 错误信息: ${result.data.error.message || result.data.error}`);
  }

  return true;
}

// 测试场景 3: 修改密码
async function testChangePassword() {
  logSection('测试场景 3: 修改密码 (验证 P0-1 密码哈希)');
  
  // 步骤 1: 修改密码
  logInfo('步骤 1: 修改密码');
  const result = await request('PUT', '/auth/password', {
    currentPassword: testData.password,
    newPassword: testData.newPassword
  }, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result.success) {
    logError('修改密码失败');
    console.log(JSON.stringify(result.data, null, 2));
    return false;
  }

  logSuccess('✓ 密码修改成功');

  // 步骤 2: 用新密码登录
  logInfo('\n步骤 2: 用新密码登录');
  const loginResult = await request('POST', '/auth/login/email', {
    email: testData.email,
    password: testData.newPassword
  });

  if (!loginResult.success) {
    logError('新密码登录失败');
    return false;
  }

  logSuccess('✓ 新密码可以登录');

  // 更新 Token
  testData.accessToken = loginResult.data.data.tokens.accessToken;
  testData.refreshToken = loginResult.data.data.tokens.refreshToken;

  // 步骤 3: 验证旧密码不能登录
  logInfo('\n步骤 3: 验证旧密码不能登录');
  const oldPasswordResult = await request('POST', '/auth/login/email', {
    email: testData.email,
    password: testData.password
  });

  if (oldPasswordResult.success) {
    logError('旧密码仍然可以登录，密码哈希可能有问题');
    return false;
  }

  logSuccess('✓ 旧密码不能登录');

  // 更新当前密码
  testData.password = testData.newPassword;

  return true;
}

// 测试场景 4: 重置密码
async function testResetPassword() {
  logSection('测试场景 4: 使用恢复密钥重置密码');
  
  // 步骤 1: 使用恢复密钥重置密码
  logInfo('步骤 1: 使用恢复密钥重置密码');
  const result = await request('POST', '/auth/reset-password', {
    email: testData.email,
    recoveryKey: testData.recoveryKey,
    newPassword: testData.resetPassword
  });

  if (!result.success) {
    logError('重置密码失败');
    console.log(JSON.stringify(result.data, null, 2));
    return false;
  }

  logSuccess('✓ 密码重置成功');

  // 步骤 2: 用新密码登录
  logInfo('\n步骤 2: 用新密码登录');
  const loginResult = await request('POST', '/auth/login/email', {
    email: testData.email,
    password: testData.resetPassword
  });

  if (!loginResult.success) {
    logError('新密码登录失败');
    return false;
  }

  logSuccess('✓ 新密码可以登录');

  // 更新数据
  testData.password = testData.resetPassword;
  testData.accessToken = loginResult.data.data.tokens.accessToken;
  testData.refreshToken = loginResult.data.data.tokens.refreshToken;

  return true;
}

// 测试场景 5: 刷新 Token
async function testRefreshToken() {
  logSection('测试场景 5: 刷新 Token');
  
  const oldRefreshToken = testData.refreshToken;
  
  const result = await request('POST', '/auth/refresh-token', {
    refreshToken: testData.refreshToken
  });

  if (!result.success) {
    logError('刷新 Token 失败');
    console.log(JSON.stringify(result.data, null, 2));
    return false;
  }

  const { tokens } = result.data.data;
  
  // 更新 Token
  testData.accessToken = tokens.accessToken;
  testData.refreshToken = tokens.refreshToken;

  logSuccess('✓ 返回了新的 Token');

  if (tokens.refreshToken !== oldRefreshToken) {
    logSuccess('✓ refreshToken 已更新');
  } else {
    logWarning('⚠ refreshToken 未更新（可能是设计如此）');
  }

  return true;
}

// 测试场景 6: 获取用户信息
async function testGetUserInfo() {
  logSection('测试场景 6: 获取用户信息');
  
  const result = await request('GET', '/auth/me', null, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result.success) {
    logError('获取用户信息失败');
    console.log(JSON.stringify(result.data, null, 2));
    return false;
  }

  const user = result.data.data;

  logSuccess('✓ 返回了用户信息');
  
  if (user.email === testData.email) {
    logSuccess('✓ 邮箱匹配');
  } else {
    logError('✗ 邮箱不匹配');
    return false;
  }

  if (user.membership) {
    logSuccess('✓ 包含会员状态');
    log(`   会员等级: ${user.membership.tier}`, 'cyan');
    log(`   会员状态: ${user.membership.status}`, 'cyan');
  }

  return true;
}

// 测试场景 7: 登出
async function testLogout() {
  logSection('测试场景 7: 登出');
  
  const result = await request('POST', '/auth/logout', null, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (!result.success) {
    logError('登出失败');
    console.log(JSON.stringify(result.data, null, 2));
    return false;
  }

  logSuccess('✓ 登出成功');

  // 验证 Token 是否失效
  logInfo('\n验证 Token 是否失效');
  const verifyResult = await request('GET', '/auth/me', null, {
    'Authorization': `Bearer ${testData.accessToken}`
  });

  if (verifyResult.success) {
    logWarning('⚠ Token 仍然有效（可能是设计如此）');
  } else {
    logSuccess('✓ Token 已失效');
  }

  return true;
}

// 主测试流程
async function runAllTests() {
  log('\n🚀 开始测试 Phase 1.4 认证 API', 'blue');
  log(`📍 服务器地址: ${BASE_URL}\n`, 'cyan');

  const tests = [
    { name: '场景 1: 用户注册', fn: testRegister },
    { name: '场景 2.1: 正确登录', fn: testLoginSuccess },
    { name: '场景 2.2: 错误密码', fn: testLoginWrongPassword },
    { name: '场景 2.3: 空密码', fn: testLoginEmptyPassword },
    { name: '场景 3: 修改密码', fn: testChangePassword },
    { name: '场景 4: 重置密码', fn: testResetPassword },
    { name: '场景 5: 刷新 Token', fn: testRefreshToken },
    { name: '场景 6: 获取用户信息', fn: testGetUserInfo },
    { name: '场景 7: 登出', fn: testLogout }
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
    log('\n🎉 所有测试通过！代码质量修复验证成功！\n', 'green');
  } else {
    log('\n⚠️  部分测试失败，请检查服务器日志\n', 'yellow');
  }
}

// 检查服务器是否运行
async function checkServer() {
  logInfo('检查服务器是否运行...');
  
  try {
    // 尝试访问 health 端点
    const response = await fetch(`${BASE_URL}/health`);
    if (response.ok) {
      logSuccess('服务器正在运行');
      return true;
    }
  } catch (error) {
    // health 端点失败，尝试注册端点（只是检查连接，不实际注册）
    try {
      const testResponse = await fetch(`${BASE_URL}/auth/register/email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: '', password: '' })
      });
      // 只要能连接上就行，不管返回什么状态码
      logSuccess('服务器正在运行');
      return true;
    } catch (e) {
      logError('无法连接到服务器');
      logInfo('请确保服务器正在运行: npm run dev');
      return false;
    }
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

