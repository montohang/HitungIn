import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import 'app_button.dart';
import 'hi_icons.dart';

/// Ucapan singkat saat sesuatu selesai ("Kredivo lunas!").
Future<void> showCelebration(BuildContext context, {required String title, required String body}) => showDialog<void>(
      context: context,
      builder: (context) {
        final c = context.colors;
        final t = context.text;
        return Dialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.x24, AppSpace.x24, AppSpace.x24, AppSpace.x16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: c.goodSoft, shape: BoxShape.circle),
                  child: Icon(HiIcons.check, size: 40, color: c.good),
                ),
                const SizedBox(height: AppSpace.x16),
                Text(title, textAlign: TextAlign.center, style: t.screenTitle.copyWith(fontSize: 24)),
                const SizedBox(height: AppSpace.x8),
                Text(body, textAlign: TextAlign.center, style: t.body.copyWith(color: c.sub, height: 1.5)),
                const SizedBox(height: AppSpace.x16),
                AppButton(label: 'Mantap!', large: true, onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        );
      },
    );
