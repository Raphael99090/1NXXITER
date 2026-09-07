#!/usr/bin/env python3
"""
1NXITER — Mini-ofuscador / Minificador de Lua
Roda no Termux sem dependências externas.

Uso:
    python3 minify.py <arquivo.lua>                   → imprime no terminal
    python3 minify.py <arquivo.lua> -o <saida.lua>    → salva em arquivo
    python3 minify.py src/ -o dist/release.lua --bundle  → junta tudo num arquivo só

O que faz:
    - Remove comentários (-- e --[[ ]])
    - Remove linhas em branco
    - Remove espaços desnecessários
    - Encurta nomes de variáveis locais (a, b, c...)
    - Preserva strings intactas (aspas simples, duplas e [[ ]])
"""

import sys
import os
import re
import string

# ─── Tokenizer simplificado ─────────────────────────────────────────

def tokenize(code):
    """
    Quebra o código Lua em tokens preservando strings e identificando
    comentários, espaços e identificadores.
    """
    tokens = []
    i = 0
    n = len(code)

    while i < n:
        # String longa [[ ]] ou [=[ ]=]
        if code[i] == '[' and i + 1 < n and code[i + 1] in '[=':
            level = 0
            j = i + 1
            while j < n and code[j] == '=':
                level += 1
                j += 1
            if j < n and code[j] == '[':
                end_pat = ']' + ('=' * level) + ']'
                end_idx = code.find(end_pat, j + 1)
                if end_idx == -1:
                    end_idx = n
                else:
                    end_idx += len(end_pat)
                tokens.append(('string', code[i:end_idx]))
                i = end_idx
                continue
            # Não era string longa, trata como operador
            tokens.append(('op', code[i]))
            i += 1
            continue

        # Comentário longo --[[ ]]
        if code[i:i+4] == '--[[' or (code[i:i+3] == '--[' and i + 3 < n and code[i+3] == '='):
            start = i + 2
            level = 0
            j = start + 1
            while j < n and code[j] == '=':
                level += 1
                j += 1
            if j < n and code[j] == '[':
                end_pat = ']' + ('=' * level) + ']'
                end_idx = code.find(end_pat, j + 1)
                if end_idx == -1:
                    end_idx = n
                else:
                    end_idx += len(end_pat)
                tokens.append(('comment', code[i:end_idx]))
                i = end_idx
                continue

        # Comentário de linha --
        if code[i:i+2] == '--':
            end_idx = code.find('\n', i)
            if end_idx == -1:
                end_idx = n
            tokens.append(('comment', code[i:end_idx]))
            i = end_idx
            continue

        # String com aspas
        if code[i] in '"\'':
            quote = code[i]
            j = i + 1
            while j < n:
                if code[j] == '\\':
                    j += 2
                    continue
                if code[j] == quote:
                    j += 1
                    break
                j += 1
            tokens.append(('string', code[i:j]))
            i = j
            continue

        # Espaço/nova linha
        if code[i] in ' \t':
            j = i
            while j < n and code[j] in ' \t':
                j += 1
            tokens.append(('space', code[i:j]))
            i = j
            continue

        if code[i] == '\n':
            tokens.append(('newline', '\n'))
            i += 1
            continue

        # Identificador ou keyword
        if code[i].isalpha() or code[i] == '_':
            j = i
            while j < n and (code[j].isalnum() or code[j] == '_'):
                j += 1
            tokens.append(('ident', code[i:j]))
            i = j
            continue

        # Número
        if code[i].isdigit() or (code[i] == '.' and i + 1 < n and code[i+1].isdigit()):
            j = i
            if code[j:j+2] in ('0x', '0X'):
                j += 2
                while j < n and (code[j] in '0123456789abcdefABCDEF_'):
                    j += 1
            else:
                while j < n and (code[j].isdigit() or code[j] == '.'):
                    j += 1
                if j < n and code[j] in 'eE':
                    j += 1
                    if j < n and code[j] in '+-':
                        j += 1
                    while j < n and code[j].isdigit():
                        j += 1
            tokens.append(('number', code[i:j]))
            i = j
            continue

        # Operadores multi-char
        if code[i:i+3] in ('...', '==='):
            tokens.append(('op', code[i:i+3]))
            i += 3
            continue
        if code[i:i+2] in ('==', '~=', '>=', '<=', '..', '::', '//', '<<', '>>', '+=', '-='):
            tokens.append(('op', code[i:i+2]))
            i += 2
            continue

        # Operador/pontuação simples
        tokens.append(('op', code[i]))
        i += 1

    return tokens


# ─── Palavras reservadas do Lua/Luau ──────────────────────────────────

LUA_KEYWORDS = {
    'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
    'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
    'return', 'then', 'true', 'until', 'while', 'continue', 'type',
    'export', 'typeof',
    # Globais comuns do Roblox que não devem ser renomeadas
    'game', 'workspace', 'script', 'self', 'pcall', 'xpcall',
    'print', 'warn', 'error', 'require', 'tostring', 'tonumber',
    'type', 'typeof', 'pairs', 'ipairs', 'next', 'select',
    'table', 'string', 'math', 'os', 'task', 'coroutine', 'debug',
    'getgenv', 'getrenv', 'getfenv', 'setfenv', 'loadstring',
    'Instance', 'Vector2', 'Vector3', 'CFrame', 'Color3', 'UDim', 'UDim2',
    'Enum', 'Ray', 'RaycastParams', 'TweenInfo', 'NumberRange',
    'ColorSequence', 'NumberSequence', 'BrickColor',
    'tick', 'time', 'wait', 'spawn', 'delay',
}


# ─── Gerador de nomes curtos ──────────────────────────────────────────

def name_generator():
    """Gera nomes curtos: a, b, ..., z, aa, ab, ..., zz, aaa, ..."""
    chars = string.ascii_lowercase
    length = 1
    while True:
        if length == 1:
            for c in chars:
                if c not in LUA_KEYWORDS:
                    yield c
        else:
            # Gera combinações
            def combos(prefix, remaining):
                if remaining == 0:
                    yield prefix
                    return
                for c in chars:
                    yield from combos(prefix + c, remaining - 1)
            for name in combos('', length):
                if name not in LUA_KEYWORDS:
                    yield name
        length += 1


# ─── Minificador ──────────────────────────────────────────────────────

def minify(code, rename_locals=True):
    tokens = tokenize(code)

    # 1. Remove comentários
    tokens = [t for t in tokens if t[0] != 'comment']

    # 2. Encontra variáveis locais e renomeia
    if rename_locals:
        # Busca declarações "local X" e "local function X"
        local_vars = set()
        i = 0
        while i < len(tokens):
            if tokens[i] == ('ident', 'local'):
                j = i + 1
                while j < len(tokens) and tokens[j][0] in ('space', 'newline'):
                    j += 1
                if j < len(tokens) and tokens[j] == ('ident', 'function'):
                    # local function NAME
                    k = j + 1
                    while k < len(tokens) and tokens[k][0] in ('space', 'newline'):
                        k += 1
                    if k < len(tokens) and tokens[k][0] == 'ident':
                        name = tokens[k][1]
                        if name not in LUA_KEYWORDS:
                            local_vars.add(name)
                elif j < len(tokens) and tokens[j][0] == 'ident':
                    # local NAME, NAME2, NAME3
                    name = tokens[j][1]
                    if name not in LUA_KEYWORDS:
                        local_vars.add(name)
                    # Check for comma-separated names
                    k = j + 1
                    while k < len(tokens):
                        while k < len(tokens) and tokens[k][0] in ('space', 'newline'):
                            k += 1
                        if k < len(tokens) and tokens[k] == ('op', ','):
                            k += 1
                            while k < len(tokens) and tokens[k][0] in ('space', 'newline'):
                                k += 1
                            if k < len(tokens) and tokens[k][0] == 'ident':
                                n2 = tokens[k][1]
                                if n2 not in LUA_KEYWORDS:
                                    local_vars.add(n2)
                                k += 1
                            else:
                                break
                        else:
                            break
            i += 1

        # Cria mapeamento de nomes curtos
        gen = name_generator()
        rename_map = {}
        for var in sorted(local_vars):
            short = next(gen)
            # Garante que o nome curto não colide com nenhum identificador existente
            while short in LUA_KEYWORDS or (short in local_vars and short != var):
                short = next(gen)
            rename_map[var] = short

        # Aplica renomeação com regras para propriedades
        new_tokens = []
        brace_depth = 0
        for idx, t in enumerate(tokens):
            if t[0] == 'op' and t[1] == '{':
                brace_depth += 1
            elif t[0] == 'op' and t[1] == '}':
                brace_depth -= 1

            if t[0] == 'ident' and t[1] in rename_map:
                is_prop = False
                # Checa se o token anterior é '.' ou ':'
                prev_idx = idx - 1
                while prev_idx >= 0 and tokens[prev_idx][0] in ('space', 'newline'):
                    prev_idx -= 1
                if prev_idx >= 0 and tokens[prev_idx][0] == 'op' and tokens[prev_idx][1] in ('.', ':'):
                    is_prop = True
                
                # Checa se é chave de dicionário: anterior é '{', ',', ou ';' e próximo é '='
                if not is_prop and brace_depth > 0:
                    next_idx = idx + 1
                    while next_idx < len(tokens) and tokens[next_idx][0] in ('space', 'newline'):
                        next_idx += 1
                    if next_idx < len(tokens) and tokens[next_idx][0] == 'op' and tokens[next_idx][1] == '=':
                        if prev_idx >= 0 and tokens[prev_idx][0] == 'op' and tokens[prev_idx][1] in ('{', ',', ';'):
                            is_prop = True

                if not is_prop:
                    new_tokens.append(('ident', rename_map[t[1]]))
                else:
                    new_tokens.append(t)
            else:
                new_tokens.append(t)
        tokens = new_tokens

    # 3. Colapsa espaços
    result = []
    prev_type = None
    for ttype, tval in tokens:
        if ttype == 'newline':
            # Mantém uma newline (Lua precisa pra separar statements)
            if prev_type != 'newline':
                result.append('\n')
                prev_type = 'newline'
            continue

        if ttype == 'space':
            # Espaço entre dois identificadores/números/keywords é necessário
            if prev_type in ('ident', 'number') and len(result) > 0:
                result.append(' ')
                prev_type = 'space'
            continue

        # Antes de ident/number, precisa de espaço se o anterior era ident/number
        if ttype in ('ident', 'number') and prev_type in ('ident', 'number'):
            if not result or result[-1] not in (' ', '\n'):
                result.append(' ')

        result.append(tval)
        prev_type = ttype

    # 4. Remove linhas vazias extras
    output = '\n'.join(line for line in ''.join(result).split('\n') if line.strip())
    return output


# ─── Bundle (juntar vários arquivos) ──────────────────────────────────

def bundle_directory(src_dir, rename=True):
    """Lê todos os .lua de um diretório (recursivo) e concatena."""
    files = []
    for root, dirs, fnames in os.walk(src_dir):
        for fname in sorted(fnames):
            if fname.endswith('.lua'):
                files.append(os.path.join(root, fname))

    parts = []
    for filepath in files:
        rel = os.path.relpath(filepath, src_dir)
        with open(filepath, 'r', encoding='utf-8') as f:
            code = f.read()
        minified = minify(code, rename_locals=rename)
        parts.append(f'-- [{rel}]\n{minified}')

    return '\n'.join(parts)


# ─── CLI ──────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    source = sys.argv[1]
    output = None
    do_bundle = False
    no_rename = False

    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == '-o' and i + 1 < len(sys.argv):
            output = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == '--bundle':
            do_bundle = True
            i += 1
        elif sys.argv[i] == '--no-rename':
            no_rename = True
            i += 1
        else:
            i += 1

    rename = not no_rename

    if do_bundle and os.path.isdir(source):
        result = bundle_directory(source, rename=rename)
    elif os.path.isfile(source):
        with open(source, 'r', encoding='utf-8') as f:
            code = f.read()
        result = minify(code, rename_locals=rename)
    else:
        print(f"Erro: '{source}' não encontrado.")
        sys.exit(1)

    if output:
        os.makedirs(os.path.dirname(output) or '.', exist_ok=True)
        with open(output, 'w', encoding='utf-8') as f:
            f.write(result)
        original = os.path.getsize(source) if os.path.isfile(source) else sum(
            os.path.getsize(os.path.join(r, f))
            for r, _, fs in os.walk(source)
            for f in fs if f.endswith('.lua')
        )
        final = len(result.encode('utf-8'))
        ratio = (1 - final / original) * 100 if original > 0 else 0
        print(f"✅ Minificado: {output}")
        print(f"   Original: {original:,} bytes → Final: {final:,} bytes ({ratio:.1f}% menor)")
    else:
        print(result)


if __name__ == '__main__':
    main()
