import os
import re

files_to_update = {
    'lib/features/onboarding/screens/onboarding_screen.dart': [
        (r'const SizedBox\(width: 20, height: 20, child: CircularProgressIndicator\(color: Colors.white, strokeWidth: 2\)\)', r'const PremiumFlowingLoader(size: 20, color: Colors.white)'),
        (r'const SizedBox\(width: 20, height: 20, child: CircularProgressIndicator\(color: Colors.black, strokeWidth: 2\)\)', r'const PremiumFlowingLoader(size: 20, color: Colors.black)')
    ],
    'lib/features/sunnah/screens/sunnah_screen.dart': [
        (r'const Center\(child: CircularProgressIndicator\(color: Colors.white\)\)', r'const Center(child: PremiumFlowingLoader(color: Colors.white))')
    ],
    'lib/features/tasbih/screens/tasbih_screen.dart': [
        (r'Center\(child: CircularProgressIndicator\(color: AppColors.activeGlow\)\)', r'Center(child: PremiumFlowingLoader(color: AppColors.activeGlow))')
    ],
    'lib/features/home/screens/home_screen.dart': [
        (r'child: CircularProgressIndicator\(color: AppColors.activeGlow\),', r'child: PremiumFlowingLoader(color: AppColors.activeGlow),')
    ],
    'lib/features/settings/screens/settings_screen.dart': [
        (r'child: CircularProgressIndicator\(strokeWidth: 2, color: Colors.white\)', r'child: PremiumFlowingLoader(size: 20, color: Colors.white)')
    ]
}

import_statement = "import '../../../widgets/common/premium_flowing_loader.dart';\n"
settings_import = "import '../../widgets/common/premium_flowing_loader.dart';\n"

for filepath, replacements in files_to_update.items():
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content
    for old, new in replacements:
        content = re.sub(old, new, content)

    if content != original_content:
        # Add import if missing
        import_str = settings_import if 'settings_screen' in filepath else import_statement
        # for home, sunnah, tasbih, onboarding: they are in lib/features/<feature>/screens/<screen>.dart
        # wait, lib/features/home/screens/home_screen.dart -> depth is 4 (lib/features/home/screens).
        # lib/widgets/common/premium_flowing_loader.dart -> depth is 3.
        # From screens to lib: ../../../
        # So it's ../../../widgets/common/premium_flowing_loader.dart
        
        if 'premium_flowing_loader.dart' not in content:
            # find last import
            last_import_index = content.rfind("import '")
            end_of_last_import = content.find(';', last_import_index) + 1
            content = content[:end_of_last_import] + '\n' + import_str + content[end_of_last_import:]

        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")
    else:
        print(f"No changes made to {filepath}. Please check patterns.")

