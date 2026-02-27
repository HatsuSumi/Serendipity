import { ParsedQs } from 'qs';

/**
 * 从 Express 请求参数中获取字符串值
 * 处理参数可能是 string 或 string[] 的情况
 */
export function getParamAsString(param: string | string[]): string {
  return typeof param === 'string' ? param : param[0];
}

/**
 * 从 Express 查询参数中获取字符串值（可选）
 * 处理 Express req.query 的所有可能类型
 */
export function getQueryAsString(
  query: string | ParsedQs | (string | ParsedQs)[] | undefined
): string | undefined {
  if (!query) return undefined;
  if (typeof query === 'string') return query;
  if (Array.isArray(query)) {
    const first = query[0];
    return typeof first === 'string' ? first : undefined;
  }
  return undefined;
}

/**
 * 从 Express 查询参数中获取整数值（可选）
 */
export function getQueryAsInt(
  query: string | ParsedQs | (string | ParsedQs)[] | undefined
): number | undefined {
  const value = getQueryAsString(query);
  if (!value) return undefined;
  const parsed = parseInt(value, 10);
  return isNaN(parsed) ? undefined : parsed;
}

/**
 * 从 Express 查询参数中获取布尔值（可选）
 */
export function getQueryAsBoolean(
  query: string | ParsedQs | (string | ParsedQs)[] | undefined
): boolean | undefined {
  const value = getQueryAsString(query);
  if (!value) return undefined;
  return value === 'true' || value === '1';
}

