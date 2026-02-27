"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.prismaMock = void 0;
const jest_mock_extended_1 = require("jest-mock-extended");
// Mock Prisma Client
exports.prismaMock = (0, jest_mock_extended_1.mockDeep)();
// Reset mock before each test
beforeEach(() => {
    (0, jest_mock_extended_1.mockReset)(exports.prismaMock);
});
exports.default = exports.prismaMock;
//# sourceMappingURL=prisma.mock.js.map