# 用户写入与同步 Data Flow

## 认证与 Profile

```text
Login/Register View → AuthViewModel → AuthRepository
→ Supabase Auth signIn/signUp
→ authStateChanges → AuthViewModel.user → AppShell 认证门控
→ ensureProfileExists → profiles（不存在时 insert）
```

## 收藏地点（local-first）

```text
MapView 保存 → LocationViewModel（立即加入内存）
→ MapRepository.addLocalSavedLocation → SQLite saved_locations(synced=0)
→ MapRepository.syncToSupabase → user_saved_regions upsert
→ 成功后 SQLite synced=1

MapView 删除 → Provider 移除 → SQLite delete
→ 若记录已同步且已登录 → user_saved_regions delete
```

注意：当前同步重点是“本地未同步项上传”，不是完整云端拉取/冲突合并。

## 众包隐患

```text
MapView 提交 → HazardViewModel 创建 temp 记录（乐观更新）
→ MapRepository.saveHazard → crowdsourced_hazards insert
├─ 失败：移除 temp 记录
└─ 成功：重新 fetchHazards，以远端记录替换临时状态

ReportedHazardsScreen 删除 → MapRepository.deleteHazard
→ crowdsourced_hazards delete → Provider 内存移除
```

隐患投票/编辑目前只改 Provider 内存，没有远端写入。

## 预算预案

```text
CostOfLivingView → BudgetViewModel
├─ 启动读取：user_budget_scenarios select（当前 user_id）
├─ 新建：insert
├─ 重命名：update（页面已接通）
├─ 金额更新：Provider 有 update 方法，但当前页面未调用
└─ 删除：delete
→ 成功后更新 Provider.scenarios/currentScenario → 页面重建
```

## 房产档案（当前仅内存）

```text
AddPropertyScreen → PropertyViewModel.add/updateInspection
→（有坐标）SecurityRiskRepository
  → match_police_district + crime_stats + crowdsourced_hazards
  → 风险字段回填 PropertyInspection
→ PropertyViewModel.inspections（内存）

删除 → inspections 移入 recycleBin
恢复 → recycleBin 移回 inspections
清空 → recycleBin.clear
```

此流没有 SQLite/Supabase 落盘；应用进程结束后用户房产、草稿和回收站变化会丢失。
