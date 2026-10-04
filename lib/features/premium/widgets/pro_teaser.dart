import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../security/app_gate.dart';
import '../data/pro_limits.dart';

void openPremium(BuildContext context, ProReason reason) =>
    context.push(Uri(path: Routes.premium, queryParameters: {'from': reason.name}).toString());

/// Kartu ajakan Pro di tempat fitur yang terkunci.
class ProTeaser extends StatelessWidget {
  const ProTeaser({super.key, required this.reason, required this.body});

  final ProReason reason;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(reason.headline, style: t.title)),
              const AppBadge.pro(),
            ],
          ),
          const SizedBox(height: AppSpace.x8),
          Text(body, style: t.body.copyWith(color: context.colors.sub)),
          const SizedBox(height: AppSpace.x16),
          AppButton(label: 'Lihat HitungIn Pro', variant: AppButtonVariant.soft, onPressed: () => openPremium(context, reason)),
        ],
      ),
    );
  }
}
