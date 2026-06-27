import os
import re
import json
from pathlib import Path

def sum_vec(v1_str, v2_str):
    """
    Складывает векторы трансформаций. 
    Например: "0, 11.25, 0" + "0, 90, 0" -> "0, 101.25, 0".
    Идеально работает для одноосевых вращений (шестерёнки, валы).
    """
    def parse_vec(s):
        try: return [float(x.strip()) for x in s.split(',')]
        except: return [0.0, 0.0, 0.0]
    
    v1 = parse_vec(v1_str)
    v2 = parse_vec(v2_str)
    
    # Заглушка для кватернионов (x,y,z,w) - просто берём родительский поворот,
    # так как прямое сложение 4-компонентных векторов математически некорректно.
    if len(v1) == 4 or len(v2) == 4:
        return v2_str
        
    res = []
    for i in range(max(len(v1), len(v2))):
        a = v1[i] if i < len(v1) else 0.0
        b = v2[i] if i < len(v2) else 0.0
        res.append(a + b)
        
    # Форматируем красиво: убираем .0 у целых чисел
    def fmt(val):
        return f"{int(val)}" if val.is_integer() else f"{val:g}"
        
    return ", ".join(fmt(x) for x in res)

def inject_attrs(prim_str, bone_str):
    """Переносит rotate и move из строки кости в строку примитива."""
    bone_rot = re.search(r'rotate\s*\(([^)]+)\)', bone_str)
    bone_move = re.search(r'move\s*\(([^)]+)\)', bone_str)
    
    res_str = prim_str
    
    if bone_rot:
        b_val = bone_rot.group(1)
        p_rot = re.search(r'rotate\s*\(([^)]+)\)', res_str)
        if p_rot:
            p_val = p_rot.group(1)
            new_val = sum_vec(p_val, b_val)
            res_str = res_str[:p_rot.start()] + f"rotate ({new_val})" + res_str[p_rot.end():]
        else:
            res_str += f" rotate ({b_val})"
            
        # Кости крутят детей вокруг нуля. Если у примитива нет своего origin, ставим (0,0,0)
        if 'origin' not in res_str:
            res_str += " origin (0, 0, 0)"
            
    if bone_move:
        b_val = bone_move.group(1)
        p_move = re.search(r'move\s*\(([^)]+)\)', res_str)
        if p_move:
            p_val = p_move.group(1)
            new_val = sum_vec(p_val, b_val)
            res_str = res_str[:p_move.start()] + f"move ({new_val})" + res_str[p_move.end():]
        else:
            res_str += f" move ({b_val})"
            
    return res_str

def process_inner_content(inner_content, bone_attrs):
    """Находит все @box, @rect, @tri внутри блока и дописывает им трансформации."""
    def replacer(match):
        original = match.group(0)
        stripped = original.rstrip()
        trailing = original[len(stripped):] # сохраняем пробелы перед скобкой {
        
        res = inject_attrs(stripped, bone_attrs)
        return res + trailing
        
    # Ищем начало примитива до первой { или перевода строки
    return re.sub(r'(@box|@rect|@tri)[^{@\n\r]+', replacer, inner_content)

def flatten_all_bones(content: str) -> str:
    """Полностью удаляет все кости, перенося (запекая) их повороты на вложенные примитивы."""
    while True:
        # rfind ищет самую ПОСЛЕДНЮЮ кость (самую глубокую). Это гарантирует, 
        # что мы обрабатываем дерево снизу вверх.
        start_idx = content.rfind('@bone')
        if start_idx == -1:
            break
            
        bracket_start = content.find('{', start_idx)
        if bracket_start == -1:
            print("Предупреждение: Найдена кость @bone без скобки {")
            break
            
        depth = 0
        end_idx = -1
        for i in range(bracket_start, len(content)):
            if content[i] == '{': depth += 1
            elif content[i] == '}':
                depth -= 1
                if depth == 0:
                    end_idx = i
                    break
                    
        if end_idx == -1:
            print("Предупреждение: Несовпадение фигурных скобок")
            break
            
        bone_decl = content[start_idx:bracket_start]
        inner_content = content[bracket_start+1:end_idx]
        
        # Удаляем отступы перед @bone
        line_start = start_idx
        while line_start > 0 and content[line_start-1] in (' ', '\t'):
            line_start -= 1
            
        # Запекаем трансформации
        new_inner = process_inner_content(inner_content, bone_decl)
        
        # Склеиваем файл обратно (уже без этой кости)
        prefix = content[:line_start]
        suffix_start = end_idx + 1
        if suffix_start < len(content) and content[suffix_start] == '\n':
            suffix_start += 1
        suffix = content[suffix_start:]
        
        content = prefix + new_inner + suffix

    # Финальная чистка лишних пустых строк
    content = re.sub(r'\n{3,}', '\n\n', content)
    return content.strip() + '\n'

def process_models(models_dir: Path, squash_dir: Path):
    if not models_dir.exists() or not models_dir.is_dir():
        print(f"Пропуск: Папка '{models_dir}' не найдена.")
        return

    squash_dir.mkdir(parents=True, exist_ok=True)
    vcm_files = [f for f in models_dir.glob("*.vcm")]
    
    processed_count = 0
    for file_path in vcm_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()

            new_content = flatten_all_bones(content)
            output_path = squash_dir / file_path.name
            
            with open(output_path, 'w', encoding='utf-8') as file:
                file.write(new_content)

            processed_count += 1
        except Exception as e:
            print(f"Ошибка при обработке {file_path.name}: {e}")

    print(f"Модели: запечено и обработано файлов .vcm -> {processed_count}")

def process_blocks_and_items(blocks_dir: Path, items_dir: Path):
    if not blocks_dir.exists() or not blocks_dir.is_dir():
        print(f"Пропуск: Папка '{blocks_dir}' не найдена.")
        return

    items_dir.mkdir(parents=True, exist_ok=True)
    block_files = [f for f in blocks_dir.glob("*.json") if not f.name.startswith("itemm_")]
    
    processed_count = 0
    for file_path in block_files:
        try:
            block_name = file_path.stem

            itemm_data = {
                "model": "custom",
                "model-name": f"squash/{block_name}",
                "hidden": True
            }
            itemm_path = blocks_dir / f"itemm_{block_name}.json"
            with open(itemm_path, 'w', encoding='utf-8') as f:
                json.dump(itemm_data, f, indent=4, ensure_ascii=False)

            item_data = {
                "icon-type": "block",
                "icon": f"voxel_kinetics:itemm_{block_name}",
                "caption": block_name.replace("_", " ").title(),
                "placing-block": f"voxel_kinetics:{block_name}"
            }
            item_path = items_dir / f"{block_name}.item.json"
            with open(item_path, 'w', encoding='utf-8') as f:
                json.dump(item_data, f, indent=4, ensure_ascii=False)

            processed_count += 1
        except Exception as e:
            print(f"Ошибка при генерации блоков/предметов для {file_path.name}: {e}")

    print(f"Блоки/Предметы: сгенерировано пар файлов -> {processed_count}")

def main():
    base_dir = Path.cwd()
    models_dir = base_dir / "models"
    squash_dir = models_dir / "squash"
    blocks_dir = base_dir / "blocks"
    items_dir = base_dir / "items"

    print("--- Начало обработки ---")
    process_models(models_dir, squash_dir)
    process_blocks_and_items(blocks_dir, items_dir)
    print("--- Готово! ---")

if __name__ == "__main__":
    main()