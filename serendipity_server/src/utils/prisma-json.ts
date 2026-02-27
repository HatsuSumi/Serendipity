import { Prisma } from '@prisma/client';

/**
 * 将值转换为 Prisma JsonValue 类型
 * 用于写入 JSONB 字段
 */
export function toJsonValue<T>(value: T): Prisma.InputJsonValue {
  return value as unknown as Prisma.InputJsonValue;
}

/**
 * 从 Prisma JsonValue 转换为指定类型
 * 用于读取 JSONB 字段
 */
export function fromJsonValue<T>(value: Prisma.JsonValue | null): T {
  if (value === null) {
    throw new Error('Cannot convert null to type');
  }
  return value as unknown as T;
}

/**
 * 从 Prisma JsonValue 转换为指定类型（可选）
 * 用于读取可选的 JSONB 字段
 */
export function fromJsonValueOptional<T>(
  value: Prisma.JsonValue | null
): T | undefined {
  if (value === null) {
    return undefined;
  }
  return value as unknown as T;
}

