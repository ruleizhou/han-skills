#!/usr/bin/env python3
"""扫描 han-util-tools references/ 目录结构，供场景路由使用。

目录结构：references/<scenario>/<platform>/<module>/<type>/

用法:
  python3 scripts/scan_routes.py                          → stdout 输出紧凑 JSON
  python3 scripts/scan_routes.py --scenario debug         → 仅输出指定场景的 JSON
  python3 scripts/scan_routes.py --catalog                → 同时生成 references/subskill-catalog.md
"""

import os
import sys
import json
import time

SCENARIOS = ("debug", "bringup", "featdev")


def skill_root():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _scan_three_level(dir_path):
    """扫描三级目录（platform → module → type），返回层级字典。"""
    result = {}
    if not os.path.isdir(dir_path):
        return result

    for platform in sorted(os.listdir(dir_path)):
        if platform.startswith(".") or platform.startswith("_"):
            continue
        p_dir = os.path.join(dir_path, platform)
        if not os.path.isdir(p_dir):
            continue
        result[platform] = {}
        for module in sorted(os.listdir(p_dir)):
            if module.startswith(".") or module.startswith("_"):
                continue
            m_dir = os.path.join(p_dir, module)
            if not os.path.isdir(m_dir):
                continue
            types = []
            for t_entry in sorted(os.listdir(m_dir)):
                if t_entry.startswith(".") or t_entry.startswith("_"):
                    continue
                if os.path.isdir(os.path.join(m_dir, t_entry)):
                    types.append(t_entry)
            result[platform][module] = types
    return result


def scan_all_scenarios(root):
    """扫描所有场景，返回 {scenario: {platform: {module: [types]}}}。"""
    ref_dir = os.path.join(root, "references")
    by_scenario = {}
    for scenario in SCENARIOS:
        s_dir = os.path.join(ref_dir, scenario)
        by_scenario[scenario] = _scan_three_level(s_dir)
    return by_scenario


def scan_skills(root):
    """扫描所有场景下的 SKILL.md，提取 name 和 description。"""
    ref_dir = os.path.join(root, "references")
    skills = []

    if not os.path.isdir(ref_dir):
        return skills

    for scenario in SCENARIOS:
        s_dir = os.path.join(ref_dir, scenario)
        if not os.path.isdir(s_dir):
            continue
        for platform in sorted(os.listdir(s_dir)):
            if platform.startswith(".") or platform.startswith("_"):
                continue
            p_dir = os.path.join(s_dir, platform)
            if not os.path.isdir(p_dir):
                continue
            for module in sorted(os.listdir(p_dir)):
                if module.startswith(".") or module.startswith("_"):
                    continue
                m_dir = os.path.join(p_dir, module)
                if not os.path.isdir(m_dir):
                    continue
                for ptype in sorted(os.listdir(m_dir)):
                    if ptype.startswith(".") or ptype.startswith("_"):
                        continue
                    t_dir = os.path.join(m_dir, ptype)
                    if not os.path.isdir(t_dir):
                        continue
                    skill_md = os.path.join(t_dir, "SKILL.md")
                    if os.path.isfile(skill_md):
                        name, desc = parse_skill_md(skill_md)
                        skills.append({
                            "scenario": scenario,
                            "platform": platform,
                            "module": module,
                            "type": ptype,
                            "name": name,
                            "description": desc,
                        })
    return skills


def parse_skill_md(path):
    """从 SKILL.md 的 YAML frontmatter 中提取 name 和 description。"""
    name = ""
    desc = ""
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        in_frontmatter = False
        for line in content.split("\n"):
            stripped = line.strip()
            if stripped == "---":
                if not in_frontmatter:
                    in_frontmatter = True
                    continue
                else:
                    break
            if in_frontmatter:
                if stripped.startswith("name:"):
                    name = stripped.split(":", 1)[1].strip()
                elif stripped.startswith("description:"):
                    desc = stripped.split(":", 1)[1].strip()
                    if desc.startswith(">"):
                        desc = desc[1:].strip()
    except (IOError, UnicodeDecodeError):
        pass
    return name, desc


def generate_catalog(root, skills):
    """生成 references/subskill-catalog.md。"""
    catalog_path = os.path.join(root, "references", "subskill-catalog.md")
    active_count = len(skills)

    lines = [
        "# 子 skill 目录索引",
        "",
        "由 `scripts/scan_routes.py --catalog` 自动生成，请勿手动编辑。",
        "",
        "---",
        "",
        "## 索引",
        "",
        "| 场景 | 平台 | 模块 | 问题类型 | 子 skill 名 | 添加日期 |",
        "|------|------|------|----------|------------|----------|",
    ]

    if skills:
        for s in skills:
            date_str = time.strftime("%Y-%m-%d")
            lines.append(
                f"| {s['scenario']} | {s['platform']} | {s['module']} | {s['type']} "
                f"| {s['name']} | {date_str} |"
            )
    else:
        lines.append("| - | - | - | - | - | - |")

    lines.extend([
        "",
        "---",
        "",
        "## 统计",
        "",
        f"- 总子 skill 数：{active_count}",
    ])

    with open(catalog_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def main():
    do_catalog = "--catalog" in sys.argv

    # 解析 --scenario 参数
    scenario_filter = None
    for i, arg in enumerate(sys.argv):
        if arg == "--scenario" and i + 1 < len(sys.argv):
            scenario_filter = sys.argv[i + 1]

    root = skill_root()
    by_scenario = scan_all_scenarios(root)

    # 确定有内容的场景列表
    scenarios_list = [s for s in SCENARIOS if any(by_scenario.get(s, {}).values())]

    data = {
        "scenarios": scenarios_list,
        "by_scenario": by_scenario,
        "ts": int(time.time()),
    }

    if scenario_filter:
        data["by_scenario"] = {scenario_filter: by_scenario.get(scenario_filter, {})}

    print(json.dumps(data, separators=(",", ":"), ensure_ascii=False))

    if do_catalog:
        skills = scan_skills(root)
        generate_catalog(root, skills)
        print(f"\n[scan_routes] catalog 已生成，共 {len(skills)} 个子 skill", file=sys.stderr)


if __name__ == "__main__":
    main()
