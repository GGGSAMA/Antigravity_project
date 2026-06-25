# 00099tests: 自动化测试套件 (Test Suite)

## 设计愿景
TDD (测试驱动开发) 的核心保障区。存放用于验证底层系统逻辑的测试脚本。

## 核心组件
- `simple_test_runner.gd`: 轻量级单元测试器。
- `test_cultivation.gd`, `test_social.gd`: 具体的模拟脱机测试文件。

## 架构规约
在对 `0000core` 核心层代码进行手术之前，优先在这里编写或运行测试，确保改动不会引发蝴蝶效应。
