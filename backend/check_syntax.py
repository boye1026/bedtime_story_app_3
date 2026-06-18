import ast
import os
import sys

errors = []
for root, dirs, files in os.walk('.'):
    if '__pycache__' in dirs:
        dirs.remove('__pycache__')
    for f in files:
        if f.endswith('.py'):
            path = os.path.join(root, f)
            try:
                with open(path, encoding='utf-8') as fp:
                    ast.parse(fp.read())
            except SyntaxError as e:
                errors.append(f'{path}: {e}')

if errors:
    for e in errors:
        print(f'FAIL: {e}')
    sys.exit(1)
else:
    print('All Python files are syntactically correct')
