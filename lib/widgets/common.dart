// Komponen UI kecil yang dipakai berulang di banyak layar.

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

RoundedRectangleBorder _r(double radius) =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

/// Tombol utama merah selebar layar.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surface,
          disabledForegroundColor: AppColors.textFaint,
          shape: _r(12),
          padding: EdgeInsets.zero,
          textStyle: hapText(fontSize, weight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Tombol dengan garis tepi (aksi sekunder).
class OutlineAction extends StatelessWidget {
  const OutlineAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.borderColor,
    this.height = 52,
    this.fontSize = 15,
    this.fullWidth = true,
    this.horizontalPadding = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? borderColor;
  final double height;
  final double fontSize;
  final bool fullWidth;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: borderColor ?? color),
        shape: _r(12),
        minimumSize: Size(0, height),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        textStyle: hapText(fontSize, weight: FontWeight.w700),
      ),
      child: Text(label),
    );
    return fullWidth
        ? SizedBox(width: double.infinity, height: height, child: button)
        : SizedBox(height: height, child: button);
  }
}

/// Tombol teks tanpa latar (mis. "Tolak", "Batalkan pesanan").
class TextAction extends StatelessWidget {
  const TextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.height = 44,
    this.fontSize = 14,
    this.fullWidth = true,
    this.weight = FontWeight.w700,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double height;
  final double fontSize;
  final bool fullWidth;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        shape: _r(12),
        minimumSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: hapText(fontSize, weight: weight),
      ),
      child: Text(label),
    );
    return fullWidth
        ? SizedBox(width: double.infinity, height: height, child: button)
        : SizedBox(height: height, child: button);
  }
}

/// Chip filter berbentuk pil. Terpilih = kuning, tidak = krem.
class HapChip extends StatelessWidget {
  const HapChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.horizontal = 12,
    this.vertical = 6,
    this.fontSize = 12,
    this.tabular = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double horizontal;
  final double vertical;
  final double fontSize;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.surface,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          child: Text(
            label,
            style: hapText(fontSize, weight: FontWeight.w600, tabular: tabular),
          ),
        ),
      ),
    );
  }
}

/// Baris chip yang bisa digulir horizontal.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children, this.gap = 6});
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Kolom input krem dengan sudut membulat.
class HapField extends StatelessWidget {
  const HapField({
    super.key,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.vertical = 12,
    this.fontSize = 14,
    this.radius = 12,
    this.textAlign = TextAlign.start,
    this.suffix,
    this.prefix,
    this.tabular = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final double vertical;
  final double fontSize;
  final double radius;
  final TextAlign textAlign;
  final Widget? suffix;
  final Widget? prefix;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: keyboardType,
      minLines: maxLines,
      maxLines: maxLines,
      textAlign: textAlign,
      onChanged: onChanged,
      cursorColor: AppColors.primary,
      style: hapText(fontSize, tabular: tabular),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        hintText: hint,
        hintStyle: hapText(fontSize, color: AppColors.textMuted),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: vertical),
        prefixIcon: prefix,
        suffixIcon: suffix,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        border: border(Colors.transparent, 0),
        enabledBorder: border(Colors.transparent, 0),
        disabledBorder: border(Colors.transparent, 0),
        focusedBorder: border(AppColors.primary, 2),
      ),
    );
  }
}

/// Label kecil tebal di atas field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.size = 13});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: hapText(size, weight: FontWeight.w600)),
      );
}

/// Label + field.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
  });
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [FieldLabel(label), child],
      );
}

/// Pesan galat merah di bawah form.
class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Text(
        message,
        style: hapText(13, weight: FontWeight.w600, color: AppColors.primary),
      );
}

/// Header layar dengan tombol kembali (tinggi 56, garis bawah krem).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: EdgeInsets.only(left: showBack ? 8 : 16, right: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.surface)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Kembali',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 24),
              color: AppColors.textDark,
            ),
          if (showBack) const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hapText(18, weight: FontWeight.w700),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Judul bagian dengan keterangan kecil di kanan (mis. "3 stand").
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.trailing,
    this.muted = false,
  });

  final String title;
  final String? trailing;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: hapText(
            18,
            weight: FontWeight.w700,
            color: muted ? AppColors.textSoft : AppColors.textDark,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: hapText(12,
                weight: FontWeight.w500,
                color: AppColors.textMuted,
                tabular: true),
          ),
      ],
    );
  }
}

/// Kotak krem berisi ikon (placeholder foto).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 72,
    this.iconSize = 24,
    this.radius = 12,
    this.color = AppColors.textMuted,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.background = Colors.white,
    this.foreground = AppColors.textDark,
    this.size = 32,
    this.iconSize = 18,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final double size;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: foreground),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Pengatur jumlah: [-] 2 [+]. Tombol + nonaktif bila [onPlus] null.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
    this.padding = 4,
    this.gap = 4,
  });

  final int quantity;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final double padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleIconButton(
            icon: Icons.remove_rounded,
            onTap: onMinus,
            tooltip: 'Kurangi',
          ),
          SizedBox(width: gap),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 22),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: hapText(14, weight: FontWeight.w700, tabular: true),
            ),
          ),
          SizedBox(width: gap),
          CircleIconButton(
            icon: Icons.add_rounded,
            onTap: onPlus,
            background: AppColors.primary,
            foreground: Colors.white,
            tooltip: 'Tambah',
          ),
        ],
      ),
    );
  }
}

/// Saklar Hap! (merah/hijau saat aktif, krem saat mati).
class HapSwitch extends StatelessWidget {
  const HapSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 44,
    this.height = 24,
    this.activeColor = AppColors.primary,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: width,
          height: height,
          padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? activeColor : AppColors.surface,
            borderRadius: BorderRadius.circular(height),
            border: value ? null : Border.all(color: AppColors.outline),
          ),
          child: Container(
            width: height - 8,
            height: height - 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 2)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kotak peringatan bergaris merah (mis. stok berubah).
class WarningBox extends StatelessWidget {
  const WarningBox({super.key, required this.messages});
  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in messages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                m,
                style: hapText(13,
                    weight: FontWeight.w600,
                    color: AppColors.primary,
                    height: 1.3),
              ),
            ),
        ],
      ),
    );
  }
}

/// Garis pemisah krem antar baris daftar.
class RowDivider extends StatelessWidget {
  const RowDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.surface);
}

/// Bottom sheet bergaya Hap!: putih, sudut atas 16, latar gelap transparan.
Future<T?> showHapSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(top: false, child: builder(ctx)),
    ),
  );
}

/// Header seller/admin: "Hap! Penjual" + judul besar.
class RoleHeader extends StatelessWidget {
  const RoleHeader({
    super.key,
    required this.subtitle,
    required this.badge,
    required this.title,
    this.trailing,
  });

  final String subtitle;
  final String badge;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surface)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: hapText(12,
                            weight: FontWeight.w500,
                            color: AppColors.textMuted),
                      ),
                    ),
                    if (badge.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        badge,
                        style: hapText(12,
                            weight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(title,
                    style: hapText(24, weight: FontWeight.w800, height: 1.15)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Deretan pil sama lebar (tab Aktif/Riwayat, Baru/Diproses/Siap).
class SegmentPills extends StatelessWidget {
  const SegmentPills({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color:
                  i == selectedIndex ? AppColors.accent : AppColors.surface,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onSelect(i),
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      style: hapText(13,
                          weight: FontWeight.w600, tabular: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
