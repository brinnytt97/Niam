#!/usr/bin/env python3
"""Validate the structure of Niam's Markdown recipe collection."""

from __future__ import annotations

import re
import sys
from pathlib import Path

EXPECTED_COUNT = 151
REQUIRED_FIELDS = ("菜系", "场景", "准备时间", "烹饪时间", "每份卡路里")
INGREDIENT_GROUPS = ("主食材", "配菜", "调味料")
ALLOWED_SCENES = {"Breakfast", "Main Meal", "Dessert", "Drink", "Snack"}


def recipe_blocks(text: str) -> list[tuple[str, str]]:
    matches = list(re.finditer(r"(?m)^## (?!#)(.+?)\s*$", text))
    return [
        (match.group(1).strip().strip("="), text[match.start() : matches[index + 1].start()])
        if index + 1 < len(matches)
        else (match.group(1).strip().strip("="), text[match.start() :])
        for index, match in enumerate(matches)
    ]


def field_value(block: str, field: str) -> str | None:
    match = re.search(
        rf"(?m)^-\s+\*\*{re.escape(field)}\*\*[：:]\s*(.*?)\s*$", block
    )
    return match.group(1).strip() if match else None


def validate(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    recipes = recipe_blocks(text)
    errors: list[str] = []
    notices: list[str] = []

    if len(recipes) != EXPECTED_COUNT:
        errors.append(f"全文：菜谱数量为 {len(recipes)}，预期 {EXPECTED_COUNT}")

    seen: set[str] = set()
    for index, (title, block) in enumerate(recipes, start=1):
        recipe_id = f"R{index:03d}"
        label = f"{recipe_id} {title}"

        if title in seen:
            errors.append(f"{label}：菜名重复")
        seen.add(title)

        for field in REQUIRED_FIELDS:
            value = field_value(block, field)
            if not value:
                errors.append(f"{label}：缺少字段「{field}」")

        scene = field_value(block, "场景")
        if scene:
            values = {item.strip() for item in scene.split("/") if item.strip()}
            invalid = sorted(values - ALLOWED_SCENES)
            if not values or invalid:
                errors.append(
                    f"{label}：场景值不合法"
                    + (f"（{', '.join(invalid)}）" if invalid else "")
                )

        if len(re.findall(r"(?m)^### 食材\s*$", block)) != 1:
            errors.append(f"{label}：需要且只能有一个「### 食材」章节")
        if len(re.findall(r"(?m)^### 步骤\s*$", block)) != 1:
            errors.append(f"{label}：需要且只能有一个「### 步骤」章节")

        for group in INGREDIENT_GROUPS:
            count = len(
                re.findall(rf"(?m)^\*\*{re.escape(group)}[：:]\*\*\s*$", block)
            )
            if count != 1:
                errors.append(f"{label}：食材分组「{group}」出现 {count} 次")

        step_section = re.search(
            r"(?ms)^### 步骤\s*$\n(.*?)(?=^### |\Z)", block
        )
        if step_section:
            numbers = [
                int(number)
                for number in re.findall(
                    r"(?m)^\s*(\d+)[.)、]\s+", step_section.group(1)
                )
            ]
            if not numbers:
                errors.append(f"{label}：步骤不是有序列表")
            elif numbers != list(range(1, len(numbers) + 1)):
                errors.append(f"{label}：步骤编号不连续或未从 1 开始")

        markers = sorted(set(re.findall(r"待确认|待计算", block)))
        if markers:
            notices.append(f"{label}：包含 {'、'.join(markers)}")

    print(f"文件：{path}")
    print(f"菜谱数：{len(recipes)}")
    print(f"结构错误：{len(errors)}")
    for error in errors:
        print(f"ERROR {error}")
    print(f"待处理标记：{len(notices)}")
    for notice in notices:
        print(f"NOTICE {notice}")

    return 1 if errors else 0


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("docs/菜谱.working.md")
    if not path.is_file():
        print(f"ERROR 文件不存在：{path}", file=sys.stderr)
        return 2
    return validate(path)


if __name__ == "__main__":
    raise SystemExit(main())
